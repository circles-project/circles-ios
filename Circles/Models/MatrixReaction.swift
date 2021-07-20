//
//  MatrixReaction.swift
//  Circles
//
//  Created by Charles Wright on 7/20/21.
//

import Foundation

struct MatrixReaction: Hashable {
    let emoji: String
    let count: UInt
}

extension MatrixReaction: Identifiable {
    var id: String {
        emoji
    }
}
