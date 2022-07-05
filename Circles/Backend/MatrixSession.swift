//
//  MatrixSession.swift
//  Circles
//
//  Created by Charles Wright on 5/10/22.
//

import Foundation
import UIKit

class MatrixSession: MatrixAPI, ObservableObject {
    
    //private var store: SQLiteDataStore
    
    var legacy: LegacyStore

    @Published var displayName: String?
    @Published var avatarUrl: URL?
    @Published var avatar: UIImage?
    @Published var statusMessage: String?
    
    @Published var device: MatrixMyDevice
    
    @Published var rooms: [RoomId: MatrixRoom]
    @Published var invitations: [RoomId: InvitedRoom]
    @Published var users: [UserId: MatrixUser]

    // Need some private stuff that outside callers can't see
    private var syncTask: Task<String,Error>?  // FIXME: Make this use the  SyncResponseBody thing instead of String ???

    //private var deviceCache: [String: MatrixDevice]
    private var ignoreUserIds: Set<String>
    
    private var storagePath: String
    //private var mediaUrlSession: URLSession // For downloading media
    //private var apiUrlSession: URLSession   // For making API calls
    
    // We need to use the Matrix 'recovery' feature to back up crypto keys etc
    // This saves us from struggling with UISI errors and unverified devices
    private var recoverySecretKey: Data?
    private var recoveryTimestamp: Date?
    
    override init(creds: MatrixCredentials) throws {
        self.legacy = LegacyStore(creds: creds)
        
        self.device = MatrixMyDevice(deviceId: creds.deviceId)

        self.rooms = [:] // FIXME: Load rooms from the store
        self.users = [:]
        self.invitations = [:]
    
        //self.store = SQLiteDataStore(userId: creds.userId, deviceId: creds.deviceId)
        
        self.ignoreUserIds = []
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first!
        self.storagePath = "\(documentsPath)/\(creds.userId)"
        
        try super.init(creds: creds)
        
        /* // FIXME: Does this still make sense given that we're now building on MatrixAPI???
        // Look up the homeserver (and identity server)
        // using the well-known URL scheme
        guard let domain = Matrix.getDomainFromUserId(userId)
        else {
            let msg = "Invalid user id \(userId)"
            print("SESSION\t\(msg)")
            throw Matrix.Error(msg)
        }
        var wk = try await Matrix.fetchWellKnown(for: domain)

        // Now connect to the homeserver
         
        */
    }
    
    private func loadRoomsFromStore() throws {
        
    }


    // https://spec.matrix.org/v1.2/client-server-api/#get_matrixclientv3sync
    func sync() async throws {
        struct SyncRequestBody: Codable {
            var filter: String?
            var fullState: Bool?
            var setPresence: String?
            var since: String?
            var timeout: Int?
        }
        
        struct SyncResponseBody: Decodable {
            struct MinimalEventsContainer: Codable {
                var events: [MinimalEvent]?
            }
            struct AccountData: Decodable {
                // Here we can't use the MinimalEvent type that we already defined
                // Because Matrix is batshit and puts crazy stuff into these `type`s
                struct Event: Decodable {
                    var type: MatrixAccountDataType
                    var content: Decodable
                    
                    enum CodingKeys: String, CodingKey {
                        case type
                        case content
                    }
                    
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        
                        self.type = try container.decode(MatrixAccountDataType.self, forKey: .type)
                        self.content = try Matrix.decodeAccountData(of: self.type, from: decoder)
                    }
                }
                var events: [Event]?
            }
            typealias Presence =  MinimalEventsContainer
            typealias Ephemeral = MinimalEventsContainer
            
            struct Rooms: Decodable {
                var invite: [RoomId: InvitedRoomSyncInfo]?
                var join: [RoomId: JoinedRoomSyncInfo]?
                var knock: [RoomId: KnockedRoomSyncInfo]?
                var leave: [RoomId: LeftRoomSyncInfo]?
            }
            struct InvitedRoomSyncInfo: Codable {
                struct InviteState: Codable {
                    var events: [StrippedStateEvent]?
                }
                var inviteState: InviteState?
            }
            struct StateEventsContainer: Codable {
                var events: [ClientEventWithoutRoomId]?
            }
            struct Timeline: Codable {
                var events: [ClientEventWithoutRoomId]
                var limited: Bool?
                var prevBatch: String?
            }
            struct JoinedRoomSyncInfo: Decodable {
                struct RoomSummary: Codable {
                    var heroes: [UserId]?
                    var invitedMemberCount: Int?
                    var joinedMemberCount: Int?
                    
                    enum CodingKeys: String, CodingKey {
                        case heroes = "m.heroes"
                        case invitedMemberCount = "m.invited_member_count"
                        case joinedMemberCount = "m.joined_member_count"
                    }
                }
                struct UnreadNotificationCounts: Codable {
                    // FIXME: The spec gives the type for these as "Highlighted notification count" and "Total notification count" -- Hopefully it's a typo, and those should have been in the description column instead
                    var highlightCount: Int
                    var notificationCount: Int
                }
                var accountData: AccountData?
                var ephemeral: Ephemeral?
                var state: StateEventsContainer?
                var summary: RoomSummary?
                var timeline: Timeline?
                var unreadNotifications: UnreadNotificationCounts?
            }
            struct KnockedRoomSyncInfo: Codable {
                struct KnockState: Codable {
                    var events: [StrippedStateEvent]
                }
                var knockState: KnockState?
            }
            struct LeftRoomSyncInfo: Decodable {
                var accountData: AccountData?
                var state: StateEventsContainer?
                var timeline: Timeline?
            }
            struct ToDevice: Codable {
                var events: [ToDeviceEvent]
            }
            struct DeviceLists: Codable {
                var changed: [UserId]?
                var left: [UserId]?
            }
            typealias OneTimeKeysCount = [String : Int]
            
            var accountData: AccountData?
            var deviceLists: DeviceLists?
            var deviceOneTimeKeysCount: OneTimeKeysCount?
            var nextBatch: String
            var presence: Presence?
            var rooms: Rooms?
            var toDevice: ToDevice?
        }
        
