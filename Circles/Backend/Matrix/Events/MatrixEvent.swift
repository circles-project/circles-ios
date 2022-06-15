//
//  MatrixEvent.swift
//  Circles
//
//  Created by Charles Wright on 5/12/22.
//

import Foundation

protocol MatrixEvent: Codable {
    var type: MatrixEventType {get}
    var content: Codable {get}
}
