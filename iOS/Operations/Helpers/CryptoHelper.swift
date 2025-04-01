// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import Foundation
import CryptoSwift

/// Helper for advanced cryptography operations using CryptoSwift
class CryptoHelper {
    // Singleton instance
    static let shared = CryptoHelper()
    
    private init() {}
    
    // MARK: - Encryption Methods
    
    /// Encrypt data using AES with a password
    /// - Parameters:
    ///   - data: Data to encrypt
    ///   - password: Password for encryption
    /// - Returns: Encrypted data as a base64 string
    func encryptAES(_ data: Data, password: String) -> String? {
        do {
            // Create key and IV from password
            let key = try PKCS5.PBKDF2(
                password: Array(password.utf8),
                salt: Array("backdoorsalt".utf8),
                keyLength: 32, // AES-256
                iterations: 4096
            ).calculate()
            
            // Random IV (initialization vector)
            let iv = AES.randomIV(AES.blockSize)
            
            // Create AES with CBC mode and PKCS7 padding
            let aes = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
            
            // Encrypt
            let encrypted = try aes.encrypt(data.bytes)
            
            // Prepend IV to the encrypted data
            let encryptedWithIV = iv + encrypted
            
            // Convert to base64 for storage/transmission
            return encryptedWithIV.toBase64()
        } catch {
            Debug.shared.log(message: "AES encryption failed: \(error)", type: .error)
            return nil
        }
    }
    
    /// Decrypt data using AES with a password
    /// - Parameters:
    ///   - encryptedBase64: Base64 encoded encrypted data with IV prepended
    ///   - password: Password for decryption
    /// - Returns: Decrypted data
    func decryptAES(_ encryptedBase64: String, password: String) -> Data? {
        do {
            // Convert base64 to bytes
            guard let encryptedBytes = Array<UInt8>(base64: encryptedBase64) else {
                Debug.shared.log(message: "Failed to decode base64 data", type: .error)
                return nil
            }
            
            // Extract IV (first 16 bytes for AES)
            let iv = Array(encryptedBytes.prefix(AES.blockSize))
            let encryptedData = Array(encryptedBytes.suffix(from: AES.blockSize))
            
            // Create key from password
            let key = try PKCS5.PBKDF2(
                password: Array(password.utf8),
                salt: Array("backdoorsalt".utf8),
                keyLength: 32, // AES-256
                iterations: 4096
            ).calculate()
            
            // Create AES with CBC mode and PKCS7 padding
            let aes = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
            
            // Decrypt
            let decrypted = try aes.decrypt(encryptedData)
            
            return Data(decrypted)
        } catch {
            Debug.shared.log(message: "AES decryption failed: \(error)", type: .error)
            return nil
        }
    }
    
    // MARK: - Hashing Methods
    
    /// Calculate SHA-256 hash of a string
    /// - Parameter input: String to hash
    /// - Returns: Hex string of the hash
    func sha256(_ input: String) -> String {
        return input.sha256()
    }
    
    /// Calculate SHA-512 hash of a string
    /// - Parameter input: String to hash
    /// - Returns: Hex string of the hash
    func sha512(_ input: String) -> String {
        return input.sha512()
    }
    
    /// Calculate HMAC using SHA-256
    /// - Parameters:
    ///   - input: Data to authenticate
    ///   - key: Key for HMAC
    /// - Returns: HMAC result as a hex string
    func hmac(_ input: String, key: String) -> String {
        do {
            let hmac = try HMAC(key: Array(key.utf8), variant: .sha2(.sha256)).authenticate(Array(input.utf8))
            return hmac.toHexString()
        } catch {
            Debug.shared.log(message: "HMAC calculation failed: \(error)", type: .error)
            return ""
        }
    }
    
    /// Derive a key from a password
    /// - Parameters:
    ///   - password: Source password
    ///   - salt: Salt for key derivation
    ///   - keyLength: Length of key to generate
    ///   - iterations: Number of iterations
    /// - Returns: Derived key as hex string or nil on failure
    func deriveKey(password: String, salt: String, keyLength: Int = 32, iterations: Int = 10000) -> String? {
        do {
            let derived = try PKCS5.PBKDF2(
                password: Array(password.utf8),
                salt: Array(salt.utf8),
                keyLength: keyLength,
                iterations: iterations
            ).calculate()
            
            return derived.toHexString()
        } catch {
            Debug.shared.log(message: "Key derivation failed: \(error)", type: .error)
            return nil
        }
    }
    
    // MARK: - Certificate Utilities
    
    /// Generate a random symmetric key
    /// - Parameter length: Key length in bytes
    /// - Returns: Random key as hex string
    func generateRandomKey(length: Int = 32) -> String {
        let bytes = (0..<length).map { _ in UInt8.random(in: 0...255) }
        return bytes.toHexString()
    }
    
    /// Compute the CRC32 checksum of data
    /// - Parameter data: Input data
    /// - Returns: CRC32 checksum
    func crc32(of data: Data) -> UInt32 {
        return CRC32.checksum(bytes: data.bytes)
    }
}
