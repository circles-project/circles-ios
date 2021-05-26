//
//  PhotoGallery.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 2/2/21.
//

import Foundation
import MatrixSDK

class PhotoGallery: ObservableObject, Identifiable {
    var room: MatrixRoom
    var container: PhotoGalleriesContainer
    
    init(from room: MatrixRoom, on container: PhotoGalleriesContainer) {
        self.room = room
        self.container = container
    }
    
    var id: String {
        self.room.id
    }
    
    func leave(completion: @escaping (MXResponse<String>)->Void)
    {
        self.container.leave(gallery: self, completion: completion)
    }
}
