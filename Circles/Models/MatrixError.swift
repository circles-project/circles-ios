//
//  MatrixError.swift
//  Circles for iOS
//
//  Created by Charles Wright on 5/4/21.
//

import Foundation

struct MatrixError: Error, Codable {
    var errcode: String
    var error: String
}
