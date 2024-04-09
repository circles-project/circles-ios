//
//  PowerLevel.swift
//  Circles
//
//  Created by Charles Wright on 4/9/24.
//

import Foundation

struct PowerLevel: Identifiable, Equatable, Hashable {
    var power: Int
    
    var id: Int {
        power
    }
    
    var description: String {
        if power < 0 {
            return "Can View"
        } else if power < 50 {
            return "Can Post"
        } else if power < 100 {
            return "Moderator"
        } else {
            return "Admin"
        }
    }
    
    static func ==(lhs: PowerLevel, rhs: PowerLevel) -> Bool {
        lhs.power == rhs.power
    }
}
