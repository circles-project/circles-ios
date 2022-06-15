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
    
    func uploadImage(_ original: UIImage, quality: CGFloat = 0.90) async throws -> String {
        let url = URL(string: "/_matrix/media/\(version)/upload", relativeTo: baseUrl)!
        var request = URLRequest(url: url)
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        guard let jpeg = original.jpegData(compressionQuality: quality)
        else {
            let msg = "Failed to encode image as JPEG"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        let (data, response) = try await mediaUrlSession.upload(for: request, from: jpeg)
        
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
        guard let responseBody = try? decoder.decode(UploadResponse.self, from: data)
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
}
