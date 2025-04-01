// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import Foundation
import CoreML

/// Client for interacting with the Backdoor AI learning server
class BackdoorAIClient {
    // Singleton instance
    static let shared = BackdoorAIClient()
    
    // Server configuration
    private let baseURL: URL
    private let apiKey: String
    
    // Server endpoints
    private let learnEndpoint = "api/ai/learn"
    private let latestModelEndpoint = "api/ai/latest-model"
    private let modelDownloadEndpoint = "api/ai/models"
    
    // User defaults keys
    private let currentModelVersionKey = "currentModelVersion"
    
    /// Initialize the client with server URL and API key
    private init() {
        // Load configuration from settings if available, otherwise use defaults
        // In a real app, the API key should be stored securely in the keychain
        let serverURL = UserDefaults.standard.string(forKey: "AIServerURL") ?? "https://ai.backdoor.app"
        self.baseURL = URL(string: serverURL)!
        self.apiKey = UserDefaults.standard.string(forKey: "AIServerAPIKey") ?? "rnd_2DfFj1QmKeAWcXF5u9Z0oV35kBiN"
        
        Debug.shared.log(message: "BackdoorAIClient initialized with server: \(serverURL)", type: .info)
    }
    
    /// Update server configuration
    func updateServerConfig(serverURL: String, apiKey: String) {
        UserDefaults.standard.set(serverURL, forKey: "AIServerURL")
        UserDefaults.standard.set(apiKey, forKey: "AIServerAPIKey")
        Debug.shared.log(message: "BackdoorAIClient configuration updated", type: .info)
    }
    
    // Common headers for all requests
    private var headers: [String: String] {
        return [
            "Content-Type": "application/json",
            "X-API-Key": apiKey,
            "User-Agent": "Backdoor-App/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
        ]
    }
    
    // MARK: - Data Upload
    
    /// Upload interaction data to the server
    func uploadInteractions(interactions: [AIInteraction], behaviors: [UserBehavior] = [], patterns: [AppUsagePattern] = []) async throws -> ModelInfo {
        let url = baseURL.appendingPathComponent(learnEndpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Convert our internal models to API models
        let apiInteractions = interactions.map { interaction -> Interaction in
            let feedback = interaction.feedback.map { 
                Feedback(rating: $0.rating, comment: $0.comment)
            }
            
            return Interaction(
                id: interaction.id,
                timestamp: ISO8601DateFormatter().string(from: interaction.timestamp),
                userMessage: interaction.userMessage,
                aiResponse: interaction.aiResponse,
                detectedIntent: interaction.detectedIntent,
                confidenceScore: interaction.confidenceScore,
                feedback: feedback
            )
        }
        
        // Convert behaviors to API models
        let apiBehaviors = behaviors.map { behavior -> AppBehavior in
            return AppBehavior(
                id: behavior.id,
                timestamp: ISO8601DateFormatter().string(from: behavior.timestamp),
                action: behavior.action,
                screen: behavior.screen,
                duration: behavior.duration,
                details: behavior.details
            )
        }
        
        // Convert patterns to API models
        let apiPatterns = patterns.map { pattern -> UsagePattern in
            return UsagePattern(
                id: pattern.id,
                timestamp: ISO8601DateFormatter().string(from: pattern.timestamp),
                feature: pattern.feature,
                timeSpent: pattern.timeSpent,
                actionSequence: pattern.actionSequence,
                completedTask: pattern.completedTask
            )
        }
        
        // Create device data package
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let deviceData = DeviceData(
            deviceId: deviceId,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            modelVersion: UserDefaults.standard.string(forKey: currentModelVersionKey) ?? "1.0.0",
            osVersion: UIDevice.current.systemVersion,
            interactions: apiInteractions,
            behaviors: apiBehaviors,
            patterns: apiPatterns
        )
        
        // Encode data
        do {
            request.httpBody = try JSONEncoder().encode(deviceData)
        } catch {
            Debug.shared.log(message: "Failed to encode device data: \(error)", type: .error)
            throw APIError.encodingFailed
        }
        
        // Make request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                Debug.shared.log(message: "Server returned error status: \((response as? HTTPURLResponse)?.statusCode ?? 0)", type: .error)
                throw APIError.invalidResponse
            }
            
            // Decode response
            do {
                let modelInfo = try JSONDecoder().decode(ModelInfo.self, from: data)
                Debug.shared.log(message: "Successfully uploaded \(interactions.count) interactions, \(behaviors.count) behaviors, and \(patterns.count) patterns", type: .info)
                return modelInfo
            } catch {
                Debug.shared.log(message: "Failed to decode model info: \(error)", type: .error)
                throw APIError.decodingFailed
            }
        } catch {
            Debug.shared.log(message: "Network error during upload: \(error)", type: .error)
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Model Management
    
    /// Get information about the latest available model
    func getLatestModelInfo() async throws -> ModelInfo {
        let url = baseURL.appendingPathComponent(latestModelEndpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Make request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                Debug.shared.log(message: "Server returned error status: \((response as? HTTPURLResponse)?.statusCode ?? 0)", type: .error)
                throw APIError.invalidResponse
            }
            
            // Decode response
            do {
                let modelInfo = try JSONDecoder().decode(ModelInfo.self, from: data)
                Debug.shared.log(message: "Latest model version: \(modelInfo.latestModelVersion)", type: .info)
                return modelInfo
            } catch {
                Debug.shared.log(message: "Failed to decode model info: \(error)", type: .error)
                throw APIError.decodingFailed
            }
        } catch {
            Debug.shared.log(message: "Network error during model info request: \(error)", type: .error)
            throw APIError.networkError(error)
        }
    }
    
