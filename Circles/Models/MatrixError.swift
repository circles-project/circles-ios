//
//  MatrixError.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 5/4/21.
//

import Foundation

struct MatrixError: Error, Codable {
    var errcode: String
    var error: String
}
