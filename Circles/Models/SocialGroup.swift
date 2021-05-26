//
//  KSChannel.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 11/3/20.
//

import Foundation
import MatrixSDK

//typealias SocialGroup = MatrixRoom

class SocialGroup: ObservableObject, Identifiable {
    var room: MatrixRoom
    var container: GroupsContainer
    
    init(from room: MatrixRoom, on container: GroupsContainer) {
        self.room = room
        self.container = container
    }
    
    var id: String {
        self.room.id
    }
    
    func leave(completion: @escaping (MXResponse<String>)->Void)
    {
        self.container.leave(group: self, completion: completion)
    }
}

/*
class KSChannel: MatrixRoom {
    
}
*/
