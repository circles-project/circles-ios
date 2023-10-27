//
//  Room+URL.swift
//  Circles
//
//  Created by Charles Wright on 10/27/23.
//

import Foundation
import Matrix

// cvw: Putting this here rather than in Matrix.swift because these URLs are specific to Circles
//      For a generic Matrix chat client, you would probably want to use matrix.to instead, or the new matrix:// URL type
extension Matrix.Room {
    var url: URL {
        
        func urlPrefix() -> String {
            switch self.type {
            case ROOM_TYPE_CIRCLE:
                return "timeline"
            case ROOM_TYPE_GROUP:
                return "group"
            case ROOM_TYPE_PHOTOS:
                return "gallery"
            case ROOM_TYPE_SPACE:
                return "profile"
            default:
                return "room"
            }
        }
        
        let prefix = urlPrefix()
        
        return URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/\(prefix)/\(self.roomId)")!
    }
}
