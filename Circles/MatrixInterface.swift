//
//  MatrixAPI.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 10/28/20.
//

import Foundation
import UIKit
import MatrixSDK

protocol MatrixInterface {
    
    func login(username: String, password: String)
    
    func logout()
    
    func finishSignupAndConnect()
        
    func whoAmI() -> String
    
    func me() -> MatrixUser

    func getUser(userId: String) -> MatrixUser?
    
    func refreshUser(userId: String, completion: @escaping (MXResponse<MatrixUser>) -> Void)
    
    func ignoreUser(userId: String, completion: @escaping (MXResponse<Void>) -> Void)

    func unIgnoreUser(userId: String, completion: @escaping (MXResponse<Void>) -> Void)

    func getDevices(userId: String) -> [MatrixDevice]
    
    func getRoom(roomId: String) -> MatrixRoom?
    
    func getRooms(for tag: String) -> [MatrixRoom]
    
    func getRooms(ownedBy user: MatrixUser) -> [MatrixRoom]
    
    func getAllRooms() -> [MatrixRoom]
    
    func getInvitedRooms() -> [InvitedRoom]
    //var invitedRooms: [InvitedRoom] { get }
    
    func getSystemNoticesRoom() -> MatrixRoom?
    
    func createRoom(name: String, insecure: Bool, completion: @escaping (MXResponse<String>) -> Void)
    
    func createRoom(name: String, with tag: String, insecure: Bool, completion: @escaping (MXResponse<String>) -> Void)
    
    func leaveRoom(roomId: String, completion: @escaping (Bool) -> Void)
    
    func addTag(_ tag: String, toRoom roomId: String, completion: @escaping (MXResponse<Void>) -> Void)
    
    func getCachedImage(mxURI: String) -> UIImage?
    
    func downloadImage(mxURI: String, completion: @escaping (_ image: UIImage) -> Void)
    
    func getCachedEncryptedImage(mxURI: String) -> UIImage?
    
    func downloadEncryptedImage(fileinfo: mEncryptedFile, completion: @escaping (MXResponse<UIImage>) -> Void)

    func uploadImage(image original: UIImage, completion: @escaping (MXProgress<URL>) -> Void)
    
    func setAvatarImage(image: UIImage, completion: @escaping (MXResponse<URL>) -> Void)
    
    func getDisplayName(userId: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func setDisplayName(name: String, completion: @escaping (MXResponse<Void>) -> Void)
    
    func setStatusMessage(message: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func setRoomAvatar(roomId: String, image: UIImage, completion: @escaping (MXResponse<Void>) -> Void)
    
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
    
    func startNewSignupSession(completion: @escaping (MXResponse<UiaaSessionState>) -> Void)
    
    func signupGetRequiredTerms() -> mLoginTermsParams?
    
    func signupDoTermsStage(completion: @escaping (MXResponse<Void>)->Void)
    
    func signupGetSessionId() -> String?
    
    func signupDoTokenStage(token: String, completion: @escaping (MXResponse<MXCredentials?>) -> Void)
    
    func signupRequestEmailToken(email: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func signupValidateEmailAddress(sid: String, token: String, completion: @escaping (MXResponse<String>) -> Void)
    
    func signupDoEmailStage(username: String, password: String, sid: String, completion: @escaping (MXResponse<MXCredentials?>)->Void)
    
    func setAccountData(_ data: [String:String], for: String, completion: @escaping (MXResponse<Void>) -> Void)
}
