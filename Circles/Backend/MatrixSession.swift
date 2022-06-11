//
//  MatrixSession.swift
//  Circles
//
//  Created by Charles Wright on 5/10/22.
//

import Foundation
import UIKit

#if false
public class MatrixSession: ObservableObject {
    
    let userId: String
    let deviceId: String
    var accessToken: String
    let homeserver: String
    let identityServer: String

    @Published var displayName: String?
    @Published var avatarUrl: URL?
    @Published var avatar: UIImage?
    @Published var statusMessage: String?
    
    @Published var device: MatrixDevice
    
    @Published var rooms: [MatrixRoom]
    @Published var invitations: [InvitedRoom]

    // Need some private stuff that outside callers can't see
    //private var syncTask: Task? // FIXME: Need to be more specific, apparently you can't just declare a plain `Task`
    private var userCache: [String: MatrixUser]
    private var roomCache: [String: MatrixRoom]
    private var deviceCache: [String: MatrixDevice]
    private var ignoreUserIds: Set<String>
    
    private var storagePath: String
    private var mediaUrlSession: URLSession // For downloading media
    private var apiUrlSession: URLSession   // For making API calls
    
    // We need to use the Matrix 'recovery' feature to back up crypto keys etc
    // This saves us from struggling with UISI errors and unverified devices
    private var recoverySecretKey: Data?
    private var recoveryTimestamp: Date?
    
    init(creds: MatrixCredentials) throws {
        self.userId = creds.userId
        self.deviceId = creds.deviceId
        self.accessToken = creds.accessToken
        
        self.rooms = []
        self.invitations = []
        
        // Look up the homeserver (and identity server)
        // using the well-known URL scheme
        let domain = getDomainFromUserId(userId)
        var wk = try await self.fetchWellKnown(for: domain)

        // Now connect to the homeserver
    }
    
    private func getDomainFromUserId(_ userId: String) -> String? {
        let toks = userId.split(separator: ":")
        if toks.count != 2 {
            return nil
        }

        let domain = String(toks[1])
        return domain
    }
    
    private func fetchWellKnown(for domain: String) async throws -> MatrixWellKnown {
        
        guard let url = URL(string: "https://\(domain)/.well-known/matrix/client") else {
            let msg = "Couldn't construct well-known URL"
            print("WELLKNOWN\t\(msg)")
            throw CirclesError(msg)
        }
        print("WELLKNOWN\tURL is \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            let msg = "Couldn't decode HTTP response"
            print("WELLKNOWN\t\(msg)")
            throw CirclesError(msg)
        }
        guard httpResponse.statusCode == 200 else {
            let msg = "HTTP request failed"
            print("WELLKNOWN\t\(msg)")
            throw CirclesError(msg)
        }
        
        let decoder = JSONDecoder()
        //decoder.keyDecodingStrategy = .convertFromSnakeCase
        let stuff = String(data: data, encoding: .utf8)!
        print("WELLKNOWN\tGot response data:\n\(stuff)")
        guard let wellKnown = try? decoder.decode(MatrixWellKnown.self, from: data) else {
            let msg = "Couldn't decode response data"
            print("WELLKNOWN\t\(msg)")
            throw CirclesError(msg)
        }
        print("WELLKNOWN\tSuccess!")
        return wellKnown
    }
}

