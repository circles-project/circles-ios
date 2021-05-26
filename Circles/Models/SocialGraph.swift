//
//  SocialGraph.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 11/5/20.
//

import Foundation
import MatrixSDK

protocol SocialGraph {
    
    var matrix: MatrixInterface { get }

    /*
    //func getGroups() -> [MatrixRoom]
    var groups: [MatrixRoom] { get }
    
    //func createGroup(name: String, completion: @escaping (MXResponse<SocialGroup>) -> Void)
    
    func addGroup(room: MatrixRoom)
    
    func removeGroup(room: MatrixRoom)
    */
    func getGroups() -> GroupsContainer
        
    func getCircles() -> [SocialCircle]
    
    //func getFollowedRooms(for user: MatrixUser) -> [MatrixRoom]
    
    func createCircle(name: String, rooms: [MatrixRoom],
                      completion: @escaping (MXResponse<SocialCircle>) -> Void)
    
    func removeCircle(circle: SocialCircle)
    
    func saveCircles(completion: @escaping (MXResponse<String>) -> Void)
    
    func follow(room: InvitedRoom, in circle: SocialCircle)
    
    func unfollow(room: MatrixRoom, in circle: SocialCircle?)
    
    func getAllFollowedRooms() -> [MatrixRoom]
    
    // Shouldnt' this be something like getPeople instead?
    // Then we can have SocialPerson (or whatever) be a first-class object
    // where we track the info for that person
    func getUsersAndTheirRooms() -> [MatrixUser: Set<MatrixRoom>]
    
    func amINewHere(completion: @escaping (MXResponse<Bool>)->Void)
    
    func setupNewAccount(completion: @escaping (Bool) -> Void)
    
    //var photoGalleries: [MatrixRoom] { get }
    func getPhotoGalleries() -> PhotoGalleriesContainer
}
