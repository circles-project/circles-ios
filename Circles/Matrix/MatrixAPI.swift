//
//  Matrix+API.swift
//  Circles
//
//  Created by Charles Wright on 6/15/22.
//

import Foundation
import UIKit

import AnyCodable

    
class MatrixAPI {
    var creds: MatrixCredentials
    var baseUrl: URL
    let version: String
    private var apiUrlSession: URLSession   // For making API calls
    private var mediaUrlSession: URLSession // For downloading media
    
    init(creds: MatrixCredentials) throws {
        self.version = "r0"
        
        self.creds = creds
        
        let apiConfig = URLSessionConfiguration.default
        apiConfig.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(creds.accessToken)",
        ]
        apiConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.apiUrlSession = URLSession(configuration: apiConfig)
        
        let mediaConfig = URLSessionConfiguration.default
        mediaConfig.httpAdditionalHeaders = [
            "Authorization": "Bearer \(creds.accessToken)",
        ]
        mediaConfig.requestCachePolicy = .returnCacheDataElseLoad
        self.mediaUrlSession = URLSession(configuration: mediaConfig)
        
        guard let wk = creds.wellKnown
        else {
            let msg = "Homeserver info is required to instantiate a Matrix API"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        self.baseUrl = URL(string: wk.homeserver.baseUrl)!
    }
    
    func call(method: String, path: String, body: Codable? = nil, expectedStatuses: [Int] = [200]) async throws -> (Data, HTTPURLResponse) {
        let url = URL(string: path, relativeTo: baseUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let codableBody = body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(AnyCodable(codableBody))
        }
        
        let (data, response) = try await apiUrlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              expectedStatuses.contains(httpResponse.statusCode)
        else {
            throw Matrix.Error("Matrix API call rejected")
        }
        
        return (data, httpResponse)
    }
    
    // https://spec.matrix.org/v1.2/client-server-api/#put_matrixclientv3profileuseriddisplayname
    func setDisplayName(_ name: String) async throws {
        let (_, _) = try await call(method: "PUT",
                                              path: "/_matrix/client/\(version)/profile/\(creds.userId)/displayname",
                                              body: [
                                                "displayname": name,
                                              ])
    }
    
    func setAvatarImage(_ image: UIImage) async throws {
        // First upload the image
        let url = try await uploadImage(image, maxSize: CGSize(width: 256, height: 256))
        // Then set that as our avatar
        try await setAvatarUrl(url)
    }
    
    func setAvatarUrl(_ url: String) async throws {
        let (_,_) = try await call(method: "PUT",
                                   path: "_matrix/client/\(version)/profile/\(creds.userId)/avatar_url",
                                   body: [
                                     "avatar_url": url,
                                   ])
    }
    