/*
extension MatrixSession: AsyncMatrixInterface {


    
    
    func pause() async throws {
        // pause() doesn't actually make any API calls
        // It just tells our own local sync task to take a break
    }
    
    func close() async throws {
        // close() is like pause; it doesn't make any API calls
        // It just tells our local sync task to shut down
    }
    
    func createRecovery(privateKey: Data) async throws {
        <#code#>
    }
    
    func deleteRecovery() async throws {
        <#code#>
    }
    
    func whoAmI() async throws -> String {
        return self.userId
    }
    
    func me() async throws -> MatrixUser {
        return try await self.getUser(userId: self.userId)
    }
    
    func get3Pids() async throws -> [String] {
        <#code#>
    }
    
    func getUser(userId: String) async throws -> MatrixUser? {
        // First, check to see whether we have this user in our cache
        if let user = self.userCache[userId] {
            return user
        } else {
            // Apparently we don't have this one in our cache yet
            // Create a new MatrixUser, with us as the backing store / homeserver / thingy
        }
    }
    
    func refreshUser(userId: String) async throws -> MatrixUser? {
        <#code#>
    }
    
    func ignoreUser(userId: String) async throws {
        <#code#>
    }
    
    func unIgnoreUser(userId: String) async throws {
        <#code#>
    }
    
    func getDevices(userId: String) async throws -> [MatrixDevice] {
        <#code#>
    }
    
    func getCurrentDevice() async throws -> MatrixDevice? {
        <#code#>
    }
    
    func getRoom(roomId: String) async throws -> MatrixRoom? {
        <#code#>
    }
    
    func getRooms(for tag: String) async throws -> [MatrixRoom] {
        <#code#>
    }
    
    func getRooms(ownedBy user: MatrixUser) async throws -> [MatrixRoom] {
        <#code#>
    }
    
    func getAllRooms() async throws -> [MatrixRoom] {
        <#code#>
    }
    
    func getInvitedRooms() async throws -> [InvitedRoom] {
        <#code#>
    }
    
    func getSystemNoticesRoom() async throws -> MatrixRoom? {
        <#code#>
    }
    
    func createRoom(name: String, type: String, insecure: Bool) async throws -> MatrixRoom {
        <#code#>
    }
    
    func createRoom(name: String, type: String, tag: String, insecure: Bool) async throws -> MatrixRoom {
        <#code#>
    }
    
    func leaveRoom(roomId: String) async throws {
        <#code#>
    }
    
    func addTag(_ tag: String, toRoom roomId: String) async throws {
        <#code#>
    }
    
    func getRoomName(roomId: String) async throws -> String? {
        <#code#>
    }
    
    func getCachedImage(mxURI: String) -> UIImage? {
        <#code#>
    }
    
    func downloadImage(mxURI: String) async throws -> UIImage {
        <#code#>
    }
    
    func getCachedEncryptedImage(mxURI: String) -> UIImage? {
        <#code#>
    }
    
    func downloadEncryptedImage(fileinfo: mEncryptedFile, mimetype: String?) async throws -> UIImage {
        <#code#>
    }
    
    func uploadImage(image original: UIImage) async throws {
        <#code#>
    }
    
    func addReaction(reaction: String, for eventId: String, in roomId: String) async throws {
        <#code#>
    }
    
    func removeReaction(reaction: String, for eventId: String, in roomId: String) async throws {
        <#code#>
    }
    
    func getReactions(for eventId: String, in roomId: String) async throws -> [MatrixReaction] {
        <#code#>
    }
    
    func setAvatarImage(image: UIImage) async throws {
        <#code#>
    }
    
    func getAvatarUrl(userId: String) async throws -> URL {
        <#code#>
    }
    
    func getDisplayName(userId: String) async throws -> String? {
        <#code#>
    }
    
    func setDisplayName(name: String) async throws {
        <#code#>
    }
    
    func setStatusMessage(message: String) async throws {
        <#code#>
    }
    
    func setRoomAvatar(roomId: String, image: UIImage) async throws {
        <#code#>
    }
    
    func getRoomAvatarURL(roomId: String) async throws -> URL {
        <#code#>
    }
    
    func fetchRoomMemberList(roomId: String) async throws -> [String : String] {
        <#code#>
    }
    
    func canonicalizeUserId(userId: String) -> String? {
        <#code#>
    }
    
    func verifyDevice(deviceId: String, userId: String) async throws {
        <#code#>
    }
    
    func blockDevice(deviceId: String, userId: String) async throws {
        <#code#>
    }
    
    func deleteDevice(deviceId: String) async throws {
        <#code#>
    }
    
    func verifyUser(userId: String) async throws {
        <#code#>
    }
    
    func unverifyUser(userId: String) async throws {
        <#code#>
    }
    
    func getTrustLevel(userId: String) async throws -> String? {
        <#code#>
    }
    
    func getCryptoAlgorithm(roomId: String) async throws -> String {
        <#code#>
    }
    
    func ensureEncryption(roomId: String) async throws {
        <#code#>
    }
    
    func startNewSignupSession() async throws -> SignupSession {
        <#code#>
    }
    
    func setAccountData(_ data: [String : String], for: String) async throws {
        <#code#>
    }
    
    func sendToDeviceMessages(_ messages: [String: [String: MatrixEvent]])
}
*/
#endif
