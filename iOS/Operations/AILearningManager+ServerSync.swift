// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import Foundation

// MARK: - Server Synchronization Extension

extension AILearningManager {
    
    /// Queue data for server synchronization
    func queueForServerSync() {
        // Don't queue if server sync is disabled
        guard isServerSyncEnabled else {
            return
        }
        
        // Set the sync flag - we'll process it in a background task
        UserDefaults.standard.set(true, forKey: "AINeedsSyncWithServer")
        
        // Schedule sync if needed
        scheduleServerSync()
    }
    
    /// Schedule server synchronization
    func scheduleServerSync() {
        // Check if sync is already scheduled
        if UserDefaults.standard.bool(forKey: "AIServerSyncScheduled") {
            return
        }
        
        // Set the scheduled flag
        UserDefaults.standard.set(true, forKey: "AIServerSyncScheduled")
        
        // Schedule the sync after a delay to batch multiple changes
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 30.0) { [weak self] in
            guard let self = self else { return }
            
            // Reset the scheduled flag
            UserDefaults.standard.set(false, forKey: "AIServerSyncScheduled")
            
            // Check if sync is still needed
            if UserDefaults.standard.bool(forKey: "AINeedsSyncWithServer") {
                // Reset the needs sync flag before starting
                UserDefaults.standard.set(false, forKey: "AINeedsSyncWithServer")
                
                // Perform sync
                Task {
                    await self.syncWithServer()
                }
            }
        }
    }
    
    /// Synchronize local data with the server
    func syncWithServer() async {
        // Don't sync if disabled
        guard isServerSyncEnabled else {
            return
        }
        
        Debug.shared.log(message: "Starting AI server synchronization", type: .info)
        
        // Get data to sync
        interactionsLock.lock()
        behaviorsLock.lock()
        patternsLock.lock()
        
        // Copy data to avoid threading issues
        let interactionsToSync = storedInteractions
        let behaviorsToSync = userBehaviors
        let patternsToSync = appUsagePatterns
        
        // Unlock
        interactionsLock.unlock()
        behaviorsLock.unlock()
        patternsLock.unlock()
        
        // Filter for interactions with feedback (prioritize those)
        let interactionsWithFeedback = interactionsToSync.filter { $0.feedback != nil }
        let otherInteractions = interactionsToSync.filter { $0.feedback == nil }
        
        // Calculate the number of interactions to send (all with feedback plus up to 20 without)
        let maxOtherInteractions = min(otherInteractions.count, 20)
        let interactionsToSend = interactionsWithFeedback + otherInteractions.prefix(maxOtherInteractions)
        
        // Only sync if we have data
        if interactionsToSend.isEmpty && behaviorsToSync.isEmpty && patternsToSync.isEmpty {
            Debug.shared.log(message: "No data to sync with server", type: .info)
            return
        }
        
        // Upload data
        do {
            // Some servers might not support the behaviors/patterns fields yet,
            // so include only if there are non-empty arrays
            let modelInfo = try await BackdoorAIClient.shared.uploadInteractions(
                interactions: interactionsToSend,
                behaviors: behaviorsToSync.isEmpty ? [] : behaviorsToSync,
                patterns: patternsToSync.isEmpty ? [] : patternsToSync
            )
            
            Debug.shared.log(message: "Successfully synchronized with server. Latest model: \(modelInfo.latestModelVersion)", type: .info)
            
            // Check if we need to update our model
            let currentVersion = UserDefaults.standard.string(forKey: "currentModelVersion") ?? "1.0.0"
            if modelInfo.latestModelVersion != currentVersion {
                // Trigger model update
                Debug.shared.log(message: "New model available from server: \(modelInfo.latestModelVersion)", type: .info)
                
                // Check and update model
                let success = await BackdoorAIClient.shared.checkAndUpdateModel()
                
                if success {
                    Debug.shared.log(message: "Successfully updated AI model from server", type: .info)
                }
            }
            
            // Clear synced data after successful upload
            removeSuccessfullySyncedData(interactions: interactionsToSend, behaviors: behaviorsToSync, patterns: patternsToSync)
            
        } catch {
            Debug.shared.log(message: "Failed to sync with server: \(error)", type: .error)
            
            // Re-queue for sync after failure
            UserDefaults.standard.set(true, forKey: "AINeedsSyncWithServer")
            
            // Try again later with exponential backoff
            let retryDelay = getNextRetryDelay()
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + retryDelay) {
                UserDefaults.standard.set(false, forKey: "AIServerSyncScheduled")
                Task {
                    await self.syncWithServer()
                }
            }
        }
    }
    
    /// Remove data that has been successfully synced with the server
    private func removeSuccessfullySyncedData(interactions: [AIInteraction], behaviors: [UserBehavior], patterns: [AppUsagePattern]) {
        // Remove synced interactions
        interactionsLock.lock()
        let interactionIdsToRemove = Set(interactions.map { $0.id })
        storedInteractions.removeAll { interactionIdsToRemove.contains($0.id) }
        interactionsLock.unlock()
        
        // Remove synced behaviors
        behaviorsLock.lock()
        let behaviorIdsToRemove = Set(behaviors.map { $0.id })
        userBehaviors.removeAll { behaviorIdsToRemove.contains($0.id) }
        behaviorsLock.unlock()
        
        // Remove synced patterns
        patternsLock.lock()
        let patternIdsToRemove = Set(patterns.map { $0.id })
        appUsagePatterns.removeAll { patternIdsToRemove.contains($0.id) }
        patternsLock.unlock()
        
        // Save changes
        saveInteractions()
        saveBehaviors()
        savePatterns()
        
        Debug.shared.log(message: "Removed \(interactionIdsToRemove.count) interactions, \(behaviorIdsToRemove.count) behaviors, and \(patternIdsToRemove.count) patterns after successful sync", type: .info)
    }
    
    /// Get exponential backoff delay for retries
    private func getNextRetryDelay() -> TimeInterval {
        let retryCount = UserDefaults.standard.integer(forKey: "AIServerSyncRetryCount")
        let baseDelay = 30.0 // 30 seconds base delay
        let maxDelay = 3600.0 // 1 hour max delay
        
        // Calculate exponential backoff
        let delay = min(baseDelay * pow(2.0, Double(retryCount)), maxDelay)
        
        // Increment retry count
        UserDefaults.standard.set(retryCount + 1, forKey: "AIServerSyncRetryCount")
        
        return delay
    }
    
    /// Reset retry count after successful sync
    private func resetRetryCount() {
        UserDefaults.standard.set(0, forKey: "AIServerSyncRetryCount")
    }
    
    /// Check for model updates from the server
    func checkForModelUpdates() async -> Bool {
        // Don't check if server sync is disabled
        guard isServerSyncEnabled else {
            return false
        }
        
        return await BackdoorAIClient.shared.checkAndUpdateModel()
    }
}
