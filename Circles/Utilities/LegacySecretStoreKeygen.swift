//
//  LegacySecretStoreKeygen.swift
//  Circles
//
//  Created by Charles Wright on 7/24/23.
//

import Foundation
import CryptoKit
import Matrix


func generateLegacySecretStorageKey(userId: UserId, password: String) throws -> (String, Data) {
    // Update 2021-06-16 - Adding my crazy scheme for doing
    //                     SSSS using only a single password
    //
    // First we bcrypt the password to get a secret that is
    // resistant to brute force and dictionary attack.
    // Then we use the symmetric ratchet to generate two keys
    // * ~~One for the login password~~ (This one we can now ignore)
    // * One for the secret "private key" for the recovery service (This is the secret storage key)

    let username = userId.username.trimmingCharacters(in: ["@"])

    print("SECRETS\tExtracted username [\(username)] from given userId [\(userId)]")

    guard let data = username.data(using: .utf8) else {
        let msg = "Failed to convert username to data"
        print("SECRETS\t\(msg)")
        throw CirclesError(msg)
    }

    let saltDigest = SHA256.hash(data: data)
    let saltString = saltDigest
        .map { String(format: "%02hhx", $0) }
        .prefix(16)
        .joined()
    print("SECRETS\tComputed salt string = [\(saltString)]")

    let numRounds = 14
    guard let bcrypt = try? BCrypt.Hash(password, salt: "$2a$\(numRounds)$\(saltString)") else {
        let msg = "BCrypt KDF failed"
        print("SECRETS\t\(msg)")
        throw CirclesError(msg)
    }
    print("SECRETS\tGot bcrypt hash = [\(bcrypt)]")
    print("       \t                   12345678901234567890123456789012345678901234567890")

    // Grabbing everything after the $ gives us the salt as well as the hash
    //let root = String(bcrypt.suffix(from: bcrypt.lastIndex(of: "$")!).dropFirst(1))
    // Grabbing only the last 31 chars gives us just the hash
    let root = String(bcrypt.suffix(31))
    print("SECRETS\tRoot secret = [\(root)]  (\(root.count) chars)")

    /*
    let newLoginPassword = SHA256.hash(data: "LoginPassword|\(root)".data(using: .utf8)!)
        .prefix(16)
        .map { String(format: "%02hhx", $0) }
        .joined()
    print("SECRETS\tGot new login password = [\(newLoginPassword)]")
    */
     
    let newPrivateKey = SHA256.hash(data: "S4Key|\(root)".data(using: .utf8)!)
        .withUnsafeBytes {
            Data(Array($0))
        }
    print("SECRETS\tGot new private key = [\(newPrivateKey)]")


    //let keyId = try Matrix.SecretStore.computeKeyId(key: newPrivateKey)
    let keyId = UUID().uuidString
    
    return (keyId, newPrivateKey)
}