    func uploadImage(_ original: UIImage, maxSize: CGSize, quality: CGFloat = 0.90) async throws -> String {
        guard let scaled = downscale_image(from: original, to: maxSize)
        else {
            let msg = "Failed to downscale image"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        let uri = try await uploadImage(scaled, quality: quality)
        return uri
    }
    
    func uploadImage(_ image: UIImage, quality: CGFloat = 0.90) async throws -> String {

        guard let jpeg = image.jpegData(compressionQuality: quality)
        else {
            let msg = "Failed to encode image as JPEG"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        return try await uploadData(data: jpeg, contentType: "image/jpeg")
    }
    
    func uploadData(data: Data, contentType: String) async throws -> String {
        
        let url = URL(string: "/_matrix/media/\(version)/upload", relativeTo: baseUrl)!
        var request = URLRequest(url: url)
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        let (responseData, response) = try await mediaUrlSession.upload(for: request, from: data)
        
        guard let httpResponse = response as? HTTPURLResponse,
              [200].contains(httpResponse.statusCode)
        else {
            let msg = "Upload request failed"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        struct UploadResponse: Codable {
            var contentUri: String
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let responseBody = try? decoder.decode(UploadResponse.self, from: responseData)
        else {
            let msg = "Failed to decode upload response"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        return responseBody.contentUri
    }
    
    // https://spec.matrix.org/v1.2/client-server-api/#post_matrixclientv3createroom
    func createRoom(name: String,
                    type: String? = nil,
                    encrypted: Bool = true,
                    invite userIds: [String] = [],
                    direct: Bool = false
    ) async throws -> String {
        
        struct CreateRoomRequestBody: Codable {
            var creation_content: [String: String] = [:]
            
            struct StateEvent: MatrixEvent {
                var content: Codable
                var stateKey: String
                var type: MatrixEventType
                
                enum CodingKeys: String, CodingKey {
                    case content
                    case stateKey = "state_key"
                    case type
                }
                
                init(type: MatrixEventType, stateKey: String = "", content: Codable) {
                    self.type = type
                    self.stateKey = stateKey
                    self.content = content
                }
                
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.stateKey = try container.decode(String.self, forKey: .stateKey)
                    self.type = try container.decode(MatrixEventType.self, forKey: .type)
                    //let minimal = try MinimalEvent(from: decoder)
                    //self.content = minimal.content
                    self.content = try Matrix.decodeEventContent(of: type, from: decoder)
                }
                
                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(stateKey, forKey: .stateKey)
                    try container.encode(type, forKey: .type)
                    try Matrix.encodeEventContent(content: content, of: type, to: encoder)
                }
            }
            var initial_state: [StateEvent] = []
            var invite: [String] = []
            var invite_3pid: [String] = []
            var is_direct: Bool = false
            var name: String
            enum Preset: String, Codable {
                case private_chat
                case public_chat
                case trusted_private_chat
            }
            var preset: Preset = .private_chat
            var room_alias_name: String?
            var room_version: Int = 7
            var topic: String?
            enum Visibility: String, Codable {
                case pub = "public"
                case priv = "private"
            }
            var visibility: Visibility = .priv
            
            init(name: String, type: String? = nil, encrypted: Bool) {
                self.name = name
                if encrypted {
                    let encryptionEvent = StateEvent(
                        type: MatrixEventType.mRoomEncryption,
                        stateKey: "",
                        content: RoomEncryptionContent()
                    )
                    self.initial_state = [encryptionEvent]
                }
                if let roomType = type {
                    self.creation_content = ["type": roomType]
                }
            }
        }
        let requestBody = CreateRoomRequestBody(name: name, type: type, encrypted: encrypted)
        
        let (data, response) = try await call(method: "POST",
                                    path: "/_matrix/client/\(version)/createRoom",
                                    body: requestBody)
        
        struct CreateRoomResponseBody: Codable {
            var roomId: String
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let responseBody = try? decoder.decode(CreateRoomResponseBody.self, from: data)
        else {
            let msg = "Failed to decode response from server"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        return responseBody.roomId
    }
    
    func createSpace(name: String) async throws -> String {
        let roomId = try await createRoom(name: name, type: "m.space", encrypted: false)
        return roomId
    }
    
    func sendStateEvent(to roomId: RoomId,
                        type: MatrixEventType,
                        content: Codable,
                        stateKey: String = ""
    ) async throws -> String {
        
        let (data, response) = try await call(method: "PUT",
                                              path: "/_matrix/client/\(version)/rooms/\(roomId)/state/\(type)/\(stateKey)",
                                              body: content)
        struct ResponseBody: Codable {
            var eventId: String
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let responseBody = try? decoder.decode(ResponseBody.self, from: data)
        else {
            let msg = "Failed to decode state event response"
            print(msg)
            throw Matrix.Error(msg)
        }
    
        return responseBody.eventId
    }

    func spaceAddChild(_ child: RoomId, to parent: RoomId) async throws {
        let servers = Array(Set([child.domain, parent.domain]))
        let order = (0x20 ... 0x7e).randomElement()?.description ?? "A"
        let content = SpaceChildContent(order: order, via: servers)
        let _ = try await sendStateEvent(to: parent, type: .mSpaceChild, content: content, stateKey: child.description)
    }
    
    func spaceAddParent(_ parent: RoomId, to child: RoomId, canonical: Bool = false) async throws {
        let servers = Array(Set([child.domain, parent.domain]))
        let content = SpaceParentContent(canonical: canonical, via: servers)
        let _ = try await sendStateEvent(to: child, type: .mSpaceParent, content: content, stateKey: parent.description)
    }
    
    func roomAddTag(roomId: RoomId, tag: String, order: Float? = nil) async throws {
        let path = "/_matrix/client/\(version)/user/\(creds.userId)/rooms/\(roomId)/tags/\(tag)"
        let body = ["order": order ?? Float.random(in: 0.0 ..< 1.0)]
        let _ = try await call(method: "PUT", path: path, body: body)
    }
    
    private func roomGetTagEventContent(roomId: RoomId) async throws -> RoomTagContent {
        let path = "/_matrix/client/\(version)/user/\(creds.userId)/rooms/\(roomId)/tags"
        let (data, response) = try await call(method: "GET", path: path, body: nil)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let tagContent = try? decoder.decode(RoomTagContent.self, from: data)
        else {
            let msg = "Failed to decode room tag content"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        return tagContent
    }
    
    func roomGetTags(roomId: RoomId) async throws -> [String] {
        let tagContent = try await roomGetTagEventContent(roomId: roomId)
        let tags: [String] = [String](tagContent.tags.keys)
        return tags
    }

    func roomSetAvatar(roomId: RoomId, image: UIImage) async throws {
        let maxSize = CGSize(width: 640, height: 640)
        
        guard let scaledImage = downscale_image(from: image, to: maxSize)
        else {
            let msg = "Failed to downscale image"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        guard let jpegData = scaledImage.jpegData(compressionQuality: 0.90)
        else {
            let msg = "Failed to compress image"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        guard let uri = try? await uploadData(data: jpegData, contentType: "image/jpeg") else {
            let msg = "Failed to upload image for room avatar"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        let info = mImageInfo(h: Int(scaledImage.size.height),
                              w: Int(scaledImage.size.width),
                              mimetype: "image/jpeg",
                              size: jpegData.count)
        
        let _ = try await sendStateEvent(to: roomId, type: .mRoomAvatar, content: RoomAvatarContent(url: uri, info: info))
    }
    
    func roomSetTopic(roomId: RoomId, topic: String) async throws {
        let _ = try await sendStateEvent(to: roomId, type: .mRoomTopic, content: ["topic": topic])
    }
    
    // https://spec.matrix.org/v1.2/client-server-api/#get_matrixclientv3roomsroomidmessages
    // Good news!  `from` is no longer required as of v1.3 (June 2022),
    // so we no longer have to call /sync before fetching messages.
    func roomGetMessages(roomId: RoomId,
                         forward: Bool = false,
                         from: String? = nil,
                         limit: Int? = 25
    ) async throws -> [ClientEvent] {
        let path = "/_matrix/client/\(version)/rooms/\(roomId)/messages"
        struct RequestBody: Codable {
            enum Direction: String, Codable {
                case forward = "f"
                case backward = "b"
            }
            var dir: Direction
            var filter: String?
            var from: String?
            var limit: Int?
            var to: String?
        }
        let body = RequestBody(dir: forward ? .forward : .backward, from: from, limit: limit)
        let (data, response) = try await call(method: "GET", path: path, body: body)
        
        struct ResponseBody: Codable {
            var chunk: [ClientEvent]
            var end: String?
            var start: String
            var state: [ClientEvent]?
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let responseBody = try decoder.decode(ResponseBody.self, from: data)
        
        return responseBody.chunk
        
    }
}
