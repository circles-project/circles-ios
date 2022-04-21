//
//  AsyncMatrixInterface.swift
//  Circles
//
//  Created by Charles Wright on 4/20/22.
//

import Foundation
import UIKit

protocol AsyncMatrixInterface {

    func getDomainFromUserId(_ userId: String) -> String?


    func login(username: String, password: String) async throws
    
    //func logout()
    func pause() async throws
    func close() async throws
    func deleteMyAccount(password: String) async throws

    func changeMyPassword(oldPassword: String, newPassword: String) async throws
    
    //func finishSignupAndConnect()

    func createRecovery(privateKey: Data) async throws
    func deleteRecovery() async throws
        
    func whoAmI() async throws -> String
    
    func me() -> MatrixUser

    func get3Pids() async throws -> [String] // FIXME: Return an array of 3pid type thingies that say whether they're email or sms or ...

    func getUser(userId: String) async throws -> MatrixUser?
    
    func refreshUser(userId: String) async throws -> MatrixUser?
    
    func ignoreUser(userId: String) async throws

    func unIgnoreUser(userId: String) async throws

    func getDevices(userId: String) async throws -> [MatrixDevice]

    func getCurrentDevice() async throws -> MatrixDevice?
    
    func getRoom(roomId: String) async throws -> MatrixRoom?
    
    func getRooms(for tag: String) async throws -> [MatrixRoom]
    
    func getRooms(ownedBy user: MatrixUser) async throws -> [MatrixRoom]
    
    func getAllRooms() async throws -> [MatrixRoom]
    
    func getInvitedRooms() async throws -> [InvitedRoom]
    //var invitedRooms: [InvitedRoom] { get }
    
    func getSystemNoticesRoom() async throws -> MatrixRoom?
    
    func createRoom(name: String, type:String, insecure: Bool) async throws -> MatrixRoom
    
    func createRoom(name: String, type: String, tag: String, insecure: Bool) async throws -> MatrixRoom
    
    func leaveRoom(roomId: String) async throws
    
    func addTag(_ tag: String, toRoom roomId: String) async throws

    func getRoomName(roomId: String) async throws -> String?
    
    func getCachedImage(mxURI: String) -> UIImage?
    
    func downloadImage(mxURI: String) async throws -> UIImage
    
    func getCachedEncryptedImage(mxURI: String) -> UIImage?
    
    func downloadEncryptedImage(fileinfo: mEncryptedFile, mimetype: String?) async throws -> UIImage

    func uploadImage(image original: UIImage) async throws // FIXME: How do we replicate the MXProgress thingy?

    func addReaction(reaction: String, for eventId: String, in roomId: String) async throws

    func removeReaction(reaction: String, for eventId: String, in roomId: String) async throws

    func getReactions(for eventId: String, in roomId: String) async throws -> [MatrixReaction]
    
    func setAvatarImage(image: UIImage) async throws

    func getAvatarUrl(userId: String) async throws -> URL
    
    func getDisplayName(userId: String) async throws -> String?
    
    func setDisplayName(name: String) async throws
    
    func setStatusMessage(message: String) async throws
    
    func setRoomAvatar(roomId: String, image: UIImage) async throws

    func getRoomAvatarURL(roomId: String) async throws -> URL

    func fetchRoomMemberList(roomId: String) async throws -> [String:String]
    
    func canonicalizeUserId(userId: String) -> String?
    
    func verifyDevice(deviceId: String, userId: String) async throws
    
    func blockDevice(deviceId: String, userId: String) async throws
    
    func deleteDevice(deviceId: String) async throws
    
    func verifyUser(userId: String) async throws
    
    func unverifyUser(userId: String) async throws
    
    func getTrustLevel(userId: String) async throws -> String?
    
    func getCryptoAlgorithm(roomId: String) async throws -> String
    
    /* // Not sure what to do about these..
       // The main MatrixSDK is hiding this stuff now, so we'll need to figure out our own data types
    func getOlmSessions(deviceKey: String) -> [MXOlmSession]
    
    func getInboundGroupSessions() -> [MXOlmInboundGroupSession]

    func getOutboundGroupSessions() -> [MXOlmOutboundGroupSession]
    */
     
    func ensureEncryption(roomId: String) async throws
    
    func startNewSignupSession() async throws -> SignupSession
    
    // We're switching to using m.room.type on the creation event,
    // now that Matrix made types official for Spaces.
    // As a consequence, types are now immutable.
    // func setRoomType(roomId: String, roomType: String, completion: @escaping (MXResponse<String>) -> Void)

    func setAccountData(_ data: [String:String], for: String) async throws
}
