// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import Foundation
import UIKit
import CoreML
import CreateML

/// Manager for on-device AI learning and improvement
class AILearningManager {
    // Singleton instance
    static let shared = AILearningManager()
    
    // Local storage for interactions
    private var storedInteractions: [AIInteraction] = []
    
    // Lock for thread-safe access
    private let interactionsLock = NSLock()
    
    // Settings keys
    private let learningEnabledKey = "AILearningEnabled"
    private let lastTrainingKey = "AILastTrainingDate"
    private let modelVersionKey = "AILocalModelVersion"
    
    // Model paths
    private let interactionsPath: URL
    private let modelsDirectory: URL
    
    // Training configuration
    private let minInteractionsForTraining = 10
    private let minDaysBetweenTraining = 1
    
    // Current model version
    private(set) var currentModelVersion: String = "1.0.0"
    
    private init() {
        // Set up storage locations
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        interactionsPath = documentsDirectory.appendingPathComponent("ai_interactions.json")
        modelsDirectory = documentsDirectory.appendingPathComponent("AIModels", isDirectory: true)
        
        // Create directories if needed
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        
        // Load stored interactions
        loadInteractions()
        
        // Get current model version
        if let savedVersion = UserDefaults.standard.string(forKey: modelVersionKey) {
            currentModelVersion = savedVersion
        }
        
        // Schedule periodic model training evaluation
        scheduleTrainingEvaluation()
    }
    
    // MARK: - Public Interface
    
    /// Check if AI learning is enabled
    var isLearningEnabled: Bool {
        return UserDefaults.standard.bool(forKey: learningEnabledKey)
    }
    
