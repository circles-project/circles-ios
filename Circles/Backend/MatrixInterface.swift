//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  MatrixInterface.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/28/20.
//

import Foundation
import UIKit
import MatrixSDK

protocol MatrixInterface {

    var sessionState: MXSessionState { get }
    
    func getStore() -> LegacyStore

    func getDomainFromUserId(_ userId: String) -> String?

    func generateSecretsFromSinglePassword(userId: String, password: String) -> MatrixSecrets?

    //func login(username: String, rawPassword: String, s4Password: String?, completion: @escaping (MXResponse<Void>) -> Void)
    
    //func logout()
    func pause()
    func close()
    func deleteMyAccount(password: String, completion: @escaping (MXResponse<Void>) -> Void)

    func changeMyPassword(oldPassword: String, newPassword: String, completion: @escaping (MXResponse<Void>) -> Void)
    
    //func finishSignupAndConnect()

    func createRecovery(privateKey: Data)
    func deleteRecovery(completion: @escaping(MXResponse<Void>) -> Void)
        
    func whoAmI() -> String
    
    func me() -> MatrixUser

    func get3Pids(completion: @escaping (MXResponse<[MXThirdPartyIdentifier]?>) -> Void)

    func getUser(userId: String) -> MatrixUser?
    
    func refreshUser(userId: String, completion: @escaping (MXResponse<MatrixUser>) -> Void)
    
    func ignoreUser(userId: String, completion: @escaping (MXResponse<Void>) -> Void)

    func unIgnoreUser(userId: String, completion: @escaping (MXResponse<Void>) -> Void)

    func getDevices(userId: String) -> [MatrixDevice]

    func getCurrentDevice() -> MatrixDevice?
    
    func getRoom(roomId: String) -> MatrixRoom?
    
    func getRooms(for tag: String) -> [MatrixRoom]
    
    func getRooms(ownedBy user: MatrixUser) -> [MatrixRoom]
    
    func getAllRooms() -> [MatrixRoom]
    
    func getInvitedRooms() -> [InvitedRoom]
    //var invitedRooms: [InvitedRoom] { get }
    
    func getSystemNoticesRoom() -> MatrixRoom?
    
    func createRoom(name: String, type:String, insecure: Bool, completion: @escaping (MXResponse<String>) -> Void)
    
    func createRoom(name: String, type: String, tag: String, insecure: Bool, completion: @escaping (MXResponse<String>) -> Void)
    
    func leaveRoom(roomId: String, completion: @escaping (Bool) -> Void)
    
    func addTag(_ tag: String, toRoom roomId: String, completion: @escaping (MXResponse<Void>) -> Void)

    func getRoomName(roomId: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func getCachedImage(mxURI: String) -> UIImage?
    
    func downloadImage(mxURI: String, completion: @escaping (_ image: UIImage) -> Void)
    
    func getCachedEncryptedImage(mxURI: String) -> UIImage?
    
    func downloadEncryptedImage(fileinfo: mEncryptedFile, mimetype: String?, completion: @escaping (MXResponse<UIImage>) -> Void)

    func uploadImage(image original: UIImage, completion: @escaping (MXProgress<URL>) -> Void)

    func addReaction(reaction: String, for eventId: String, in roomId: String, completion: @escaping (MXResponse<Void>) -> Void)

    func removeReaction(reaction: String, for eventId: String, in roomId: String, completion: @escaping (MXResponse<Void>) -> Void)

    func getReactions(for eventId: String, in roomId: String) -> [MatrixReaction]
    
    func setAvatarImage(image: UIImage, completion: @escaping (MXResponse<URL>) -> Void)

    func getAvatarUrl(userId: String, completion: @escaping (MXResponse<URL>) -> Void)
    
    func getDisplayName(userId: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func setDisplayName(name: String, completion: @escaping (MXResponse<Void>) -> Void)
    
    func setStatusMessage(message: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func setRoomAvatar(roomId: String, image: UIImage, completion: @escaping (MXResponse<Void>) -> Void)

    func getRoomAvatar(roomId: String, completion: @escaping (MXResponse<URL>) -> Void)

    func fetchRoomMemberList(roomId: String, completion: @escaping (MXResponse<[String:String]>) -> Void)
    
    func canonicalizeUserId(userId: String) -> String?
    
    func verifyDevice(deviceId: String, userId: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func blockDevice(deviceId: String, userId: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func deleteDevice(deviceId: String, password: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func verify(userId: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func unverify(userId: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func getTrustLevel(userId: String) -> MXUserTrustLevel
    
    func getCryptoAlgorithm(roomId: String) -> String
    
    func getOlmSessions(deviceKey: String) -> [MXOlmSession]
    
    func getInboundGroupSessions() -> [MXOlmInboundGroupSession]

    func getOutboundGroupSessions() -> [MXOlmOutboundGroupSession]

    func ensureEncryption(roomId: String, completion: @escaping (MXResponse<Void>) -> Void)
    
    func tryToDecrypt(message: MatrixMessage, completion: @escaping (MXResponse<Void>) -> Void)

    /*
    func startNewSignupSession(completion: @escaping (MXResponse<UIAA.SessionState>) -> Void)
    
    func signupGetRequiredTerms() -> mLoginTermsParams?
    
    func signupDoTermsStage(completion: @escaping (MXResponse<Void>)->Void)
    
    func signupGetSessionId() -> String?
    
    func signupDoTokenStage(token: String, tokenType: String, completion: @escaping (MXResponse<MXCredentials?>) -> Void)

    func signupDoAppStoreStage(receipt: String, completion: @escaping (MXResponse<MXCredentials?>) -> Void)
    
    func signupRequestEmailToken(email: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func signupValidateEmailAddress(sid: String, token: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func signupDoEmailStage(username: String, password: String, sid: String, completion: @escaping (MXResponse<MXCredentials?>)->Void)
    */

    func setRoomType(roomId: String, roomType: String, completion: @escaping (MXResponse<String>) -> Void)

    func setAccountData(_ data: [String:String], for: String, completion: @escaping (MXResponse<Void>) -> Void)
}
