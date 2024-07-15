//
//  Keychain.swift
//  Circles
//
//  Created by Charles Wright on 4/12/23.
//

import Foundation
import Security

import Matrix

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

// https://developer.apple.com/documentation/security/keychain_services/keychain_items/adding_a_password_to_the_keychain
func savePassword(userId: UserId, password: String) throws {
    let query: [String: Any] = [
        kSecClass as String: kSecClassInternetPassword,
        kSecAttrAccount as String: "\(userId)",
        kSecAttrServer as String: userId.domain,
        kSecValueData as String: password.data(using: .utf8)!
    ]
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess
    else {
        throw KeychainError.unhandledError(status: status)
    }
}

func saveAccessToken(creds: Matrix.Credentials) throws {
    let query: [String: Any] = [
        kSecClass as String: kSecClassInternetPassword,
        kSecAttrAccount as String: "\(creds.userId)::\(creds.deviceId)",
        kSecAttrServer as String: creds.userId.domain,
        kSecValueData as String: creds.accessToken.data(using: .utf8)!
    ]
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess
    else {
        throw KeychainError.unhandledError(status: status)
    }
}

// https://developer.apple.com/documentation/security/keychain_services/keychain_items/searching_for_keychain_itemsa
func loadAccessToken(userId: UserId, deviceId: String) throws -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassInternetPassword,
        kSecAttrServer as String: userId.domain,
        //kSecAttrAccount as String: "\(userId)/\(deviceId)",
        kSecMatchLimit as String: kSecMatchLimitAll,
        kSecReturnAttributes as String: true,
        kSecReturnData as String: true
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status != errSecItemNotFound else { throw KeychainError.noPassword }
    guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    
    guard let existingItems = item as? [[String : Any]]
    else {
        throw KeychainError.unexpectedPasswordData
    }
    for existingItem in existingItems {
        guard let accessTokenData = existingItem[kSecValueData as String] as? Data,
              let accessToken = String(data: accessTokenData, encoding: String.Encoding.utf8),
              let accountString = existingItem[kSecAttrAccount as String] as? String
        else {
            throw KeychainError.unexpectedPasswordData
        }
        if accountString == "\(userId)/\(deviceId)" {
            return accessToken
        }
    }

    return nil
}
