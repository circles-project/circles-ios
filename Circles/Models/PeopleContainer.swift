//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PeopleContainer.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/2/21.
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
        
        //self.reload()
    }
    
    func reload() {

        self.people = []
        
        //var dgroup = DispatchGroup()
        
        print("RELOAD\tBOOM!  Ay!  Whoop!  Starting Reload!")
        //self.people.removeAll()
        
        var newPeople: Set<MatrixUser> = []

        /* // 2021-09-01 Not doing to include the groupies for 1.0

        // Groupies: Everyone who's in a group with us
        let groups = store.getGroups().groups
        print("RELOAD\tFound \(groups.count) groups")

        for grp in groups {
            dgroup.enter()
            grp.room.asyncMembers { response in
                print("RELOAD\tGot response for group [\(grp.room.displayName ?? grp.room.id)]")
                switch(response) {
                case .failure(let err):
                    print("RELOAD\tCouldn't get group members for room \(grp.room.displayName ?? grp.room.id)")
                    break
                case .success(let groupies):
                    print("RELOAD\tGot \(groupies.count) users from group \(grp.room.displayName ?? grp.room.id)")
                    self.queue.async {
                        //self.people.append(contentsOf: groupies)
                        //newPeople.formUnion(groupies)

                        for member in groupies {
                            if !self.people.contains(member) {
                                self.people.append(member)
                            }
                        }
                    }
                }
                dgroup.leave()
            }
        }
        */
        
        let circles = store.getCircles()
        print("RELOAD\tFound \(circles.count) circles")
        var circleRooms: Set<MatrixRoom> = []
        circleRooms = circles.reduce(circleRooms) { (curr,circle) in
            curr.union(circle.stream.rooms)
        }
        print("RELOAD\tFound \(circleRooms.count) rooms")

        // Find my followers
        for room in circleRooms {
            if room.tags.contains(ROOM_TAG_OUTBOUND) {
                //dgroup.enter()
                room.asyncMembers { response in
                    print("RELOAD\tGot response for circle room [\(room.displayName ?? room.id)]")

                    switch(response) {
                    case .failure(let err):
                        print("RELOAD\tCouldn't get any members for room \(room.displayName ?? room.id)")
                        break
                    case .success(let followers):
                        self.queue.async {
                            print("RELOAD\tGot \(followers.count) followers from circle room \(room.displayName ?? room.id)")
                            //self.people.append(contentsOf: users)
                            newPeople.formUnion(followers)
                        }
                    }
                    //dgroup.leave()
                }
            }
        }

        // Find the people I'm following
        for room in circleRooms {
            /*
            dgroup.enter()
            room.asyncOwners { response in
                switch(response) {
                case .failure(let err):
                    print("RELOAD\tCouldn't get any owners for room \(room.displayName ?? room.id)")
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
            */
            if let creator = room.creator {
                if !people.contains(creator) {
                    people.append(creator)
                }
            }
        }

        /*
        dgroup.notify(queue: self.queue) {
            let me = self.store.me()
            let newArray = newPeople
                .subtracting([me])
                .compactMap { user in
                    user
                }
                //.sorted(by: {$0.id < $1.id})
            //self.people.removeAll()
            //self.people.append(contentsOf: newArray)
            //self.people = newArray
            print("RELOAD\tWe have \(self.people.count) people after reload()")
        }
        */
    }
}
