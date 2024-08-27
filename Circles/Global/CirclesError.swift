//
//  CirclesError.swift
//  Circles
//
//  Created by Charles Wright on 4/27/22.
//

import Foundation

struct CirclesError: Error {
    var message: String
    
    init(_ message: String) {
        self.message = message
    }
}
