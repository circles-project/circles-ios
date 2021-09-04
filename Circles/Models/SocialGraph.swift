//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  SocialGraph.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/5/20.
//

import Foundation
import MatrixSDK

protocol SocialGraph {
    
    var matrix: MatrixInterface { get }

    func getGroups() -> GroupsContainer
        
    //func getCircles() -> [SocialCircle]
    
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
    
    //var photoGalleries: [MatrixRoom] { get }
    func getPhotoGalleries() -> PhotoGalleriesContainer
}
