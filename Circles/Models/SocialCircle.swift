//
//  SocialCircle.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/14/20.
//

import Foundation
import MatrixSDK

class SocialCircle: ObservableObject, Identifiable {
    var graph: SocialGraph
    //var store: KSStore
    var matrix: MatrixInterface
    
    var id: String
    var tag: String
    var name: String
    
    var stream: SocialStream
    
    class func randomId() -> String {
        let range: Range<UInt64> = 0 ..< (1 << 53)
        let id = UInt64.random(in: range)
        let circleId = String(format: "%016qx", id)
        return circleId
    }
    
    init(circleId: String, name: String, graph: SocialGraph) {
        //self.graph = store as SocialGraph
        //self.matrix = store as MatrixInterface
        self.graph = graph
        self.matrix = graph.matrix
        
        self.id = circleId
        self.name = name
        self.tag = "social.kombucha.circles." + self.id
        
        self.stream = SocialStream(name: name, tag: tag, matrix: graph.matrix)
    }
    
    var outbound: MatrixRoom? {
        stream.rooms.filter { room in
            print("OUTBOUND\tFound room \(room.id)")
            for tag in room.tags {
                print("OUTBOUND\t\tTag: \(tag)")
            }
            return room.tags.contains(ROOM_TAG_OUTBOUND)
        }
        .first
    }
    
    var followers: [MatrixUser] {
        var members = self.outbound?.joinedMembers ?? []
        members.removeAll { user in
            user == matrix.me()
        }
        return members
    }
    
    func unfollow(room: MatrixRoom, completion handler: @escaping (MXResponse<Void>) -> Void) {
        self.stream.removeRoom(room: room, completion: handler)
    }
}

extension SocialCircle: Hashable {
    static func == (lhs: SocialCircle, rhs: SocialCircle) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