        if let task = syncTask {
            let result = await task.result
            // FIXME: Handle errors here
            return
        } else {
            syncTask = .init(priority: .background) {
                let requestBody = SyncRequestBody(timeout: 0)
                let (data, response) = try await self.call(method: "GET", path: "/_matrix/client/v3/sync", body: requestBody)
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                guard let responseBody = try? decoder.decode(SyncResponseBody.self, from: data)
                else {
                    self.syncTask = nil
                    let msg = "Failed to decode /sync response"
                    print(msg)
                    throw Matrix.Error(msg)
                }
                
                // Process the sync response, updating local state
                
                // Handle invites
                if let invitedRoomsDict = responseBody.rooms?.invite {
                    for (roomId, info) in invitedRoomsDict {
                        guard let events = info.inviteState?.events
                        else {
                            continue
                        }
                        if self.invitations[roomId] == nil {
                            let room = try InvitedRoom(matrix: self, roomId: roomId, stateEvents: events)
                            self.invitations[roomId] = room
                        }
                    }
                }
                
                // Handle rooms where we're already joined
                if let joinedRoomsDict = responseBody.rooms?.join {
                    for (roomId, info) in joinedRoomsDict {
                        if let room = self.rooms[roomId] {
                            // Update the room with the latest data from `info`
                        } else {
                            // What the heck should we do here???
                            // Do we create the Room object, or not???
                        }
                    }
                }
                
                
                self.syncTask = nil
                
                return responseBody.nextBatch
            }
        }
    }
    
    func pause() async throws {
        // pause() doesn't actually make any API calls
        // It just tells our own local sync task to take a break
    }
    
    func close() async throws {
        // close() is like pause; it doesn't make any API calls
        // It just tells our local sync task to shut down
    }
    
    func createRecovery(privateKey: Data) async throws {
        throw Matrix.Error("Not implemented")
    }
    
    func deleteRecovery() async throws {
        throw Matrix.Error("Not implemented")
    }
    
    func whoAmI() -> UserId {
        creds.userId
    }
    
    func me() async throws -> MatrixUser {
        return try await self.getUser(userId: creds.userId)!
    }
    
    func get3Pids() async throws -> [String] {
        throw Matrix.Error("Not implemented")
    }
    
    func getUser(userId: UserId) async throws -> MatrixUser? {
        // First, check to see whether we have this user in our cache
        if let user = users[userId] {
            return user
        } else {
            // Apparently we don't have this one in our cache yet
            // Create a new MatrixUser, with us as the backing store / homeserver / thingy
            let user = legacy.getUser(userId: "\(userId)")
            await MainActor.run {
                users[userId] = user
            }
            //let user = MatrixUser(userId: userId, session: self)
            return user
        }
    }
    

    
    

    
    // https://spec.matrix.org/v1.2/client-server-api/#ignoring-users
    // Need to modify our account data by hitting /user/<user_id>/account_data/<type> where type = m.ignored_user_list
    // https://spec.matrix.org/v1.2/client-server-api/#put_matrixclientv3useruseridaccount_datatype
    func ignoreUser(userId: String) async throws {
        throw Matrix.Error("Not implemented")
        
        // First make sure that we have the current list
        
        // Add the user to it
        
        // Send the combined list to the server
        
        throw Matrix.Error("Not implemented")
    }
    
    // https://spec.matrix.org/v1.2/client-server-api/#ignoring-users
    func unIgnoreUser(userId: String) async throws {
        
        // First make sure we have the current list
        
        // Remove the user from the list
        
        // Send the reduced list to the server
        
        throw Matrix.Error("Not implemented")
    }
    
    func getDevices(userId: String) async throws -> [MatrixCryptoDevice] {
        // There is no /devices endpoint for users other than ourself
        // So we have to hit the /keys/query endpoint instead
        struct KeysQueryRequest: Codable {
            var deviceKeys: [String: [String]]
            var timeout: Int
            var token: String?
        }

        var body = KeysQueryRequest(deviceKeys: [userId: []], timeout: 10_000)
        let (data, response) = try await call(method: "POST", path: "/_matrix/client/\(version)/keys/query", body: body)
    
        struct KeysQueryResponse: Decodable {
            var deviceKeys: [String: [String: MatrixCryptoDevice]] // user_id -> device_id -> device_info
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let responseBody = try? decoder.decode(KeysQueryResponse.self, from: data)
        else {
            throw Matrix.Error("Couldn't decode response")
        }
        guard let devicesForMyUser = responseBody.deviceKeys[userId] else {
            return []
        }
        
        return Array(devicesForMyUser.values)
    }
    
    /* // This is just self.device
    func getCurrentDevice() async throws -> MatrixDevice? {
        
    }
    */
    
    // MARK: Rooms
    
    func getRoom(roomId: RoomId) async throws -> MatrixRoom? {
        if self.rooms[roomId] == nil {
            let room = legacy.getRoom(roomId: "\(roomId)")
            await MainActor.run {
                self.rooms[roomId] = room
            }
        }
        
        return self.rooms[roomId]
    }
    
    func getRooms(for tag: String) async throws -> [MatrixRoom] {
        // TODO: Tags are stored in the user's account data
        //       Therefore we need to implement account data first
        throw Matrix.Error("Not implemented")
    }
    
    func getRooms(ownedBy user: MatrixUser) async throws -> [MatrixRoom] {
        throw Matrix.Error("Not implemented")
    }
    
    // FIXME: What exactly are we trying to do here?
    // Maybe the point of this one is just to sync with the server
    // https://spec.matrix.org/v1.2/client-server-api/#get_matrixclientv3joined_rooms
    func reloadJoinedRooms() async throws {
        let roomIds = try await getJoinedRoomIds()
        var roomList = [(RoomId,MatrixRoom)]()
        
        for roomId in roomIds {
            if let room = try? await getRoom(roomId: roomId) {
                roomList.append( (roomId,room) )
            }
        }
        
        let newRooms = Dictionary(uniqueKeysWithValues: roomList)
        
        await MainActor.run {
            self.rooms = newRooms
        }
    }
    
    func getInvitedRooms() async throws -> [InvitedRoom] {
        throw Matrix.Error("Not implemented")
    }
    
    func getSystemNoticesRoom() async throws -> MatrixRoom? {
        throw Matrix.Error("Not implemented")
    }
    
    func createRoom(name: String, type: String, encrypted: Bool, invite: [UserId], direct: Bool) async throws -> MatrixRoom? {
        guard let roomId: RoomId = try? await createRoom(name: name, type: type, encrypted: encrypted, invite: invite, direct: direct)
        else {
            return nil
        }
        
        return try await getRoom(roomId: roomId)
    }
    
    func downloadEncryptedImage(fileinfo: mEncryptedFile, mimetype: String?) async throws -> UIImage {
        throw Matrix.Error("Not implemented")
    }
    
    
    func addReaction(reaction: String, for eventId: String, in roomId: String) async throws {
        throw Matrix.Error("Not implemented")
    }
    
    func removeReaction(reaction: String, for eventId: String, in roomId: String) async throws {
        throw Matrix.Error("Not implemented")
    }
    
    func getReactions(for eventId: String, in roomId: String) async throws -> [MatrixReaction] {
        throw Matrix.Error("Not implemented")
    }
    
    override func leave(roomId: RoomId, reason: String? = nil) async throws {
        try await super.leave(roomId: roomId, reason: reason)
        await MainActor.run {
            self.rooms[roomId] = nil
        }
    }
    
    func decline(roomId: RoomId, reason: String? = nil) async throws {
        try await super.leave(roomId: roomId, reason: reason)
        await MainActor.run {
            self.invitations[roomId] = nil
        }
    }
    
    
    func fetchRoomMemberList(roomId: String) async throws -> [String : String] {
        throw Matrix.Error("Not implemented")
    }
    
    
    func verifyDevice(deviceId: String, userId: String) async throws {
        throw Matrix.Error("Not implemented")
    }
    
    func blockDevice(deviceId: String, userId: String) async throws {
        throw Matrix.Error("Not implemented")
    }
    
    func deleteDevice(deviceId: String) async throws {
        throw Matrix.Error("Not implemented")
    }
    
    func verifyUser(userId: String) async throws {
        throw Matrix.Error("Not implemented")
    }
    
    func getTrustLevel(userId: String) async throws -> String? {
        throw Matrix.Error("Not implemented")
    }
    
    func getCryptoAlgorithm(roomId: String) async throws -> String {
        throw Matrix.Error("Not implemented")
    }
    
    func ensureEncryption(roomId: String) async throws {
        throw Matrix.Error("Not implemented")
    }
    
    func sendToDeviceMessages(_ messages: [String: [String: MatrixEvent]]) async throws {
        throw Matrix.Error("Not implemented")
    }
}
