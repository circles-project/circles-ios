//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PhotoGallery.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/2/21.
//

import Foundation
import MatrixSDK

class PhotoGallery: ObservableObject, Identifiable, Equatable, Hashable {
    var room: MatrixRoom
    var session: CirclesSession
    
    init(room: MatrixRoom, session: CirclesSession) {
        self.room = room
        self.session = session
    }
    
    var id: String {
        self.room.id
    }
    
    var galleryId: RoomId {
        room.roomId
    }
    
    func leave(reason: String? = nil) async throws {
        try await session.leaveGallery(galleryId: galleryId, reason: reason)
    }
    
    static func == (lhs: PhotoGallery, rhs: PhotoGallery) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        self.galleryId.hash(into: &hasher)
    }
    
    
}
