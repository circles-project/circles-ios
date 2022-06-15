//
//  RoomEncryptionContent.swift
//  
//
//  Created by Charles Wright on 5/18/22.
//

import Foundation

struct RoomEncryptionContent: Codable {
    enum Algorithm: String, Codable {
        case megolmV1AesSha2 = "m.megolm.v1.aes-sha2"
    }
    let algorithm: Algorithm
    let rotationPeriodMs: Int
    let rotationPeriodMsgs: Int
}
