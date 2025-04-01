// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import Foundation

/// Extension for BackdoorAIClient to ensure all async calls are properly awaited
extension BackdoorAIClient {
    // Add an async version of getLatestModelURL that uses proper await syntax
    func getLatestModelURLAsync() async -> URL? {
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
