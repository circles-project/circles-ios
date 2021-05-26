//
//  PeopleContainer.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 2/2/21.
//

import Foundation
import MatrixSDK

class PeopleContainer: ObservableObject {
    var store: KSStore
    var queue: DispatchQueue
    @Published var people: [MatrixUser] = []
    
    
    init(_ store: KSStore) {
        self.store = store
        self.queue = DispatchQueue(label: "PeopleContainer", qos: .background)
        
        self.reload()
    }
    
    func reload() {
        
        var dgroup = DispatchGroup()
        
        print("RELOAD\tBOOM!  Ay!  Whoop!  Starting Reload!")
        //self.people.removeAll()
        
        var newPeople: Set<MatrixUser> = []

        // Groupies: Everyone who's in a group with us
        let groups = store.getGroups().groups
        print("RELOAD\tFound \(groups.count) groups")

        for grp in groups {
            dgroup.enter()
            grp.room.asyncMembers { response in
                print("RELOAD\tGot response for group [\(grp.room.displayName ?? grp.room.id)]")
                switch(response) {
                case .failure(let err):
                    break
                case .success(let groupies):
                    print("RELOAD\tGot \(groupies.count) users from group \(grp.room.displayName ?? grp.room.id)")
                    self.queue.async {
                        //self.people.append(contentsOf: groupies)
                        newPeople.formUnion(groupies)
                    }
                }
                dgroup.leave()
            }
        }
        
        let circles = store.getCircles()
        print("RELOAD\tFound \(circles.count) circles")
        var circleRooms: Set<MatrixRoom> = []
        circleRooms = circles.reduce(circleRooms) { (curr,circle) in
            curr.union(circle.stream.rooms)
        }
        print("RELOAD\tFound \(circleRooms.count) rooms")

        for room in circleRooms {
            dgroup.enter()
            room.asyncMembers { response in
                print("RELOAD\tGot response for circle room [\(room.displayName ?? room.id)]")

                switch(response) {
                case .failure(let err):
                    break
                case .success(let followers):
                    self.queue.async {
                        print("RELOAD\tGot \(followers.count) followers from circle room \(room.displayName ?? room.id)")
                        //self.people.append(contentsOf: users)
                        newPeople.formUnion(followers)
                    }
                }
                dgroup.leave()
            }
        }

        for room in circleRooms {
            dgroup.enter()
            room.asyncOwners { response in
                switch(response) {
                case .failure(let err):
                    break
                case .success(let leaders):
                    self.queue.async {
                        print("RELOAD\tGot \(leaders.count) leaders from circle room \(room.displayName ?? room.id)")
                        //self.people.append(contentsOf: owners)
                        newPeople.formUnion(leaders)
                    }
                }
                dgroup.leave()
            }
        }
        
        dgroup.notify(queue: self.queue) {
            let me = self.store.me()
            let newArray = newPeople
                .subtracting([me])
                .compactMap { user in
                    user
                }
                .sorted(by: {$0.id < $1.id})
            self.people.removeAll()
            self.people.append(contentsOf: newArray)
        }
    }
}
