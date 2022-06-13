//
//  MatrixCredentials.swift
//  Circles
//
//  Created by Charles Wright on 4/25/22.
//

import Foundation

struct MatrixCredentials: Codable {
    var accessToken: String
    var deviceId: String
    var userId: String
    var wellKnown: MatrixWellKnown?
    //var homeServer: String? // Warning: Deprecated; Do not use
}

/*
struct MatrixCredentialsWithoutWellKnown: Codable {
    var accessToken: String
    var deviceId: String
    var userId: String
}
*/
