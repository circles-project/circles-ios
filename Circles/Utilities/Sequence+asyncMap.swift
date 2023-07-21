//
//  Sequence+asyncMap.swift
//  Circles
//
//  Created by Charles Wright on 3/14/23.
//

import Foundation

// Based on https://www.swiftbysundell.com/articles/async-and-concurrent-forEach-and-map/
extension Sequence {
    func map<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
    
    func compactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            let t = try await transform(element)
            if t != nil {
                values.append(t!)
            }
        }

        return values
    }
}
