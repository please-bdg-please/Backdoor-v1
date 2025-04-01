// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import Foundation
import UIKit

/// Extension to ensure proper async/await usage in view controllers
extension ModelServerIntegrationViewController {
    
    /// Safe wrapper for async tasks that ensures proper await usage
    func performAsyncSafely(_ task: @escaping () async -> Void) {
        Task {
            await task()
        }
    }
    
    /// Safe method to check server status with proper async/await handling
    func checkServerStatusSafely() {
        performAsyncSafely { [weak self] in
            do {
                let modelInfo = try await BackdoorAIClient.shared.getLatestModelInfo()
                DispatchQueue.main.async {
                    self?.serverStatusLabel.text = "Server status: Online\nLatest model: \(modelInfo.latestModelVersion)"
                    self?.serverStatusLabel.textColor = .systemGreen
                }
            } catch {
                DispatchQueue.main.async {
                    self?.serverStatusLabel.text = "Server status: Error - \(error.localizedDescription)"
                    self?.serverStatusLabel.textColor = .systemRed
                }
            }
        }
    }
    
    /// Safe wrapper for model uploads using proper async/await
    func uploadModelSafely(completion: @escaping (Bool, String) -> Void) {
        performAsyncSafely { [weak self] in
            guard let self = self else { return }
            
            let result = await AILearningManager.shared.uploadTrainedModelToServer()
            
            DispatchQueue.main.async {
                completion(result.success, result.message)
            }
        }
    }
}
