//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PhotoGalleriesContainer.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/2/21.
//

import Foundation
import MatrixSDK

/*
  FIXME: This class should be a generic.
  This and GroupsContainer are *exactly* the same code, just with a different associated type.
  However, on the first try I couldn't figure out how to make Swift understand that
  I wanted two sets of generic classes that work together, the Container and the "Contained".
  So, following the YAGNI principle, here's the crude "git 'r done" version.
*/

class PhotoGalleriesContainer: ObservableObject {
    var matrix: MatrixInterface
    @Published var galleries: [PhotoGallery] = []
    
    init(_ interface: MatrixInterface) {
        self.matrix = interface
        
        // Because we can't initialize any SocialGroup instances using our current 'self' as the GroupsContainer...
        // Why doing it in this function is better, I'm not sure...
        self.reload()
    }
    
    func reload() {
        //if !self.galleries.isEmpty {
            self.galleries.removeAll()
        //}
        let newGalleries = self.matrix.getRooms(for: ROOM_TAG_PHOTOS)
            .map { room in
                PhotoGallery(from: room, on: self)
            }
        self.galleries.append(contentsOf: newGalleries)
    }
    
    /*
    var groups: [MatrixRoom] {
        matrix.getRooms(for: ROOM_TAG_GROUP)
    }
    */
        
    func create(name: String, completion: @escaping (MXResponse<PhotoGallery>) -> Void)
    {
        self.matrix.createRoom(name: name,
                               with: ROOM_TAG_PHOTOS,
                               insecure: false
        ) { response in
            switch(response) {
            case .failure(let err):
                let msg = "Failed to create Room for new Gallery [\(name)]"
                print(msg)
                completion(.failure(KSError(message: msg)))
            case .success(let roomId):
                if let room = self.matrix.getRoom(roomId: roomId) {
                    room.setRoomType(type: ROOM_TYPE_PHOTOS) { response2 in
                        if response2.isSuccess {
                            self.objectWillChange.send()
                            let newGallery = PhotoGallery(from: room, on: self)
                            self.galleries.insert(newGallery, at: 0)
                            completion(.success(newGallery))
                        }
                        else {
                            // No reason to leave the room hanging around
                            self.matrix.leaveRoom(roomId: roomId, completion: {_ in })

                            let msg = "Failed to tag new Room as a Group"
                            completion(.failure(KSError(message: msg)))
                        }
                    }
                }
                else {
                    let msg = "Couldn't create MatrixRoom from mxroom"
                    completion(.failure(KSError(message: msg)))
                }
            }
        }
    }
    
    func leave(gallery: PhotoGallery, completion: @escaping (MXResponse<String>)->Void)
    {
        self.matrix.leaveRoom(roomId: gallery.room.id) { success in
            if success {
                self.galleries.removeAll(where: { candidate in
                    candidate.id == gallery.id
                })
                completion(.success(gallery.id))
            }
            else {
                let msg = "Failed to leave group \(gallery.id)"
                completion(.failure(KSError(message: msg)))
            }
        }
    }
}
