//
//  CustomErrors.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/5/24.
//

import Foundation

enum CustomErrors: LocalizedError {
    case errorWith(message: String)
    
    var errorDescription: String? {
        switch self {
        case .errorWith(let message):
            return NSLocalizedString("Oops: \(message)", comment: "")
        }
    }
}
