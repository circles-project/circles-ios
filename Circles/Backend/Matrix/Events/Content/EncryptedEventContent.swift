//
//  EncryptedEventContent.swift
//  
//
//  Created by Charles Wright on 5/18/22.
//

import Foundation

protocol MatrixCiphertext: Codable {}

struct MegolmCiphertext: MatrixCiphertext {
    let base64: String
    
    init(from decoder: Decoder) throws {
        self.base64 = try .init(from: decoder)
    }
    
    func encode(to encoder: Encoder) throws {
        try self.base64.encode(to: encoder)
    }
}

struct OlmCiphertext: MatrixCiphertext {
    struct EncryptedPayload: Codable {
        let type: Int
        let body: String
    }
    let ciphertext: [String: EncryptedPayload]
    
    init(from decoder: Decoder) throws {
        self.ciphertext = try .init(from: decoder)
    }
    
    func encode(to encoder: Encoder) throws {
        try self.ciphertext.encode(to: encoder)
    }
}

struct EncryptedEventContent: MatrixMessageContent {
    enum Algorithm: String {
        case olmV1 = "m.olm.v1.curve25519-aes-sha2"
        case megolmV1 = "m.megolm.v1.aes-sha2"
    }
    
    let algorithm: Algorithm
    let senderKey: String
    let deviceId: String
    let sessionId: String
    let ciphertext: MatrixCiphertext
    
    enum CodingKeys: String, CodingKey {
        case algorithm
        case senderKey = "sender_key"
        case deviceId = "device_id"
        case sessionId = "session_id"
        case ciphertext
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.algorithm = try container.decode(Algorithm.self, forKey: .algorithm)
        self.senderKey = try container.decode(String.self, forKey: .senderKey)
        self.deviceId = try container.decode(String.self, forKey: .deviceId)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        
        switch self.algorithm {
        case .olmV1:
            self.ciphertext = try container.decode(OlmCiphertext.self, forKey: .ciphertext)
        case .megolmV1:
            self.ciphertext = try container.decode(MegolmCiphertext.self, forKey: .ciphertext)
        }
    }
}

struct EventPlaintextPayload: Codable {
    let type: String
    let content: MatrixMessageContent
    let roomId: String
    
    init(from decoder: Decoder) throws {
        // FIXME: Need to borrow code from MatrixClientEvent to decode this thing
    }
    
    // As with MatrixClientEvent, support for .encode() and Encodable should be automatic, since the only ambiguity is on the input side.
    // Once we have a Codable MatrixMessageContent, whatever it is, it knows how to encode itself.
}