    /// Set whether AI learning is enabled
    func setLearningEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: learningEnabledKey)
        Debug.shared.log(message: "AI learning \(enabled ? "enabled" : "disabled")", type: .info)
    }
    
    /// Get the URL for the latest trained model
    func getLatestModelURL() -> URL? {
        let modelPath = modelsDirectory.appendingPathComponent("model_\(currentModelVersion).mlmodel")
        
        // Check if file exists
        if FileManager.default.fileExists(atPath: modelPath.path) {
            return modelPath
        }
        
        return nil
    }
    
    /// Record a user interaction with the AI for learning purposes
    func recordInteraction(userMessage: String, aiResponse: String, intent: String, confidence: Double) {
        // Skip if learning is disabled
        guard isLearningEnabled else {
            return
        }
        
        // Create interaction record
        let interaction = AIInteraction(
            id: UUID().uuidString,
            timestamp: Date(),
            userMessage: userMessage,
            aiResponse: aiResponse,
            detectedIntent: intent,
            confidenceScore: confidence,
            feedback: nil,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            modelVersion: currentModelVersion
        )
        
        // Add to stored interactions
        interactionsLock.lock()
        storedInteractions.append(interaction)
        interactionsLock.unlock()
        
        // Save to disk
        saveInteractions()
        
        // Check if we should train a new model
        evaluateTraining()
    }
    
    /// Add feedback to a specific interaction
    func recordFeedback(for interactionId: String, rating: Int, comment: String? = nil) {
        interactionsLock.lock()
        
        // Find the interaction
        if let index = storedInteractions.firstIndex(where: { $0.id == interactionId }) {
            // Add feedback
            storedInteractions[index].feedback = AIFeedback(rating: rating, comment: comment)
            
            // Save
            saveInteractions()
            
            // Consider training if this is highly-rated feedback
            if rating >= 4 {
                DispatchQueue.global(qos: .background).async { [weak self] in
                    self?.evaluateTraining()
                }
            }
        }
        
        interactionsLock.unlock()
    }
    
    /// Get statistics about stored interactions
    func getLearningStatistics() -> LearningStatistics {
        interactionsLock.lock()
        defer { interactionsLock.unlock() }
        
        let total = storedInteractions.count
        let withFeedback = storedInteractions.filter { $0.feedback != nil }.count
        let averageRating = calculateAverageRating()
        let lastTrainingDate = UserDefaults.standard.object(forKey: lastTrainingKey) as? Date
        
        return LearningStatistics(
            totalInteractions: total,
            interactionsWithFeedback: withFeedback,
            averageFeedbackRating: averageRating,
            modelVersion: currentModelVersion,
            lastTrainingDate: lastTrainingDate
        )
    }
    
    /// Manually trigger model training
    func trainModelNow(completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(false, "Manager deallocated")
                }
                return
            }
            
            // Check if we have enough data
            if self.storedInteractions.count < self.minInteractionsForTraining {
                DispatchQueue.main.async {
                    completion(false, "Not enough interactions for training (need at least \(self.minInteractionsForTraining))")
                }
                return
            }
            
            // Perform training
            let result = self.trainNewModel()
            
            DispatchQueue.main.async {
                if result.success {
                    completion(true, "Successfully trained model version \(result.version)")
                } else {
                    completion(false, "Training failed: \(result.errorMessage ?? "Unknown error")")
                }
            }
        }
    }
    
    /// Clear all stored interactions
    func clearAllInteractions() {
        interactionsLock.lock()
        storedInteractions.removeAll()
        interactionsLock.unlock()
        
        saveInteractions()
        
        Debug.shared.log(message: "Cleared all stored AI interactions", type: .info)
    }
    
    // MARK: - Private Methods
    
    /// Schedule periodic evaluation for training
    private func scheduleTrainingEvaluation() {
        // Check once per day if training should be performed
        let timer = Timer(timeInterval: 24 * 60 * 60, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
    }
    
    @objc private func timerFired() {
        evaluateTraining()
    }
    
    /// Evaluate if a new model should be trained
    private func evaluateTraining() {
        // Only train if learning is enabled
        guard isLearningEnabled else {
            return
        }
        
        // Check if we have enough interactions
        interactionsLock.lock()
        let interactionCount = storedInteractions.count
        interactionsLock.unlock()
        
        guard interactionCount >= minInteractionsForTraining else {
            return
        }
        
        // Check when we last trained
        let lastTraining = UserDefaults.standard.object(forKey: lastTrainingKey) as? Date ?? Date.distantPast
        let daysSinceLastTraining = Calendar.current.dateComponents([.day], from: lastTraining, to: Date()).day ?? Int.max
        
        guard daysSinceLastTraining >= minDaysBetweenTraining else {
            return
        }
        
        // We meet all criteria, start training
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.trainNewModel()
        }
    }
    
    /// Train a new model using stored interactions
    private func trainNewModel() -> (success: Bool, version: String, errorMessage: String?) {
        Debug.shared.log(message: "Starting AI model training", type: .info)
        
        do {
            // Lock and copy interactions
            interactionsLock.lock()
            let interactionsToUse = storedInteractions
            interactionsLock.unlock()
            
            // Generate new version
            let timestamp = Int(Date().timeIntervalSince1970)
            let newVersion = "1.0.\(timestamp)"
            
            // Prepare training data
            // Focus on interactions with positive feedback for better quality
            let trainingData = interactionsToUse.filter { 
                if let feedback = $0.feedback {
                    return feedback.rating >= 3  // Only use moderate to positive examples
                }
                return false
            }
            
            // Handle case where we don't have enough quality examples
            if trainingData.count < 5 {
                Debug.shared.log(message: "Not enough quality training examples", type: .warning)
                return (false, newVersion, "Not enough quality examples (with good feedback)")
            }
            
            // Create MLDataTable from interactions
            var textInput: [String] = []
            var intentOutput: [String] = []
            
            for interaction in trainingData {
                textInput.append(interaction.userMessage)
                intentOutput.append(interaction.detectedIntent)
            }
            
            // Create simple text classifier
            let modelURL = modelsDirectory.appendingPathComponent("model_\(newVersion).mlmodel")
            
            // Train model
            let sentimentClassifier = try MLTextClassifier(
                trainingData: .init(
                    textColumn: .init(textInput),
                    labelColumn: .init(intentOutput)
                )
            )
            
            // Save the model
            try sentimentClassifier.write(to: modelURL)
            
            // Update current version
            currentModelVersion = newVersion
            UserDefaults.standard.set(newVersion, forKey: modelVersionKey)
            UserDefaults.standard.set(Date(), forKey: lastTrainingKey)
            
            Debug.shared.log(message: "Successfully trained new model version: \(newVersion)", type: .info)
            
            // Notify that a new model is available
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("AIModelUpdated"), object: nil)
            }
            
            return (true, newVersion, nil)
            
        } catch {
            Debug.shared.log(message: "Failed to train model: \(error)", type: .error)
            return (false, currentModelVersion, error.localizedDescription)
        }
    }
    
    /// Calculate average rating from feedbacks
    private func calculateAverageRating() -> Double {
        let feedbacks = storedInteractions.compactMap { $0.feedback }
        
        if feedbacks.isEmpty {
            return 0.0
        }
        
        let sum = feedbacks.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(feedbacks.count)
    }
    
    /// Save interactions to disk
    private func saveInteractions() {
        interactionsLock.lock()
        defer { interactionsLock.unlock() }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(storedInteractions)
            try data.write(to: interactionsPath)
        } catch {
            Debug.shared.log(message: "Failed to save interactions: \(error)", type: .error)
        }
    }
    
    /// Load interactions from disk
    private func loadInteractions() {
        guard FileManager.default.fileExists(atPath: interactionsPath.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: interactionsPath)
            let decoder = JSONDecoder()
            let interactions = try decoder.decode([AIInteraction].self, from: data)
            
            interactionsLock.lock()
            storedInteractions = interactions
            interactionsLock.unlock()
            
            Debug.shared.log(message: "Loaded \(interactions.count) stored interactions", type: .info)
        } catch {
            Debug.shared.log(message: "Failed to load stored interactions: \(error)", type: .error)
        }
    }
}

// MARK: - Model Types

/// Represents a single user interaction with the AI
struct AIInteraction: Codable, Identifiable, Equatable {
    let id: String
    let timestamp: Date
    let userMessage: String
    let aiResponse: String
    let detectedIntent: String
    let confidenceScore: Double
    var feedback: AIFeedback?
    let appVersion: String
    let modelVersion: String
    
    static func == (lhs: AIInteraction, rhs: AIInteraction) -> Bool {
        return lhs.id == rhs.id
    }
}

/// User feedback on an AI interaction
struct AIFeedback: Codable {
    let rating: Int // 1-5 rating
    let comment: String?
}

/// Statistics about stored interactions
struct LearningStatistics {
    let totalInteractions: Int
    let interactionsWithFeedback: Int
    let averageFeedbackRating: Double
    let modelVersion: String
    let lastTrainingDate: Date?
}
