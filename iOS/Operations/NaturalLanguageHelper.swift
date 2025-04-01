// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import Foundation
import NaturalLanguage
import SSNaturalLanguage

/// Helper class for natural language processing features
class NaturalLanguageHelper {
    
    // Singleton instance
    static let shared = NaturalLanguageHelper()
    
    private init() {}
    
    /// Detect the language of a given text
    func detectLanguage(in text: String) -> String {
        // First try with SSNaturalLanguage
        if let language = SSNLLanguageRecognizer.dominantLanguage(for: text) {
            return language
        }
        
        // Fall back to Apple's NaturalLanguage if needed
        if #available(iOS 13.0, *) {
            let tagger = NLTagger(tagSchemes: [.language])
            tagger.string = text
            if let language = tagger.dominantLanguage?.rawValue {
                return language
            }
        }
        
        return "unknown"
    }
    
    /// Get sentiment analysis for text
    func analyzeSentiment(in text: String) -> Double {
        // Use SSNaturalLanguage for sentiment analysis
        // Returns score from -1.0 (negative) to 1.0 (positive)
        return SSNLSentimentAnalyzer.getSentiment(for: text)
    }
    
    /// Extract entities from text
    func extractEntities(from text: String) -> [String: String] {
        var entities: [String: String] = [:]
        
        // Use SSNaturalLanguage for entity extraction
        let recognizedEntities = SSNLEntityRecognizer.getEntities(from: text)
        
        for entity in recognizedEntities {
            entities[entity.text] = entity.type.rawValue
        }
        
        return entities
    }
    
    /// Tokenize text into words
    func tokenize(text: String) -> [String] {
        return SSNLTokenizer.getTokens(from: text)
    }
}
