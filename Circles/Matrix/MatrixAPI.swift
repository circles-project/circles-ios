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
    
    // MARK: Init
    
    init(creds: MatrixCredentials) throws {
        self.version = "r0"
        
        self.creds = creds
        
        let apiConfig = URLSessionConfiguration.default
        apiConfig.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(creds.accessToken)",
        ]
        apiConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        apiConfig.httpMaximumConnectionsPerHost = 4 // Default is 6 but we're getting some 429's from Synapse...
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
    
    // MARK: API Call
    
    func call(method: String, path: String, body: Codable? = nil, expectedStatuses: [Int] = [200]) async throws -> (Data, HTTPURLResponse) {
        print("APICALL\tCalling \(method) \(path)")
        let url = URL(string: path, relativeTo: baseUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let codableBody = body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let encodedBody = try encoder.encode(AnyCodable(codableBody))
            print("APICALL\tRaw request body = \n\(String(decoding: encodedBody, as: UTF8.self))")
            request.httpBody = encodedBody
        }
        
               
        var slowDown = true
        var delayNs: UInt64 = 1_000_000_000
        var count = 0
        
        repeat {
            let (data, response) = try await apiUrlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse
            else {
                let msg = "Couldn't handle HTTP response"
                print("APICALL\t\(msg)")
                throw Matrix.Error(msg)
            }
            
            if httpResponse.statusCode == 429 {
                slowDown = true

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                if let rateLimitError = try? decoder.decode(Matrix.RateLimitError.self, from: data),
                   let delayMs = rateLimitError.retryAfterMs {
                    delayNs = 1_000_000 * UInt64(delayMs)
                } else {
                    delayNs *= 2
                }
                
                print("APICALL\tGot 429 error...  Waiting \(delayNs) nanosecs and then retrying")
                try await Task.sleep(nanoseconds: delayNs)
                
                count += 1
            } else {
                slowDown = false
                guard expectedStatuses.contains(httpResponse.statusCode)
                else {
                    let msg = "Matrix API call rejected with status \(httpResponse.statusCode)"
                    print("APICALL\t\(msg)")
                    throw Matrix.Error(msg)
                }
                print("APICALL\tGot response with status \(httpResponse.statusCode)")
                
                return (data, httpResponse)
            }
            
        } while slowDown && count < 5
        
        throw Matrix.Error("API call failed")
    }
    
    // MARK: My User Profile
    
    // https://spec.matrix.org/v1.2/client-server-api/#put_matrixclientv3profileuseriddisplayname
    func setMyDisplayName(_ name: String) async throws {
        let (_, _) = try await call(method: "PUT",
                                              path: "/_matrix/client/\(version)/profile/\(creds.userId)/displayname",
                                              body: [
                                                "displayname": name,
                                              ])
    }
    
    func setMyAvatarImage(_ image: UIImage) async throws {
        // First upload the image
        let url = try await uploadImage(image, maxSize: CGSize(width: 256, height: 256))
        // Then set that as our avatar
        try await setMyAvatarUrl(url)
    }
    
    func setMyAvatarUrl(_ url: String) async throws {
        let (_,_) = try await call(method: "PUT",
                                   path: "_matrix/client/\(version)/profile/\(creds.userId)/avatar_url",
                                   body: [
                                     "avatar_url": url,
                                   ])
    }
    
    func setMyStatus(message: String) async throws {
        let body = [
            "presence": "online",
            "status_msg": message,
        ]
        try await call(method: "PUT", path: "/_matrix/client/\(version)/presence/\(creds.userId)/status", body: body)
    }
    
    // MARK: Other User Profiles
    
    func getDisplayName(userId: UserId) async throws -> String? {
        let path = "/_matrix/client/\(version)/profile/\(userId)/displayname"
        let (data, response) = try await call(method: "GET", path: path)
        
        struct ResponseBody: Codable {
            var displayname: String?
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        guard let responseBody = try? decoder.decode(ResponseBody.self, from: data)
        else {
            return nil
        }
        
        return responseBody.displayname
    }
    
    // https://spec.matrix.org/v1.2/client-server-api/#get_matrixclientv3profileuseridavatar_url
    func getAvatarUrl(userId: UserId) async throws -> String? {
        let path = "/_matrix/client/\(version)/profile/\(userId)/avatar_url"
        let (data, response) = try await call(method: "GET", path: path)
        
        struct ResponseBody: Codable {
            var avatarUrl: String?
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        guard let responseBody = try? decoder.decode(ResponseBody.self, from: data)
        else {
            return nil
        }
        
        return responseBody.avatarUrl
    }
    
    func getAvatarImage(userId: UserId) async throws -> UIImage? {
        
        
        // Download the bytes from the given uri
        guard let uri = try await getAvatarUrl(userId: userId)
        else {
            let msg = "Couldn't get mxc:// URI"
            print("USER\t\(msg)")
            throw Matrix.Error(msg)
        }
        guard let mxc = MXC(uri)
        else {
            let msg = "Invalid mxc:// URI"
            print("USER\t\(msg)")
            throw Matrix.Error(msg)
        }
        
        let data = try await downloadData(mxc: mxc)
        
        // Create a UIImage
        let image = UIImage(data: data)
        
        // return the UIImage
        return image
    }
    
    func getProfileInfo(userId: String) async throws -> (String?,String?) {
               
        let (data, response) = try await call(method: "GET", path: "/_matrix/client/\(version)/profile/\(userId)")
        
        struct UserProfileInfo: Codable {
            let displayName: String?
            let avatarUrl: String?
            
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let profileInfo: UserProfileInfo = try? decoder.decode(UserProfileInfo.self, from: data)
        else {
            let msg = "Failed to decode user profile"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        return (profileInfo.displayName, profileInfo.avatarUrl)
    }
    
    // MARK: Account Data
    
    // https://spec.matrix.org/v1.2/client-server-api/#get_matrixclientv3useruseridaccount_datatype
    func getAccountData<T>(for eventType: String, of dataType: T.Type) async throws -> T where T: Decodable {
        let path = "/_matrix/client/\(version)/user/\(creds.userId)/account_data/\(eventType)"
        let (data, response) = try await call(method: "GET", path: path)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let content = try decoder.decode(dataType, from: data)
        
        return content
    }
    
    // MARK: Devices
    
    func getDevices() async throws -> [MatrixMyDevice] {
        let path = "/_matrix/client/\(version)/devices"
        let (data, response) = try await call(method: "GET", path: path)
        
        struct DeviceInfo: Codable {
            var deviceId: String
            var displayName: String?
            var lastSeenIp: String?
            var lastSeenTs: Int?
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let infos = try? decoder.decode([DeviceInfo].self, from: data)
        else {
            let msg = "Couldn't decode device info"
            print("DEVICES\t\(msg)")
            throw Matrix.Error(msg)
        }
        
        let devices = infos.map {
            MatrixMyDevice(matrix: self, deviceId: $0.deviceId, displayName: $0.displayName, lastSeenIp: $0.lastSeenIp, lastSeenUnixMs: $0.lastSeenTs)
        }
        
        return devices
    }
    
    func getDevice(deviceId: String) async throws -> MatrixMyDevice {
        let path = "/_matrix/client/\(version)/devices/\(deviceId)"
        let (data, response) = try await call(method: "GET", path: path)
        
        struct DeviceInfo: Codable {
            var deviceId: String
            var displayName: String?
            var lastSeenIp: String?
            var lastSeenTs: Int?
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let info = try? decoder.decode(DeviceInfo.self, from: data)
        else {
            let msg = "Couldn't decode info for device \(deviceId)"
            print("DEVICES\t\(msg)")
            throw Matrix.Error(msg)
        }
        
        let device = MatrixMyDevice(matrix: self, deviceId: info.deviceId, displayName: info.displayName, lastSeenIp: info.lastSeenIp, lastSeenUnixMs: info.lastSeenTs)
        
        return device
    }
    
    func setDeviceDisplayName(deviceId: String, displayName: String) async throws {
        let path = "/_matrix/client/\(version)/devices/\(deviceId)"
        let (data, response) = try await call(method: "PUT",
                                              path: path,
                                              body: [
                                                "display_name": displayName
                                              ])
    }
    
    // https://spec.matrix.org/v1.3/client-server-api/#delete_matrixclientv3devicesdeviceid
    // FIXME This must support UIA.  Return a UIAASession???
    func deleteDevice(deviceId: String) async throws -> UIAuthSession? {
        let path = "/_matrix/client/\(version)/devices/\(deviceId)"
        let (data, response) = try await call(method: "DELETE",
                                              path: path,
                                              body: nil,
                                              expectedStatuses: [200,401])
        switch response.statusCode {
        case 200:
            // No need to do UIA.  Maybe we recently authenticated ourselves for another API call?
            // Anyway, we're happy.  Tell the caller that we're good to go; no more work to do.
            return nil
        case 401:
            // We need to auth
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            guard let uiaState = try? decoder.decode(UIAA.SessionState.self, from: data)
            else {
                let msg = "Could not decode UIA info"
                print("API\t\(msg)")
                throw Matrix.Error(msg)
            }
            let uiaSession = UIAuthSession("DELETE", URL(string: path, relativeTo: baseUrl)!, credentials: creds, requestDict: [:])
            uiaSession.state = .connected(uiaState)
            
            return uiaSession
        default:
            throw Matrix.Error("Got unexpected response")
        }
    }
    
    // MARK: Rooms
    
    // https://spec.matrix.org/v1.2/client-server-api/#get_matrixclientv3joined_rooms
    func getJoinedRoomIds() async throws -> [RoomId] {
        
        let (data, response) = try await call(method: "GET", path: "/_matrix/client/\(version)/joined_rooms")
        
        struct ResponseBody: Codable {
            var joinedRooms: [RoomId]
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let responseBody = try? decoder.decode(ResponseBody.self, from: data)
        else {
            let msg = "Failed to decode list of joined rooms"
            print("GETJOINEDROOMS\t\(msg)")
            throw Matrix.Error(msg)
        }
        
        return responseBody.joinedRooms
    }
    
    // https://spec.matrix.org/v1.2/client-server-api/#post_matrixclientv3createroom
    func createRoom(name: String,
                    type: String? = nil,
                    encrypted: Bool = true,
                    invite userIds: [UserId] = [],
                    direct: Bool = false
    ) async throws -> RoomId {
        print("CREATEROOM\tCreating room with name=[\(name)] and type=[\(type ?? "(none)")]")
        
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
            var initial_state: [StateEvent]?
            var invite: [String]?
            var invite_3pid: [String]?
            var is_direct: Bool = false
            var name: String?
            enum Preset: String, Codable {
                case private_chat
                case public_chat
                case trusted_private_chat
            }
            var preset: Preset = .private_chat
            var room_alias_name: String?
            var room_version: String = "7"
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
        
        print("CREATEROOM\tSending Matrix API request...")
        let (data, response) = try await call(method: "POST",
                                    path: "/_matrix/client/\(version)/createRoom",
                                    body: requestBody)
        print("CREATEROOM\tGot Matrix API response")
        
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
        
        return RoomId(responseBody.roomId)!
    }
    
    func sendStateEvent(to roomId: RoomId,
                        type: MatrixEventType,
                        content: Codable,
                        stateKey: String = ""
    ) async throws -> String {
        print("SENDSTATE\tSending state event of type [\(type.rawValue)] to room [\(roomId)]")
        
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
    
    // MARK: Room tags
    
    func addTag(roomId: RoomId, tag: String, order: Float? = nil) async throws {
        let path = "/_matrix/client/\(version)/user/\(creds.userId)/rooms/\(roomId)/tags/\(tag)"
        let body = ["order": order ?? Float.random(in: 0.0 ..< 1.0)]
        let _ = try await call(method: "PUT", path: path, body: body)
    }
    
    private func getTagEventContent(roomId: RoomId) async throws -> RoomTagContent {
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
    
    func getTags(roomId: RoomId) async throws -> [String] {
        let tagContent = try await getTagEventContent(roomId: roomId)
        let tags: [String] = [String](tagContent.tags.keys)
        return tags
    }
    
    // MARK: Room Metadata

    func setAvatarImage(roomId: RoomId, image: UIImage) async throws {
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
    
    func getAvatarImage(roomId: RoomId) async throws -> UIImage? {
        guard let content = try? await getRoomState(roomId: roomId, for: .mRoomAvatar, of: RoomAvatarContent.self)
        else {
            // No avatar for this room???
            return nil
        }
        
        guard let mxc = MXC(content.url)
        else {
            let msg = "Invalid avatar image URL"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        let data = try await downloadData(mxc: mxc)
        let image = UIImage(data: data)
        return image
    }
    
    func setTopic(roomId: RoomId, topic: String) async throws {
        let _ = try await sendStateEvent(to: roomId, type: .mRoomTopic, content: ["topic": topic])
    }
    
    func setDisplayName(roomId: RoomId, name: String) async throws {
        try await sendStateEvent(to: roomId, type: .mRoomName, content: RoomNameContent(name: name))
    }
    
    func getDisplayName(roomId: RoomId) async throws -> String {
        let content = try await getRoomState(roomId: roomId, for: .mRoomName, of: RoomNameContent.self)
        return content.name
    }
    
    // MARK: Room Messages
    
    // https://spec.matrix.org/v1.2/client-server-api/#get_matrixclientv3roomsroomidmessages
    // Good news!  `from` is no longer required as of v1.3 (June 2022),
    // so we no longer have to call /sync before fetching messages.
    func getMessages(roomId: RoomId,
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
    
    // https://spec.matrix.org/v1.2/client-server-api/#get_matrixclientv3roomsroomidjoined_members
    func getJoinedMembers(roomId: RoomId) async throws -> [UserId] {
        let path = "/_matrix/client/\(version)/rooms/\(roomId)/joined_members"
        let (data, response) = try await call(method: "GET", path: path)
        
        
        struct RoomMember: Codable {
            var avatarUrl: String
            var displayName: String
        }
        typealias ResponseBody = [UserId: RoomMember]
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let responseBody = try decoder.decode(ResponseBody.self, from: data)
        let users = [UserId](responseBody.keys)
        return users
    }
    
    // https://spec.matrix.org/v1.2/client-server-api/#get_matrixclientv3roomsroomidstate
    func getRoomState(roomId: RoomId) async throws -> [ClientEvent] {
        let path = "/_matrix/client/\(version)/rooms/\(roomId)/state"
        
        let (data, response) = try await call(method: "GET", path: path)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let events = try decoder.decode([ClientEvent].self, from: data)
        return events
    }
    
    func getRoomState<T>(roomId: RoomId, for eventType: MatrixEventType, of dataType: T.Type, with stateKey: String? = nil) async throws -> T where T: Decodable {
        let path = "/_matrix/client/\(version)/rooms/\(roomId)/state/\(eventType)/\(stateKey ?? "")"
        let (data, response) = try await call(method: "GET", path: path)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        guard let content = try? decoder.decode(dataType, from: data)
        else {
            let msg = "Couldn't decode room state for event type \(eventType)"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        return content
    }
    
    func inviteUser(roomId: RoomId, userId: UserId, reason: String? = nil) async throws {
        let path = "/_matrix/client/\(version)/rooms/\(roomId)/invite"
        let (data, response) = try await call(method: "POST",
                                              path: path,
                                              body: [
                                                "user_id": "\(userId)",
                                                "reason": reason
                                              ])
        // FIXME: Parse and handle any Matrix 400 or 403 errors
    }
    
    func kickUser(roomId: RoomId, userId: UserId, reason: String? = nil) async throws {
        let path = "/_matrix/client/\(version)/rooms/\(roomId)/kick"
        let (data, response) = try await call(method: "POST",
                                              path: path,
                                              body: [
                                                "user_id": "\(userId)",
                                                "reason": reason
                                              ])
    }
    
    func banUser(roomId: RoomId, userId: UserId, reason: String? = nil) async throws {
        let path = "/_matrix/client/\(version)/rooms/\(roomId)/ban"
        let (data, response) = try await call(method: "POST",
                                              path: path,
                                              body: [
                                                "user_id": "\(userId)",
                                                "reason": reason
                                              ])
    }
    
    func join(roomId: RoomId, reason: String? = nil) async throws {
        let path = "/_matrix/client/\(version)/rooms/\(roomId)/join"
        let (data, response) = try await call(method: "POST",
                                              path: path,
                                              body: [
                                                "reason": reason
                                              ])
    }
    
    func knock(roomId: RoomId, reason: String? = nil) async throws {
        let path = "/_matrix/client/\(version)/knock/\(roomId)"
        let (data, response) = try await call(method: "POST",
                                              path: path,
                                              body: [
                                                "reason": reason
                                              ])
    }
    
    func leave(roomId: RoomId, reason: String? = nil) async throws {
        let path = "/_matrix/client/\(version)/rooms/\(roomId)/leave"
        let (data, response) = try await call(method: "POST",
                                              path: path,
                                              body: [
                                                "reason": reason
                                              ])
    }
    
    func forget(roomId: RoomId) async throws {
        let path = "/_matrix/client/\(version)/rooms/\(roomId)/forget"
        let (data, response) = try await call(method: "POST", path: path)
    }
    
    func getRoomPowerLevels(roomId: RoomId) async throws -> [String: Int] {
        throw Matrix.Error("Not implemented")
    }
    
    // MARK: Spaces
    
    func createSpace(name: String) async throws -> RoomId {
        print("CREATESPACE\tCreating space with name [\(name)]")
        let roomId = try await createRoom(name: name, type: "m.space", encrypted: false)
        return roomId
    }
    
    func addSpaceChild(_ child: RoomId, to parent: RoomId) async throws {
        print("SPACES\tAdding [\(child)] as a child space of [\(parent)]")
        let servers = Array(Set([child.domain, parent.domain]))
        let order = (0x20 ... 0x7e).randomElement()?.description ?? "A"
        let content = SpaceChildContent(order: order, via: servers)
        let _ = try await sendStateEvent(to: parent, type: .mSpaceChild, content: content, stateKey: child.description)
    }
    
    func addSpaceParent(_ parent: RoomId, to child: RoomId, canonical: Bool = false) async throws {
        let servers = Array(Set([child.domain, parent.domain]))
        let content = SpaceParentContent(canonical: canonical, via: servers)
        let _ = try await sendStateEvent(to: child, type: .mSpaceParent, content: content, stateKey: parent.description)
    }
    
    func getSpaceChildren(_ roomId: RoomId) async throws -> [RoomId] {
        let allStateEvents = try await getRoomState(roomId: roomId)
        let spaceChildEvents = allStateEvents.filter {
            $0.type == .mSpaceChild
        }
        return spaceChildEvents.compactMap {
            guard let childRoomIdString = $0.stateKey,
                  let content = $0.content as? SpaceChildContent,
                  content.via != nil  // This check for `via` is the only way we have to know if this child relationship is still valid
            else {
                return nil
            }
            
            return RoomId(childRoomIdString)
        }
    }
    
    func removeSpaceChild(_ child: RoomId, from parent: RoomId) async throws {
        print("SPACES\tRemoving [\(child)] as a child space of [\(parent)]")
        let order = "\(0x7e)"
        let content = SpaceChildContent(order: order, via: nil)  // This stupid `via = nil` thing is the only way we have to remove a child relationship
        let _ = try await sendStateEvent(to: parent, type: .mSpaceChild, content: content, stateKey: child.description)
    }
    

    
    // MARK: Media API
    
    func downloadData(mxc: MXC) async throws -> Data {
        let path = "/_matrix/media/\(version)/download/\(mxc.serverName)/\(mxc.mediaId)"
        
        let url = URL(string: path, relativeTo: baseUrl)!
        let request = URLRequest(url: url)
        
        let (data, response) = try await mediaUrlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            let msg = "Failed to download media"
            print("DOWNLOAD\t\(msg)")
            throw Matrix.Error(msg)
        }
        
        return data
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
        request.httpMethod = "POST"
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
}