    /// Download a specific model version from the server
    func downloadModel(version: String) async throws -> URL {
        let url = baseURL.appendingPathComponent("\(modelDownloadEndpoint)/\(version)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Create temporary file to store the model
        let tempDir = FileManager.default.temporaryDirectory
        let modelURL = tempDir.appendingPathComponent("model_\(version).mlmodel")
        
        // Download to file
        do {
            let (downloadLocation, response) = try await URLSession.shared.download(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                Debug.shared.log(message: "Server returned error status during download: \((response as? HTTPURLResponse)?.statusCode ?? 0)", type: .error)
                throw APIError.downloadFailed
            }
            
            // Move to our location
            if FileManager.default.fileExists(atPath: modelURL.path) {
                try FileManager.default.removeItem(at: modelURL)
            }
            
            try FileManager.default.moveItem(at: downloadLocation, to: modelURL)
            Debug.shared.log(message: "Successfully downloaded model version \(version)", type: .info)
            
            return modelURL
        } catch {
            Debug.shared.log(message: "Failed to download model: \(error)", type: .error)
            throw APIError.downloadFailed
        }
    }
    
    /// Compile and save model to the app's documents directory
    func compileAndSaveModel(at tempURL: URL) async throws -> URL {
        // Get documents directory for persistent storage
        let documentsDir = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        // Get models directory
        let modelsDir = documentsDir.appendingPathComponent("AIModels", isDirectory: true)
        if !FileManager.default.fileExists(atPath: modelsDir.path) {
            try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Define destination
        let modelFileName = tempURL.lastPathComponent
        let compiledModelName = modelFileName.replacingOccurrences(of: ".mlmodel", with: ".mlmodelc")
        let compiledModelURL = modelsDir.appendingPathComponent(compiledModelName)
        
        // Check if model already exists
        if FileManager.default.fileExists(atPath: compiledModelURL.path) {
            Debug.shared.log(message: "Model already compiled at \(compiledModelURL.path)", type: .info)
            return compiledModelURL
        }
        
        // Compile model (this is CPU intensive - do on background thread)
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    Debug.shared.log(message: "Compiling model at \(tempURL.path)", type: .info)
                    let compiledURL = try MLModel.compileModel(at: tempURL)
                    
                    // Save to documents directory
                    if FileManager.default.fileExists(atPath: compiledModelURL.path) {
                        try FileManager.default.removeItem(at: compiledModelURL)
                    }
                    try FileManager.default.copyItem(at: compiledURL, to: compiledModelURL)
                    
                    Debug.shared.log(message: "Model successfully compiled and saved to \(compiledModelURL.path)", type: .info)
                    continuation.resume(returning: compiledModelURL)
                } catch {
                    Debug.shared.log(message: "Failed to compile model: \(error)", type: .error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Check for model updates, download and update if needed
    func checkAndUpdateModel() async -> Bool {
        do {
            let modelInfo = try await getLatestModelInfo()
            let currentVersion = UserDefaults.standard.string(forKey: currentModelVersionKey) ?? "1.0.0"
            
            // If we have a newer version available
            if modelInfo.latestModelVersion != currentVersion {
                Debug.shared.log(message: "New model version available: \(modelInfo.latestModelVersion) (current: \(currentVersion))", type: .info)
                
                // Download and update
                let tempModelURL = try await downloadModel(version: modelInfo.latestModelVersion)
                let compiledModelURL = try await compileAndSaveModel(at: tempModelURL)
                
                // Update current version
                UserDefaults.standard.set(modelInfo.latestModelVersion, forKey: currentModelVersionKey)
                
                // Post notification for other components
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name("AIModelUpdated"), object: nil)
                }
                
                return true
            } else {
                Debug.shared.log(message: "Model is already up to date (version \(currentVersion))", type: .info)
                return false
            }
        } catch {
            Debug.shared.log(message: "Error checking for model updates: \(error)", type: .error)
            return false
        }
    }
    
    /// Get the URL to the latest model
    func getLatestModelURL() -> URL? {
        // Get the current model version
        let version = UserDefaults.standard.string(forKey: currentModelVersionKey) ?? "1.0.0"
        
        // Get documents directory
        guard let documentsDir = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else {
            return nil
        }
        
        // Get the compiled model directory
        let modelsDir = documentsDir.appendingPathComponent("AIModels", isDirectory: true)
        let modelName = "model_\(version).mlmodelc"
        let modelURL = modelsDir.appendingPathComponent(modelName)
        
        // Check if the model exists
        if FileManager.default.fileExists(atPath: modelURL.path) {
            return modelURL
        }
        
        return nil
    }
}

// MARK: - Data Structures for API Interaction

extension BackdoorAIClient {
    /// User feedback on an AI interaction
    struct Feedback: Codable {
        let rating: Int
        let comment: String?
    }
    
    /// A single user interaction with the AI
    struct Interaction: Codable {
        let id: String
        let timestamp: String // ISO8601 formatted date
        let userMessage: String
        let aiResponse: String
        let detectedIntent: String
        let confidenceScore: Double
        let feedback: Feedback?
    }
    
    /// A single user behavior within the app
    struct AppBehavior: Codable {
        let id: String
        let timestamp: String // ISO8601 formatted date
        let action: String
        let screen: String
        let duration: TimeInterval
        let details: [String: String]
    }
    
    /// A pattern of app usage
    struct UsagePattern: Codable {
        let id: String
        let timestamp: String // ISO8601 formatted date
        let feature: String
        let timeSpent: TimeInterval
        let actionSequence: [String]
        let completedTask: Bool
    }
    
    /// Complete data package to send to the server
    struct DeviceData: Codable {
        let deviceId: String
        let appVersion: String
        let modelVersion: String
        let osVersion: String
        let interactions: [Interaction]
        let behaviors: [AppBehavior]
        let patterns: [UsagePattern]
    }
    
    /// Response from the server containing model information
    struct ModelInfo: Codable {
        let success: Bool
        let message: String
        let latestModelVersion: String
        let modelDownloadURL: String?
    }
    
    /// Errors that can occur during API operations
    enum APIError: Error, LocalizedError {
        case invalidResponse
        case modelNotFound
        case encodingFailed
        case decodingFailed
        case downloadFailed
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "The server returned an invalid response"
            case .modelNotFound:
                return "The requested model was not found"
            case .encodingFailed:
                return "Failed to encode data for upload"
            case .decodingFailed:
                return "Failed to decode server response"
            case .downloadFailed:
                return "Failed to download model"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
}
