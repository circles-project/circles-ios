//
//  Array+RawRepresentable.swift
//  Circles
//
//  Created by Charles Wright on 11/10/23.
//

import Foundation

extension Array: RawRepresentable where Element: Codable {
    // Tried to use Data but it doesn't work... Trying String
    public typealias RawValue = String

    public init?(rawValue: String) {
        let decoder = JSONDecoder()
        guard let data = rawValue.data(using: .utf8),
              let array = try? decoder.decode([Element].self, from: data)
        else {
            return nil
        }
        self = array
    }
    
    public var rawValue: String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return string
    }
}
