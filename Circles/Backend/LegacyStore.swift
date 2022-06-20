//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  KSStore.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/22/20.
//

// swiftlint:disable file_length

import Foundation
import Combine
import SwiftUI
import UIKit
import MatrixSDK
import OLMKit
import StoreKit
//import BCryptSwift // BCryptSwift is super freaking slow
//import BCrypt      // The version based on PerfectBCrypt worked great, until Xcode started refusing to compile it.  So I just imported its sources under Utilities/BCrypt, and it works.  :shrug:
import CryptoKit
import DictionaryCoding


struct MatrixSecrets {
    var loginPassword: String
    var secretKey: Data

    enum KeygenMethod: String {
        case fromSinglePassword
        case fromTwoPasswords
    }
    var keygenMethod: KeygenMethod
}

class LegacyStore: ObservableObject {
    // New approach (Oct 2020) -- Let the MXSession hold the one
    // authoritative copy of all of its state.  Why duplicate extra work?
    var session: MXSession
    var loginMxRc: MXRestClient?
    var sessionMxRc: MXRestClient?
    var signupMxRc: MXRestClient?

    
    var sessionStateSink: Cancellable? = nil
    var invitedRoomsSink: Cancellable? = nil
    var accountDataSink: Cancellable? = nil
    var newRoomsSink: Cancellable? = nil
    var identityServerSink: Cancellable? = nil

    // For deriving a new login password and SSSS key from a regular password
    var rootSecret: String?


    var homeserver: URL? {
        URL(string: self.session.matrixRestClient.homeserver)
    }

    var identityServer: URL? {
        URL(string: self.session.matrixRestClient.identityServer)
    }
    
    @Published var sessionState: MXSessionState

    // Model data for the Matrix layer
    var userId: String?
    var deviceId: String?
    var accessToken: String?
    var users: [String:MatrixUser] = [:]
    var rooms: [String:MatrixRoom] = [:]
    
    @Published var invitedRooms: [InvitedRoom] = []
    @Published var newestRooms: [MatrixRoom] = []
    
    // Model data for the social network layer
    @Published var circles: [SocialCircle] = []
    var groups: GroupsContainer? = nil
    var galleries: PhotoGalleriesContainer? = nil
    var people: PeopleContainer? = nil

    // We need to use the Matrix 'recovery' feature to back up crypto keys etc
    // This saves us from struggling with UISI errors and unverified devices
    private var recoverySecretKey: Data?
    private var recoveryTimestamp: Date?
        
    init(creds: MatrixCredentials) {
        // OK, let's see what we have to work with here.
        // If we have saved credentials, then we can go ahead and connect
        // to Matrix, and we'll be up and running.
        // If we don't have an access token (yet), then we're stuck
        // offline for now.

        // Set up some basic SDK options that we will need either way
        MXSDKOptions.sharedInstance().disableIdenticonUseForUserAvatar = true
        
        let logConf = MXLogConfiguration()
        logConf.logLevel = .debug
        MXLog.configure(logConf)

        self.loginMxRc = nil
        self.sessionMxRc = nil
        self.session = MXSession()
        self.sessionState = .closed

        // Set up our Combine listeners regardless of whether we're online or offline or whatever
        setupListeners()

        // OK so far so good.  Now do we have a recovery key?
        self.recoverySecretKey = UserDefaults.standard.data(forKey: "recoverySecretKey[\(creds.userId)]") ?? UserDefaults.standard.data(forKey: "privateKey[\(creds.userId)]")

        self.userId = creds.userId
        self.deviceId = creds.deviceId
        self.accessToken = creds.accessToken
        
        let mxCreds = MXCredentials(homeServer: creds.wellKnown!.homeserver.baseUrl, userId: creds.userId, accessToken: creds.accessToken)
        mxCreds.deviceId = creds.deviceId

        self.sessionMxRc = MXRestClient(credentials: mxCreds, unrecognizedCertificateHandler: nil)
        self.loginMxRc = self.sessionMxRc

        self.connect(restclient: self.sessionMxRc!) {
            print("STORE\tBack from connect()")
        }

        /*
        dgroup.notify(queue: .main) {
            print("STORE\tBack from looking up well known")
        }
        */

        print("STORE\tDone with init()")

    }

    /*
    private func _fetchWellKnown(for domain: String, completion: @escaping (MXResponse<MatrixWellKnown>) -> Void) {
        print("WELLKNOWN\tFetching well-known server info for domain [\(domain)]")
        guard let url = URL(string: "https://\(domain)/.well-known/matrix/client") else {
            let msg = "Couldn't construct well-known URL"
            print("WELLKNOWN\t\(msg)")
            completion(.failure(KSError(message: msg)))
            return
        }
        print("WELLKNOWN\tURL is \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("WELLKNOWN\tFailed to fetch well-known URL")
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                let msg = "Couldn't decode HTTP response"
                let err = KSError(message: msg)
                print("WELLKNOWN\t\(msg)")
                completion(.failure(err))
                return
            }
            guard httpResponse.statusCode == 200 else {
                let msg = "WELLKNOWN\tHTTP request failed"
                let err = KSError(message: msg)
                print("WELLKNOWN\t\(msg)")
                completion(.failure(err))
                return
            }
            let decoder = JSONDecoder()
            //decoder.keyDecodingStrategy = .convertFromSnakeCase
            let stuff = String(data: data!, encoding: .utf8)!
            print("WELLKNOWN\tGot response data:\n\(stuff)")
            guard let wellKnown = try? decoder.decode(MatrixWellKnown.self, from: data!) else {
                let msg = "Couldn't decode response data"
                let err = KSError(message: msg)
                print("WELLKNOWN\t\(msg)")
                completion(.failure(err))
                return
            }
            print("WELLKNOWN\tSuccess!")
            completion(.success(wellKnown))
        }
        task.resume()
    }
    */

    func setupListeners() {
        // Update 10/26/2020 -- HOWEVER, we need to be careful how we do this.
        // The MXSession comes from crufty old ObjC code.  For integration
        // with SwiftUI, we need to speak Combine, which is Swift only.
        // So we're going to need something of an adapter here.
        // We need to use NotificationCenter (or whatever) to subscribe to
        // updates from the MXSession's state.  Then we need to (re)publish
        // them into Combine as an ObservableObject so that SwiftUI can know
        // to update the Views when we have a change in the state.
        // For example, in MXSession.h, the MXSession will send a
        // kMXSessionStateDidChangeNotification when the session state changes.
        // Then we need to publish an ObjectWillChange (or whatever it's called)
        // so that SwiftUI can re-render the Views.
        //
        // Based on MXSession.m, it looks like the Session just posts its
        // events to the default NotificationCenter.  So all we need to do
        // is listen for them and provide the closure to handle them.
        // Hmmm... This may be easier than I thought.  Apple provides a function
        // that will give you a Combine Publisher for a given Notification name:
        // https://developer.apple.com/documentation/foundation/notificationcenter
        //
        // Subscribe to updates from the MXSession
        // NOTE: We can do this now, regardless of whether or not we have
        // an active MXSession yet.  For now, we just need to sign up with
        // NotificationCenter, and the MXSession will come along later to
        // actually post the events...
        self.sessionStateSink = NotificationCenter.default.publisher(for: NSNotification.Name.mxSessionStateDidChange)
            .sink(receiveCompletion: { _ in
                    print("SESSIONSTATESINK: Received completion")
                },
                receiveValue: { notification in
                    print("SESSIONSTATESINK: Got notification: \(notification)")
                    //self.objectWillChange.send()
                    let maybeMxSession: MXSession? = notification.object as? MXSession
                    if let mxs = maybeMxSession {
                        switch mxs.state {
                        case MXSessionState.running:
                            print("Session is now running")
                            if let key = self.recoverySecretKey {
                                self.connectRecovery(privateKey: key)
                            }
                        case MXSessionState.homeserverNotReachable:
                            print("Session can't reach the homeserver")
                        case MXSessionState.closed:
                            print("Session is closed")
                        case MXSessionState.syncError:
                            print("Session has a sync error")
                        case MXSessionState.syncInProgress:
                            print("Session is syncing")
                        default:
                            print("Session is... doing something else")
                        }
                        
                        // SwiftUI doesn't get the updates when we try using the .objectWillChange.send() above
                        // Let's see if keeping our own @Published copy of the state will do the trick...
                        self.sessionState = mxs.state
                    }
                }
            )
        
        // Subscribe to updates about the accout data,
        // since that is where we store our social graph.
        self.accountDataSink = NotificationCenter.default.publisher(for: NSNotification.Name.mxSessionAccountDataDidChange)
            .sink(receiveCompletion: { _ in
                    print("NEWROOM\tSink: Received completion")
                },
                receiveValue: { value in
                    print("NEWROOM\tSink: Got notification: \(value)")
                    //self.objectWillChange.send()
                }
            )
        
        // Subscribe to updates about invited rooms,
        // so we can display an accurate list on the HomeScreen
        self.invitedRoomsSink = NotificationCenter.default.publisher(for: NSNotification.Name.mxSessionInvitedRoomsDidChange)
            .sink(receiveCompletion: { _ in
                    print("NEWROOM\tSink: Received completion")
                },
                receiveValue: { notification in
                    print("NEWROOM\tSink: Got new invited room notification:") // \(notification)")
                    self.objectWillChange.send()
                    self.invitedRooms = self.getInvitedRooms()

                    if let userInfo = notification.userInfo {
                        if let roomId = userInfo["roomId"] as? String,
                           let event = userInfo["event"] as? MXEvent {
                            
                            self.handleNewRoom(roomId: roomId)
                            
                            print("NEWROOM\tChanged invited room is [\(roomId)], changed with event [\(String(describing: event.eventId))]")
                        }
                    }

                }
            )
        
        self.identityServerSink = NotificationCenter.default.publisher(for: NSNotification.Name.MXIdentityServiceTermsNotSigned)
            .sink(receiveCompletion: { _ in
                print("IDENTITY\tSink: Received completion")
            },
            receiveValue: { notification in
                print("IDENTITY\tSink: Received \"Terms not Signed\" notification")
                if let userInfo = notification.userInfo {
                    guard let isUserId = userInfo[MXIdentityServiceNotificationUserIdKey],
                          let isServer = userInfo[MXIdentityServiceNotificationIdentityServerKey],
                          let isAccessToken = userInfo[MXIdentityServiceNotificationAccessTokenKey] else {
                        print("IDENTITY\tError: Couldn't unpack user info data")
                        return
                    }
                    
                    print("IDENTITY\tGot userId = \(isUserId) server = \(isServer) token = \(isAccessToken)")
                }
            })
        
        // Presumably this one fires whenever we create/accept a new joined room
        // ~~on another device~~ -- Apparently on any device, including this one.
        self.newRoomsSink = NotificationCenter.default.publisher(for: NSNotification.Name.mxSessionNewRoom)
            .sink(receiveCompletion: { _ in
                    print("Sink: Received completion")
                },
                receiveValue: { notification in
                    print("Sink: Got new room notification: \(notification)")
                    self.objectWillChange.send()
                }
            )
        
    }
    
    func handleNewRoom(roomId: String) {
        print("NEWROOM\tHandling new room")
        guard let room = self.getRoom(roomId: roomId) else {
            print("NEWROOM\tCan't find the room..  Maybe we haven't joined yet?")
            return
        }

        room.getRoomType() { response in
            switch response {
            case .failure:
                let msg = "NEWROOM\tFailed to get room type for new room \(roomId)"
                print(msg)
            case .success(let roomType):
                if roomType == ROOM_TYPE_CIRCLE {
                    print("NEWROOM\tNew room is a Circle!")
                    self.newestRooms.append(room)
                }
            }
        }
    }
    





    func getDomainFromUserId(_ userId: String) -> String? {
        let toks = userId.split(separator: ":")
        if toks.count != 2 {
            return nil
        }

        let domain = String(toks[1])
        return domain
    }
    
}

extension LegacyStore: SocialGraph {

    func getPeopleContainer() -> PeopleContainer {
        if self.people == nil {
            self.people = PeopleContainer(self)
        }
        return self.people!
    }
    
    func getGroups() -> GroupsContainer {
        if self.groups == nil {
            self.groups = GroupsContainer(self)
        }
        return self.groups!
    }
    
    func getPhotoGalleries() -> PhotoGalleriesContainer {
        if self.galleries == nil {
            self.galleries = PhotoGalleriesContainer(self)
        }
        return self.galleries!
    }

    func loadCircles(completion: @escaping (MXResponse<[SocialCircle]>) -> Void) {
        print("CIRCLES\tLoading circles from account data...")
        if let data = session.accountData?.accountData(forEventType: EVENT_TYPE_CIRCLES) as? [String : String] {
            print("CIRCLES\tFound circle data in our account data")
            var newCircles = Set<SocialCircle>()
            for (id, name) in data {
                print("CIRCLES\tFound a circle with id = \(id) name = \(name)")
                let circle = SocialCircle(circleId: id, name: name, graph: self)
                newCircles.insert(circle)
            }
            self.circles = newCircles.sorted(by: {$0.tag < $1.tag})
            completion(.success(self.circles))
        } else {
            let msg = "Couldn't get account data for circles"
            let err = KSError(message: msg)
            completion(.failure(err))
        }

    }

    /*
    func getCircles() -> [SocialCircle] {
        print("CIRCLES\tGetting all circles")
        return circles.sorted(by: {$0.tag < $1.tag})
    }
    */
    
    func saveCircles(completion: @escaping (MXResponse<String>) -> Void) {
        print("Saving circles")
        var data: [String:String] = [:]
        for circle in circles {
            if circle.tag != CIRCLE_TAG_FOLLOWING {
                print("\tFound circle with id = \(circle.id) and name = \(circle.name)")
                data[circle.id] = circle.name
            }
        }
        session
            .setAccountData(data,
                           forType: EVENT_TYPE_CIRCLES,
                           success: {
                            let msg = "Saved circles to Matrix"
                            print(msg)
                            completion(.success(msg))
                           },
                           failure: { err in
                            let msg = "Error! Failed to save circles: \(err)"
                            print(msg)
                            completion(.failure(err!))
                           })
    }
    
    func createCircle(name: String, rooms: [MatrixRoom],
                      completion: @escaping (MXResponse<SocialCircle>) -> Void)
    {
        let circle = SocialCircle(circleId: SocialCircle.randomId(), name: name, graph: self)

        print("CREATECIRCLE Creating Circle [\(name)] with id=\(circle.id)")
        // Using the simple concurrency pattern from
        // https://www.swiftbysundell.com/articles/task-based-concurrency-in-swift/
        let dgroup = DispatchGroup()
        var error: KSError? = nil
        
        print("CREATECIRCLE Tagging rooms with Circle id \(circle.id)")
        for room in rooms {
            dgroup.enter()
            room.addTag(tag: circle.tag) { response in
                if response.isFailure {
                    let msg = "Failed to set tag [\(circle.tag)]"
                    error = error ?? KSError(message: msg)
                    print(msg)
                } else {
                    print("CREATECIRCLE Tagged room \(room.displayName ?? room.id) as \(circle.tag) for Circle \(name)")
                }
                dgroup.leave()
            }
            
            dgroup.enter()
            room.addTag(tag: ROOM_TAG_FOLLOWING) { response in
                if response.isFailure {
                    let msg = "Failed to set tag [\(ROOM_TAG_FOLLOWING)]"
                    error = error ?? KSError(message: msg)
                } else {
                    print("CREATECIRCLE Tagged room \(room.displayName ?? room.id) as \(ROOM_TAG_FOLLOWING) for Circle \(name)")
                }
                dgroup.leave()
            }
        }
        
        // Also create our outbound room, and tag it appropriately so we can find it later
        print("CREATECIRCLE Creating new outbound Room for [\(circle.name)]")
        dgroup.enter()
        self.createRoom(name: name, type: ROOM_TYPE_CIRCLE, tag: circle.tag) { response in
            switch(response) {
            case .failure(let err):
                let msg = "CREATECIRCLE Failed to create outbound room for circle \(name): \(error)"
                print(msg)
                error = error ?? KSError(message: msg)
                dgroup.leave()
            case .success(let roomId):
                print("CREATECIRCLE Created room \(roomId) for circle \(name)")
                
                // FIXME This crap belongs in the MatrixRoom class
                if let room = self.getRoom(roomId: roomId)  {
            
                    dgroup.enter()
                    room.setRoomType(type: ROOM_TYPE_CIRCLE) { response in
                        if response.isFailure {
                            let msg = "Failed to set room type"
                            print(msg)
                            error = error ?? KSError(message: msg)
                        }
                        dgroup.leave()
                    }
                } else {
                    let msg = "Failed to get MatrixRoom"
                    error = error ?? KSError(message: msg)
                }
                
                dgroup.enter()
                if let outbound = self.getRoom(roomId: roomId) {
                    outbound.addTag(tag: ROOM_TAG_OUTBOUND) { response in
                        switch(response) {
                        case .failure(let err):
                            let msg = "CREATECIRCLE Failed to set tag [\(ROOM_TAG_OUTBOUND)]"
                            print(msg)
                            error = error ?? KSError(message: msg)
                        case .success:
                            print("CREATECIRCLE Successfully tagged room \(roomId ?? "???") as \(ROOM_TAG_OUTBOUND) for circle [\(name)]")
                        }
                        dgroup.leave()
                    }
                } else {
                    print("CREATECIRCLE\tFailed to tag outbound room for new circle [\(circle.id)]")
                    error = error ?? KSError(message: "Couldn't find new outbound room")
                    dgroup.leave()
                }
                
                dgroup.leave()
            }
            
        }
        
        dgroup.notify(queue: .main) {
            if let error = error {
                print("CREATECIRCLE Failed to create circle \(name)")
                completion(.failure(error))
            } else {
                print("CREATECIRCLE Created circle \(name)")
                self.circles.append(circle)
                //self.saveCircles()
                self.objectWillChange.send()
                completion(.success(circle))
            }
        }
    }
    
    func removeCircle(circle: SocialCircle) {
        if circles.contains(circle) {
            //self.objectWillChange.send()
            circles.removeAll(where: {$0 == circle})
            //let tag = "social.kombucha.stream." + circle.id
            let tag = circle.tag
            for room in circle.stream.rooms {
                room.removeTag(tag: tag) { _ in }
            }
            self.saveCircles() { _ in
                self.objectWillChange.send()
            }
        }
    }
    
    func follow(room: InvitedRoom, in circle: SocialCircle) {
        room.join(tags: [ROOM_TAG_FOLLOWING, circle.tag]) { response in
            if response.isSuccess {
                circle.stream.addRoom(roomId: room.id) { _ in }
            }
        }
    }
    
    func unfollow(room: MatrixRoom, in circle: SocialCircle?) {
        if circle == nil {
            matrix.leaveRoom(roomId: room.id) { _ in }
        }
        else {
            circle!.unfollow(room: room) { _ in }
        }
    }
    
    func getAllFollowedRooms() -> [MatrixRoom] {
        self.getRooms(for: ROOM_TAG_FOLLOWING)
    }

    
    var matrix: MatrixInterface {
        return self as MatrixInterface
    }
}


extension LegacyStore: MatrixInterface {
    
    func changeMyPassword(oldPassword: String, newPassword: String, completion: @escaping (MXResponse<Void>) -> Void) {
        guard let restClient = self.session.matrixRestClient else {
            let msg = "Failed to get Matrix rest client"
            let err = KSError(message: msg)
            print("STORE\t\(msg)")
            completion(.failure(err))
            return
        }

        // OK now we need to figure out whether we can use the raw passwords,
        // or if we have to do our bcrypt hashing thing on them first.

        let userId = self.whoAmI()

        let keygenMethod: String? = UserDefaults.standard.string(forKey: "keygen_method[\(userId)]")

        if keygenMethod == MatrixSecrets.KeygenMethod.fromTwoPasswords.rawValue {
            // Easy version.  Just use the raw passwords.
            restClient.changePassword(from: oldPassword, to: newPassword, logoutDevices: false, completion: completion)
        } else {
            // If we're here, then we need to hash the passwords before we can use them
            guard let oldSecrets = self.generateSecretsFromSinglePassword(userId: userId, password: oldPassword),
                  let newSecrets = self.generateSecretsFromSinglePassword(userId: userId, password: newPassword)
            else {
                let msg = "Failed to generate secrets from password(s)"
                print("CHANGEPASSWORD\t\(msg)")
                let err = KSError(message: msg)
                completion(.failure(err))
                return
            }
            restClient.changePassword(from: oldSecrets.loginPassword, to: newSecrets.loginPassword, logoutDevices: false, completion: completion)
        }
    }

    func get3Pids(completion: @escaping (MXResponse<[MXThirdPartyIdentifier]?>) -> Void) {
        guard let restClient = self.session.matrixRestClient else {
            let msg = "Failed to get Matrix rest client"
            let err = KSError(message: msg)
            print("STORE\t\(msg)")
            completion(.failure(err))
            return
        }

        restClient.thirdPartyIdentifiers(completion)
    }

    func getAvatarUrl(userId: String, completion: @escaping (MXResponse<URL>) -> Void) {
        guard let restClient = self.session.matrixRestClient else {
            let msg = "Failed to get Matrix rest client"
            let err = KSError(message: msg)
            print("STORE\t\(msg)")
            completion(.failure(err))
            return
        }
        restClient.avatarUrl(forUser: userId, completion: completion)
    }

    func getRoomAvatar(roomId: String, completion: @escaping (MXResponse<URL>) -> Void) {
        guard let restClient = self.session.matrixRestClient else {
            let msg = "Failed to get Matrix rest client"
            let err = KSError(message: msg)
            print("STORE\t\(msg)")
            completion(.failure(err))
            return
        }
        restClient.avatar(ofRoom: roomId, completion: completion)
    }


    func getRoomName(roomId: String, completion: @escaping (MXResponse<String>) -> Void) {
        guard let restClient = self.session.matrixRestClient else {
            let msg = "Failed to get Matrix rest client"
            let err = KSError(message: msg)
            print("STORE\t\(msg)")
            completion(.failure(err))
            return
        }
        restClient.name(ofRoom: roomId, completion: completion)
    }


    func fetchRoomMemberList(roomId: String, completion: @escaping (MXResponse<[String:String]>) -> Void) {
        guard let restClient = self.session.matrixRestClient else {
            let msg = "Failed to get Matrix rest client"
            let err = KSError(message: msg)
            print("MATRIXMEMBERS\t\(msg)")
            completion(.failure(err))
            return
        }

        //let params = [kMXMembersOfRoomParametersMembership: "join"]
        let params = [String:Any]()
        restClient.members(ofRoom: roomId,
                           withParameters: params,
                           success: { result in

                                guard let events = result as? [MXEvent] else {
                                    print("MATRIXMEMBERS\tRest client gave us garbage")
                                    return
                                }

                                print("MATRIXMEMBERS\tGot \(events.count) state events from Matrix")

                                var membership = [String:String]()
                                for event in events {
                                    guard let userId = event.stateKey,
                                          let userState = event.content["membership"] as? String else {
                                        print("MATRIXMEMBERS\tGot an event without valid membership info")
                                        continue
                                    }
                                    membership[userId] = userState
                                }
                                completion(.success(membership))
                            },
                           failure: { error in
                                let msg = "Failed to get room members from the homeserver"
                                print("MATRIXMEMBERS\t\(msg)")
                                let err = KSError(message: msg)
                                completion(.failure(err))
                           }
        )
    }

    func getStore() -> LegacyStore {
        self
    }

    func addReaction(reaction: String, for eventId: String, in roomId: String, completion: @escaping (MXResponse<Void>) -> Void) {

        guard let agg = self.session.aggregations else {
            let msg = "Failed to get Matrix aggregations manager"
            print("REACTIONS\tError: \(msg)")
            let err = KSError(message: msg)
            completion(.failure(err))
            return
        }

        agg.addReaction(reaction, forEvent: eventId, inRoom: roomId,
                        success: { completion(.success(()))},
                        failure: {err in completion(.failure(err))})
    }

    func removeReaction(reaction: String, for eventId: String, in roomId: String, completion: @escaping (MXResponse<Void>) -> Void) {

        guard let agg = self.session.aggregations else {
            let msg = "Failed to get Matrix aggregations manager"
            print("REACTIONS\tError: \(msg)")
            let err = KSError(message: msg)
            completion(.failure(err))
            return
        }

        agg.removeReaction(reaction, forEvent: eventId, inRoom: roomId,
                           success: { completion(.success(()))},
                           failure: {err in completion(.failure(err))})
    }

    func getReactions(for eventId: String, in roomId: String) -> [MatrixReaction] {
        guard let agg = self.session.aggregations else {
            let msg = "Failed to get Matrix aggregations manager"
            print("REACTIONS\tError: \(msg)")
            //let err = KSError(message: msg)
            //completion(.failure(err))
            return []
        }

        var reactions = [MatrixReaction]()
        guard let aggregated = agg.aggregatedReactions(onEvent: eventId, inRoom: roomId) else {
            // No aggregated reactions for this event
            // Ok, no problem, just return the empty array that we already have
            return reactions
        }
        for mxReactionCount in aggregated.reactions {
            let emoji = mxReactionCount.reaction
            let count = mxReactionCount.count
            reactions.append(MatrixReaction(emoji: emoji, count: count))
        }
        return reactions
    }

    /*
    func generateSecrets(userId: String, rawPassword: String, s4Password: String? = nil, completion: @escaping (MXResponse<MatrixSecrets>)->Void) {
        guard let password2 = s4Password else {
            generateSecretsFromSinglePassword(userId: userId, password: rawPassword, completion: completion)
            return
        }
        generateSecretsFromTwoPasswords(userId: userId, loginPassword: rawPassword, s4Password: password2, completion: completion)
    }
    */

    func generateSecretsFromTwoPasswords(userId: String, loginPassword: String, s4Password: String, completion: @escaping (MXResponse<MatrixSecrets>)->Void) {

        guard let crypto = self.session.crypto,
              let recovery = crypto.recoveryService else {
            let msg = "Failed to find Matrix recovery service"
            print("SECRETS\t\(msg)")
            let err = KSError(message: msg)
            completion(.failure(err))
            return
        }

        recovery.privateKey(fromPassphrase: s4Password,
                            success: { privateKey in
                                print("SECRETS\tGenerated private key")
                                let secrets = MatrixSecrets(loginPassword: loginPassword, secretKey: privateKey, keygenMethod: .fromTwoPasswords)
                                completion(.success(secrets))
                            }, failure: { err in
                                print("SECRETS\tKey generation failed")
                                completion(.failure(err))
                            })
    }

    func generateSecretsFromSinglePassword(userId: String, password: String) -> MatrixSecrets? {
        // Update 2021-06-16 - Adding my crazy scheme for doing
        //                     SSSS using only a single password
        //
        // First we bcrypt the password to get a secret that is
        // resistant to brute force and dictionary attack.
        // Then we use the symmetric ratchet to generate two keys
        // * One for the login password
        // * One for the secret "private key" for the recovery service

        guard let userPart = userId.split(separator: ":").first else {
            return nil
        }
        var username = userPart
        if username.starts(with: "@") {
            username = username.dropFirst()
        }
        print("SECRETS\tExtracted username [\(username)] from given userId [\(userId)]")

        guard let data = username.data(using: .utf8) else {
            let msg = "Failed to convert username to data"
            print("SECRETS\t\(msg)")
            return nil
        }

        let saltDigest = SHA256.hash(data: data)
        let saltString = saltDigest
            .map { String(format: "%02hhx", $0) }
            .prefix(16)
            .joined()
        print("SECRETS\tComputed salt string = [\(saltString)]")

        let numRounds = 14
        guard let bcrypt = try? BCrypt.Hash(password, salt: "$2a$\(numRounds)$\(saltString)") else {
            let msg = "BCrypt KDF failed"
            print("SECRETS\t\(msg)")
            return nil
        }
        print("SECRETS\tGot bcrypt hash = [\(bcrypt)]")
        print("       \t                   12345678901234567890123456789012345678901234567890")

        // Grabbing everything after the $ gives us the salt as well as the hash
        //let root = String(bcrypt.suffix(from: bcrypt.lastIndex(of: "$")!).dropFirst(1))
        // Grabbing only the last 31 chars gives us just the hash
        let root = String(bcrypt.suffix(31))
        self.rootSecret = root
        print("SECRETS\tRoot secret = [\(root)]  (\(root.count) chars)")

        let newLoginPassword = SHA256.hash(data: "LoginPassword|\(root)".data(using: .utf8)!)
            .prefix(16)
            .map { String(format: "%02hhx", $0) }
            .joined()
        print("SECRETS\tGot new login password = [\(newLoginPassword)]")

        let newPrivateKey = SHA256.hash(data: "S4Key|\(root)".data(using: .utf8)!)
            .withUnsafeBytes {
                Data(Array($0))
            }
        print("SECRETS\tGot new private key = [\(newPrivateKey)]")

        return MatrixSecrets(loginPassword: newLoginPassword,
                             secretKey: newPrivateKey,
                             keygenMethod: .fromSinglePassword
        )
    }
    
    /*
    func login(username: String, rawPassword: String, s4Password: String? = nil, completion: @escaping (MXResponse<Void>) -> Void) {
        print("in login()")

        // Check: Are we already logged in?
        switch(self.session.state) {
        case MXSessionState.closed:
            
            // We need the user's domain in order to look up the homeserver from the .well-known URL
            guard let userDomain = getDomainFromUserId(username) ?? kombuchaDomain
            else {
                let msg = "Failed to determine domain for username [\(username)]"
                print("LOGIN\t\(msg)")
                let err = KSError(message: msg)
                completion(.failure(err))
                return
            }

            _fetchWellKnown(for: userDomain) { wellKnownResponse in
                guard case let .success(wellKnownInfo) = wellKnownResponse,
                      let hsURL = URL(string: wellKnownInfo.homeserver.base_url)
                else {
                    let msg = "Failed to look up well-known homeserver info for domain \(userDomain)"
                    print("LOGIN\t\(msg))")
                    let err = KSError(message: msg)
                    completion(.failure(err))
                    return
                }

                self.loginMxRc = MXRestClient(homeServer: hsURL,
                                              unrecognizedCertificateHandler: nil)

                // FIXME Only do this if we're using a single password
                //       for both login and SSSS
                // Actually - We should still use the "secrets" struct
                // If we have two passwords, we should just generate it differently
                //   - .loginPassword is just the "raw" password from the user
                //   - .secretKey is generated from the special SSSS password
                let keygenMethod: MatrixSecrets.KeygenMethod = s4Password == nil ? .fromSinglePassword : .fromTwoPasswords
                var secrets: MatrixSecrets?

                if keygenMethod == .fromSinglePassword {
                    secrets = self.generateSecretsFromSinglePassword(userId: username, password: rawPassword)
                    if secrets == nil {
                        let msg = "Failed to generate secrets from username and password(s)"
                        print(msg)
                        completion(.failure(KSError(message: msg)))
                        return
                    }
                }

                var params: [String:Any] = [:]
                params["type"] = "m.login.password"
                params["identifier"] = ["type" : "m.id.user"]
                params["user"] = username
                params["password"] = secrets?.loginPassword ?? rawPassword // Use the bcrypt password if we generated one; Otherwise fall back to using the raw password
                if let saved_device_id = UserDefaults.standard.string(forKey: "device_id[\(username)]") {
                    params["device_id"] = saved_device_id
                    print("LOGIN\tUsing existing deviceId [\(saved_device_id)]")
                } else {
                    print("LOGIN\tNo saved deviceId")
                }
                params["initial_device_display_name"] = "Circles (\(UIDevice.current.model))"

                self.loginMxRc!.login(parameters: params) { response in
                    print("LOGIN\tGot login response")
                    switch(response) {
                    case .failure(let err):
                        print("LOGIN\tFailed: \(err)")
                        completion(.failure(err))
                    case .success(let creds):
                        print("LOGIN\tLogged in")
                        // Validate the credentials that we received
                        guard let user_id = creds["user_id"] as? String,
                              let access_token = creds["access_token"] as? String,
                              let device_id = creds["device_id"] as? String
                        else {
                            let msg = "LOGIN\tLogged in but some creds are bogus"
                            print(msg)
                            let error = KSError(message: msg)
                            completion(.failure(error))
                            return
                        }

                        // Print credentials for debugging
                        print("LOGIN\tGot user id = \(user_id)")
                        print("LOGIN\tGot device id = \(device_id)")
                        print("LOGIN\tGot access token = \(access_token)")

                        var newCreds = MXCredentials()
                        newCreds.userId = user_id
                        newCreds.accessToken = access_token
                        newCreds.deviceId = device_id
                        newCreds.homeServer = hsURL.absoluteString

                        // Save credentials in case the app is closed and re-started
                        let defaults = UserDefaults.standard
                        defaults.set(user_id, forKey: "user_id")
                        defaults.set(device_id, forKey: "device_id[\(user_id)]")
                        defaults.set(access_token, forKey: "access_token[\(user_id)]")
                        // Also remember how we handle the user's raw password
                        //   - eg Do we need to hash it before we use it for UIAA?
                        defaults.set(keygenMethod.rawValue, forKey: "keygen_method[\(user_id)]")

                        // Also save a copy of the device_id for the plain username.
                        // This way, we'll be able to retrieve it next time even if the user doesn't
                        // type in their full Matrix user ID

                        if user_id != username {
                            defaults.set(device_id, forKey: "device_id[\(username)]")
                        }
                        print("Saved credentials to UserDefaults")

                        // Connect to the Matrix backend and go live
                        self.sessionMxRc = MXRestClient(credentials: newCreds, unrecognizedCertificateHandler: nil)
                        self.connect(restclient: self.sessionMxRc!) {
                            // Now we can run anything that needs the running session and/or the crypto interface AND the password

                            self.setupCrossSigning(password: secrets?.loginPassword ?? rawPassword)


                            if let singlePasswordSecrets = secrets {
                                UserDefaults.standard.set(singlePasswordSecrets.secretKey, forKey: "privateKey[\(user_id)]")
                                UserDefaults.standard.set(singlePasswordSecrets.secretKey, forKey: "recoverySecretKey[\(user_id)]")
                                self.recoverySecretKey = singlePasswordSecrets.secretKey
                                self.setupRecovery(secrets: singlePasswordSecrets)
                            } else {
                                self.generateSecretsFromTwoPasswords(userId: user_id, loginPassword: rawPassword, s4Password: s4Password!) { secretsResponse in

                                    switch secretsResponse {
                                    case .failure(let err):
                                        print("LOGIN\tFailed to generate secrets")
                                    case .success(let twoPasswordSecrets):
                                        UserDefaults.standard.set(twoPasswordSecrets.secretKey, forKey: "privateKey[\(user_id)]")
                                        UserDefaults.standard.set(twoPasswordSecrets.secretKey, forKey: "recoverySecretKey[\(user_id)]")
                                        self.recoverySecretKey = twoPasswordSecrets.secretKey
                                        self.setupRecovery(secrets: twoPasswordSecrets)
                                    }
                                }
                            }

                            completion(.success(()))

                        }
                    }
                }
            }

        default:
            let msg = "In the wrong state... Not actually loggin in..."
            print(msg)
            let error = KSError(message: msg)
            completion(.failure(error))
            // Do nothing, we're already logged in
            // FIXME What if we're logged in **as somebody else**?
            break
        }
        print("Leaving login()")
    }
    */
    
    func setupRecovery(key: Data) {
        guard let crypto = self.session.crypto,
              let recovery = crypto.recoveryService else {
            print("RECOVERY\tCouldn't get recoveryService")
            return
        }
        print("RECOVERY\tSetting up")

        if !recovery.hasRecovery() {
            print("RECOVERY\tDidn't find an existing recovery.  Creating one now...")
            createRecovery(privateKey: key)
        } else {
            // We have a recovery already existing
            print("RECOVERY\tWe have an existing recovery")
 
            print("RECOVERY\tConnecting with our current secret key")
            self.connectRecovery(privateKey: key)
        }
    }

    /*
    func setupRecovery(secrets: MatrixSecrets) {
        guard let crypto = self.session.crypto,
              let recovery = crypto.recoveryService else {
            print("RECOVERY\tCouldn't get recoveryService")
            return
        }
        let userId = self.whoAmI()
        print("RECOVERY\tSetting up for user [\(userId)]")

        if !recovery.hasRecovery() {
            print("RECOVERY\tDidn't find an existing recovery.  Creating one now...")
            createRecovery(privateKey: secrets.secretKey)
        } else {
            // We have a recovery already existing
            print("RECOVERY\tWe have an existing recovery")
            // Do we have the key already saved on this device?
            if let savedKey = UserDefaults.standard.data(forKey: "privateKey[\(userId)]") {
                // Ok, we had already saved this key
                // So let's use it
                print("RECOVERY\tConnecting with the saved key")
                self.connectRecovery(privateKey: savedKey)
            } else {
                print("RECOVERY\tConnecting with our current secret key")
                self.connectRecovery(privateKey: secrets.secretKey)
            }
        }
    }
    */

    
    func createRecovery(privateKey: Data) {

        //let userId = self.whoAmI()

        guard let crypto = self.session.crypto,
              let recovery = crypto.recoveryService else {
            print("RECOVERY\tCouldn't get recoveryService")
            return
        }

        func handleCreateSuccess(info: MXSecretStorageKeyCreationInfo) {
            /*
            let defaults = UserDefaults.standard

            defaults.set(info.recoveryKey, forKey: "recoveryKey[\(userId)]")
            defaults.set(info.privateKey, forKey: "privateKey[\(userId)]")
            */
            print("RECOVERY\tSetup success")
        }

        func handleCreateFailure(error: Error) {
            print("RECOVERY\tSetup failed")
        }

        recovery
            .createRecovery(
                forSecrets: nil,
                withPrivateKey: privateKey,
                createServicesBackups: true,
                success: handleCreateSuccess,
                failure: handleCreateFailure
            )
    }

    func deleteRecovery(completion: @escaping(MXResponse<Void>) -> Void) {
        guard let crypto = self.session.crypto,
              let recovery = crypto.recoveryService else {
            print("RECOVERY\tCouldn't get recoveryService")
            completion(.failure(KSError(message: "Failed to delete recovery")))
            return
        }

        recovery.deleteRecovery(withDeleteServicesBackups: true,
                                success: {
                                    let stillThere = recovery.hasRecovery()
                                    print("RECOVERY\tDelete was successful.  But is the recovery still there?  Answer: \(stillThere)")
                                    completion(.success(()))
                                },
                                failure: { err in
                                    completion(.failure(err))
                                })
    }

    func connectRecovery(privateKey: Data) {
        guard let crypto = self.session.crypto,
              let recovery = crypto.recoveryService else {
            print("RECOVERY\tCouldn't get recoveryService")
            return
        }

        let now = Date()
        if let timestamp = self.recoveryTimestamp {
            // Check to make sure we didn't *just* do this
            if timestamp.distance(to: now) < RECOVERY_MIN_INTERVAL {
                print("RECOVERY\tAborting connectRecovery() because we're still within the minimum interval")
                return
            }
        }
        self.recoveryTimestamp = now

        func handleSuccess(result: MXSecretRecoveryResult) {
            print("RECOVERY\tSuccess - connected to recovery")
            // Now we should probably update the recovery with any local secrets
            recovery.updateRecovery(
                forSecrets: nil,
                withPrivateKey: privateKey,
                success: {
                    print("RECOVERY\tSuccess updating recovery")
                },
                failure: {_ in
                    print("RECOVERY\tFailed to update recovery")
                })
        }

        func handleError(error: Error) {
            print("RECOVERY\tFailed to connect to existing recovery")
            // Hmm OK we failed to connect to the existing one.
            // Why don't we just create a new one?
            // Answer: Because Matrix won't let us.
        }

        recovery.checkPrivateKey(privateKey) { match in
            if match {
                print("RECOVERY\tPrivate keys match.  Recovering secrets...")
                recovery.recoverSecrets(nil,
                                        withPrivateKey: privateKey,
                                        recoverServices: true,
                                        success: handleSuccess,
                                        failure: handleError)
            } else {
                print("RECOVERY\tError: Private keys don't match!")
            }
        }


    }
       
    func setupCrossSigning(password: String) {
        print("XSIGN Setting up")
        guard let crypto = self.session.crypto else {
            print("XSIGN Error: No crypto")
            return
        }
        
        guard let mxcross = crypto.crossSigning else {
            print("MXSIGN Error: No cross signing")
            return
        }
        
        switch(mxcross.state) {
        case .notBootstrapped:
            print("XSIGN Not bootstrapped")
            
            mxcross.setup(withPassword: password,
                          success: {
                            print("XSIGN Bootstrap successful")
                            self.objectWillChange.send()
                          },
                          failure: { err in
                            print("XSIGN Bootstrap failed \(err)")
                          })
            
        case .crossSigningExists:
            print("XSIGN Exists")
        case .trustCrossSigning:
            print("XSIGN Trusting")
        case .canCrossSign:
            print("XSIGN Can cross sign")
        default:
            print("XSIGN I don't know WTF is going on")
        }
    }
    
    func connect(restclient: MXRestClient, completion: @escaping () -> Void) {
        print("Connecting a logged-in Matrix session")
        guard let session = MXSession(matrixRestClient: restclient) else {
            print("Failed to connect via Matrix rest client")
            return
        }
        self.session = session
        
        //self.session.setIdentityServer(identityServer.absoluteString, andAccessToken: nil)
        
        let store = MXFileStore(credentials: restclient.credentials)
        self.session.setStore(store) { store_response in
            self.objectWillChange.send()
            switch(store_response) {
            case .failure(let error):
                print("Failed to set up MXStore: \(error)")
                return
            case .success:
                print("Set up MXStore")
                
                self.session.enableCrypto(true) { crypto_response in
                    if crypto_response.isSuccess {
                        print("Set up Crypto")
                        
                        guard let crypto = self.session.crypto else {
                            return
                        }
                        // FIXME While we're debugging, don't worry about device verification
                        crypto.warnOnUnknowDevices = false
                        // Trying to fix UISI errors by resetting the cached list of keys
                        crypto.resetDeviceKeys()
                        
                        // Start listening for updates from the Matrix backend
                        self.session.start() { start_response in
                            switch(start_response) {
                            case .failure(let error):
                                print("CONNECT\tFailed to start MXSession: \(error)")
                                return
                            case .success:
                                self.objectWillChange.send()

                                print("CONNECT\tSuccessfully started MXSession")
                                self.invitedRooms = self.getInvitedRooms()
                                
                                // 2022-05-05 We're having lots of encryption errors lately.  Might as well try getting private keys from our other devices.
                                crypto.requestAllPrivateKeys()
                                

                                // We're trying to be more careful about enumerating our circles now
                                // So we have to initialize the local copy at some point
                                self.loadCircles() { _ in }

                            }
                        }
                    }
                    else {
                        print("Failed to set up crypto :(")
                    }
                }
            }
        }
    }

    /*
    func finishSignupAndConnect() {
        if let restClient = self.signupMxRc {
            self.connect(restclient: restClient) {
                self.signupMxRc = nil
            }
        }
    }
    */


    func deactivateAccount(password: String, completion: @escaping (MXResponse<Void>) -> Void) {
        pause()
        let params = ["password": password]
        self.session.deactivateAccount(withAuthParameters: params, eraseAccount: true) { response in
            completion(response)
        }
    }
    
    //func logout() {
    func pause() {
        // Wipe the access token so we're not still logged in
        // if we close & reopen the app
        if let uid = self.session.myUserId {
            let defaults = UserDefaults.standard
            defaults.set("", forKey: "access_token[\(uid)]")
        }
        self.objectWillChange.send()
        self.session.pause()
    }

    func close() {

        // Don't really log out, or the server will delete our device_id
        // and then other clients won't be able to provide decryption keys
        // for this device.
        let userId = self.session.myUserId
        //self.objectWillChange.send()
        
        // FIXME Instead of calling any kind of logout(),
        //       really we should be doing self.sesion.close() here.
        //       The problem is that, for some reason, with close()
        //       instead of logout(), SwiftUI is too slow to switch
        //       back to the LoggedOutScreen.  So we crash because
        //       we're on a logged in screen, and suddenly we have
        //       no me() or whoAmI() anymore. :-(
        //       This REALLY motivates re-working the way we handle
        //       state management in this app.  As if we needed even
        //       more motivation.  Sigh.  But this one is going to be
        //       the straw that breaks the camel's back.
        //self.session.logout() { response in
        //self.session.matrixRestClient.logout() { response in

        self.session.close()
        /*
            switch(response) {
            case .failure(let err):
                print("Error: Logout failed", err)
            case .success:
        */
                // OK great, we're out.
                //self.objectWillChange.send()
                // Wipe the old (now invalid) access token.
                if let uid = userId {
                    let defaults = UserDefaults.standard
                    defaults.set("", forKey: "access_token[\(uid)]")
                }
                
                // Also blow away all of our internal state
                // Model data for the Matrix layer
                self.users = [:]
                self.rooms = [:]
                self.invitedRooms = []
                
                // Model data for the social network layer
                self.circles = []
                // ViewModel "Containers" for the various screens
                self.groups = nil
                self.galleries = nil
                self.people = nil
                
                // Connection(s) to the homeserver
                self.signupMxRc = nil
                self.sessionMxRc = nil
                self.loginMxRc = nil
        //self.session.close()
                print("Logout was successful")
        /*
            }
        }
        */
    }

    func deleteMyAccount(password: String, completion: @escaping (MXResponse<Void>) -> Void) {

        // Does the user use one password for everything?
        //   * If so, we should bcrypt() the raw password before sending it
        // Or are they on an old Matrix account with two different passwords?
        //   * If so, we should just send the raw password.
        //     We don't care what the second password is right now.

        let keygenMethod: String? = UserDefaults.standard.string(forKey: "keygen_method[\(self.whoAmI())]")

        var params: [String:String] = [:]
        params["username"] = self.whoAmI()

        if keygenMethod == MatrixSecrets.KeygenMethod.fromSinglePassword.rawValue {
            params["password"] = password
        } else {
            guard let secrets = self.generateSecretsFromSinglePassword(userId: self.whoAmI(), password: password) else {
                let msg = "Failed to generate secrets from username/password"
                print(msg)
                completion(.failure(KSError(message: msg)))
                return
            }
            params["password"] = secrets.loginPassword
        }


        self.session.pause()

        self.session.deactivateAccount(withAuthParameters: params, eraseAccount: true, completion: completion)
    }
    
    func whoAmI() -> String {
        self.session.myUserId
    }
    
    func me() -> MatrixUser {
        self.getUser(userId: self.session.myUserId)!
    }
    
    func getUser(userId: String) -> MatrixUser? {
        if let user = self.users[userId] {
            return user
        }
        else {
            guard let mxuser = self.session.user(withUserId: userId) else {
                return nil
            }
            
            let user = MatrixUser(from: mxuser, on: self)
        
            self.users[userId] = user
            
            // We're having some issues where displaynames and avatars are getting lost.
            // For some reason, this especially seems to happen to the logged in user.
            // So, let's try manually fetching them each time when we first see a user (including me() / session.myUser)
            refreshUser(userId: userId) { response in
                if response.isSuccess {
                    user.objectWillChange.send()
                }
            }
            
            return self.users[userId]
        }
    }
    
    func refreshUser(userId: String, completion: @escaping (MXResponse<MatrixUser>) -> Void) {
        
        guard let mxuser = self.session.getOrCreateUser(userId),
              let user = self.getUser(userId: userId) else {
            let msg = "Couldn't get user \(userId)"
            print("Error: \(msg)")
            completion(.failure(KSError(message: msg)))
            return
        }
        
        mxuser.update(fromHomeserverOfMatrixSession: self.session,
                      success: {
                        print("STORE\tGot updated user details for [\(userId)]")
                        completion(.success(user))
                      },
                      failure: { error in
                        // Well, crud.  Not much we can do about it though.
                        let msg = "Failed to get user details from homeserver"
                        print("STORE\t\(msg)")
                        completion(.failure(error ?? KSError(message: msg)))
                      })
    }
    
    func ignoreUser(userId: String, completion: @escaping (MXResponse<Void>) -> Void) {
        self.session.ignore(users: [userId], completion: completion)
    }
    
    func unIgnoreUser(userId: String, completion: @escaping (MXResponse<Void>) -> Void) {
        self.session.unIgnore(users: [userId], completion: completion)
    }
    
    func getDevices(userId: String) -> [MatrixDevice] {
        guard let crypto = session.crypto else {
            return []
        }
        guard let mxdevices = crypto.devices(forUser: userId) else {
            return []
        }
        return mxdevices.values.compactMap { deviceInfo in
            MatrixDevice(from: deviceInfo, on: self)
        }
    }

    func getCurrentDevice() -> MatrixDevice? {
        let allMyDevices = self.getDevices(userId: self.whoAmI())
        return allMyDevices.first(where: {$0.id == self.session.myDeviceId})
    }
    
    func getRoom(roomId: String) -> MatrixRoom? {
        if let room = self.rooms[roomId] {
            return room
        }
        else {
            guard let mxroom = self.session.room(withRoomId: roomId) else {
                return nil
            }
            
            self.rooms[roomId] = MatrixRoom(from: mxroom, on: self)
            return self.rooms[roomId]
        }
    }
    
    func getRooms(for tag: String) -> [MatrixRoom] {
        print("GETROOMS\tGetting rooms for tag \(tag)")
        guard let mxrooms = self.session.rooms(withTag: tag) else {
            print("GETROOMS\t\tNo rooms for tag \(tag)")
            return []
        }
        return mxrooms.compactMap { mxroom in
            print("GETROOMS\t\tFound room \(mxroom.roomId ?? "???") for tag \(tag)")
            return self.getRoom(roomId: mxroom.roomId)
        }
    }
    
    func getRooms(ownedBy user: MatrixUser) -> [MatrixRoom] {
        self.session.rooms
                .compactMap({self.getRoom(roomId: $0.roomId)})
                .filter({$0.owners.contains(user)})
    }
    
    func getAllRooms() -> [MatrixRoom] {
        let mxrooms = self.session.rooms
        return mxrooms.compactMap { mxroom in
            self.getRoom(roomId: mxroom.roomId)
        }
    }
    
    func getInvitedRooms() -> [InvitedRoom] {
        print("INVITED\tGetting invited rooms...")
        guard let mxrooms: [MXRoom] = self.session.invitedRooms() else {
            print("INVITED\tMatrix has no invited rooms.  Returning empty array.")
            return []
        }
        print("INVITED\tMatrix has \(mxrooms.count) invited mxrooms")
        let rooms: [InvitedRoom] = Set(mxrooms)
            /*
            .filter { mxroom in
                guard let roomType = mxroom.summary.roomTypeString else {
                    print("INVITED\tInvited MXRoom \(String(describing: mxroom.roomId)) has no room type.  Skipping...")
                    return false
                }
                let validRoomTypes = [ROOM_TYPE_CIRCLE, ROOM_TYPE_GROUP, ROOM_TYPE_PHOTOS]
                return validRoomTypes.contains(roomType)
            }
            */
            .compactMap { mxroom in
                //self.getRoom(roomId: mxroom.roomId)
                print("INVITED\tFound invited room [\(mxroom.roomId ?? "")]")
                return InvitedRoom(from: mxroom, on: self)
            }
        print("INVITED\tReturning \(rooms.count) invited rooms")
        return rooms
    }
    
    func getSystemNoticesRoom() -> MatrixRoom? {
        
        if let room = self.getRooms(for: "m.server_notice").first {
            return room
        }

        guard let userDomain = getDomainFromUserId(whoAmI()) else {
            return nil
        }
        let systemNoticesUserId = "@notices:\(userDomain)"
        print("NOTICES\tNotices userId = \(systemNoticesUserId)")
        
        guard let mxroom = self.session.directJoinedRoom(withUserId: systemNoticesUserId) else {
            print("NOTICES\tNo system notices room")
            return nil
        }
        
        print("NOTICES\tRoom is \(mxroom.roomId)")
        return self.getRoom(roomId: mxroom.roomId) 
    }
    
    func createRoom(name: String, type: String, insecure: Bool = false, completion: @escaping (MXResponse<String>) -> Void) {
        /*
        // Easy way, but doesn't give us enough low-level access to set things up the way we want
        let params = MXRoomCreationParameters()
        params.name = name
        params.preset = kMXRoomPresetPrivateChat // Join by invite only, history is shared...
        params.visibility = kMXRoomDirectoryVisibilityPrivate
        */
        

        
        var params: [String: Any] = [:]
        params["visibility"] = "private"
        params["name"] = name
        //params["preset"] = "private_chat"
        params["join_rules"] = "invite"
        params["history_visibility"] = "shared"
        params["guest_access"] = "forbidden"
        params["room_type"] = type

        // TODO Fill in the starting power levels, etc
        // The convention could be something like this:
        //   100 = Owner
        //    50 = Moderator
        //    30 = Contributor
        //    10 = Commentor
        //     0 = Viewer
        // So for a room owned by someone else in a Circle,
        // you would normally be either a 10 or a 0, depending
        // on whether the owner lets their friends send messages.
        // FIXME I'm not sure what the difference is between 10 and 30 though.
        // We can't limit lower-power users from sending m.message, while
        // still allowing them to send anything else.  Can we?
        // We could, but we would have to define our own new message type.
        // The Matrix spec defines some sort of reaction thing, but
        //   (1) it's deprecated
        //   (2) it was only for stuff like read receipts
        // Boo.
        params["power_level_content_override"] = [
            "events_default": 10,
            "users_default": 10
        ]

        // Let's see if we can turn on encryption here, by
        // getting the proper incantation of combining JSON
        // and MX ObjC data types...
        if !insecure {
            let encryptionEvent = MXRoomCreationParameters.initialStateEventForEncryption(withAlgorithm: "m.megolm.v1.aes-sha2")
            params["initial_state"] = [encryptionEvent]
        }
        
        // Any more-detailed tweaking of the setup params should be
        // done in the completion handler on behalf of the caller.
        // Here we're a generic utility function; we can't know every
        // possible use case.
        
        let restClient: MXRestClient = self.signupMxRc ?? self.session.matrixRestClient
        
        restClient.createRoom(parameters: params) { response in
            switch(response) {
            case .success(let mxCreateRoomResponse):
                print("CREATEROOM\tCreated new room")
                self.objectWillChange.send()
                /* // Already handled the encryption at creation time :)
                if !insecure {
                    if let roomId = mxCreateRoomResponse.roomId {
                        let encryptionParams = [
                            "algorithm": "m.megolm.v1.aes-sha2",
                            "rotation_period_ms": "604800000",
                            "rotation_period_msgs": "100"
                        ]
                        print("CREATEROOM\tSending room encryption event")
                        restClient.sendEvent(toRoom: roomId, eventType: .roomEncryption, content: encryptionParams, txnId: nil) { response2 in
                            switch response2 {
                            case .success(let _):
                                print("CREATEROOM\tSuccess!  Room is now encrypted.")
                                completion(.success(roomId))
                            case .failure(let err):
                                print("CREATEROOM\tFailed to encrypt room: \(err)")
                                completion(.failure(err))
                            }
                        }
                    } else {
                        let msg = "Failed to get new room id for [\(name)]"
                        print("CREATEROOM\t\(msg)")
                        completion(.failure(KSError(message: msg)))
                    }
                }
                else {
                    print("CREATEROOM\tCreated insecure room for [\(name)]")
                    completion(.success(mxCreateRoomResponse.roomId))
                }
                */
                guard let roomId = mxCreateRoomResponse.roomId else {
                    let msg = "Couldn't get id for new room"
                    print("CREATEROOM\t\(msg)")
                    let err = KSError(message: msg)
                    completion(.failure(err))
                    return
                }
                print("CREATEROOM\tSuccess!  Created room for \(name)")
                completion(.success(roomId))
                
            case .failure(let err):
                let msg = "Failed to create room for \(name)"
                print(msg)
                completion(.failure(err))
            }
        }
    }
    
    func createRoom(name: String, type: String, tag: String, insecure: Bool = false, completion: @escaping (MXResponse<String>) -> Void) {
        self.createRoom(name: name, type: type, insecure: insecure) { response in
            switch(response) {
            case .failure(let error):
                print("Failed to create a room for \(name): \(error)")
                completion(response)
            case .success(let roomId):
                print("Success creating room \(name) : [\(roomId)]")

                let restClient: MXRestClient = self.signupMxRc ?? self.session.matrixRestClient
                let order = String(format: "%1.2f", Double.random(in: 0..<1))
                restClient.addTag(tag, withOrder: order, toRoom: roomId) { tagResponse in
                    switch(tagResponse) {
                    case .failure(let error):
                        print("Failed to set tag \"\(tag)\": \(error)")
                        // FIXME Also, delete (leave) the room that we failed to tag??
                        completion(.failure(error))
                    case .success:
                        print("Successfully set tag \"\(tag)\"!")
                        completion(.success(roomId))
                    }
                }
            }
        }
    }
    
    func leaveRoom(roomId: String, completion: @escaping (Bool) -> Void = {_ in }) {
        self.session.leaveRoom(roomId) { response in
            switch(response) {
            case .failure(let error):
                print("Failed to leave room \(roomId): \(error)")
                completion(false)
            case .success:
                print("Left room \(roomId)")
                self.objectWillChange.send()
                completion(true)
            }
            //completion(response)
        }
    }
    
    func addTag(_ tag: String, toRoom roomId: String, completion: @escaping (MXResponse<Void>) -> Void) {
        let restClient: MXRestClient = self.signupMxRc ?? self.session.matrixRestClient
        let order = String(format: "%1.2f", Double.random(in: 0 ..< 1))
        restClient.addTag(tag, withOrder: order, toRoom: roomId, completion: completion)
    }
      
    func getCachedImage(mxURI: String) -> UIImage? {
        let cache_filename = MXMediaManager.cachePath(forMatrixContentURI: mxURI, andType: nil, inFolder: PLAINTEXT_CACHE_FOLDER)
        return MXMediaManager.getFromMemoryCache(withFilePath: cache_filename)
    }
    
    func downloadImage(mxURI: String, completion: @escaping (_ image: UIImage) -> Void) {
        guard let cache_filename = MXMediaManager.cachePath(forMatrixContentURI: mxURI, andType: nil, inFolder: PLAINTEXT_CACHE_FOLDER) else {
            // FIXME Call the completion handler with an error
            return
        }
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: cache_filename) {
            guard let image = MXMediaManager.loadThroughCache(withFilePath: cache_filename) else {
                // FIXME Call the completion handler with an error
                print("File exists but failed to load image through cache: [\(cache_filename)]")
                return
            }
            completion(image)
        } else {
            // We don't have the image file yet
            // First download the image from the media store
            // Then load it through the cache and return it
            // WISHLIST Really wishing there were a Swift extension for the MXMediaManager
            self.session.mediaManager.downloadMedia(
                fromMatrixContentURI: mxURI,
                withType: nil,
                inFolder: nil,
                success: { path in
                    guard let image = MXMediaManager.loadThroughCache(withFilePath: path) else {
                        // FIXME Do something to report/handle the error
                        print("Failed to load image after downloading it")
                        return
                    }
                    completion(image)
                },
                failure: { error in
                    // FIXME Do something to report the error
                    print("Failed to download image through MXMediaManager")
                    return
                }
            )
        }
    }
    
    func getCachedEncryptedImage(mxURI: String) -> UIImage? {
        let cache_filename = MXMediaManager.cachePath(forMatrixContentURI: mxURI, andType: nil, inFolder: DECRYPTED_CACHE_FOLDER)
        return MXMediaManager.getFromMemoryCache(withFilePath: cache_filename)
    }

    
    func downloadEncryptedImage(fileinfo: mEncryptedFile, mimetype: String?, completion: @escaping (MXResponse<UIImage>) -> Void) {
        guard let cache_filename = MXMediaManager.cachePath(forMatrixContentURI: fileinfo.url.absoluteString, andType: nil, inFolder: DECRYPTED_CACHE_FOLDER) else {
            // FIXME Call the completion handler with an error
            let msg = "Couldn't get cache path"
            completion(.failure(KSError(message: msg)))
            return
        }
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: cache_filename) {
            guard let image = MXMediaManager.loadThroughCache(withFilePath: cache_filename) else {
                // FIXME Call the completion handler with an error
                let msg = "File exists but failed to load image through cache: [\(cache_filename)]"
                completion(.failure(KSError(message: msg)))
                return
            }
            completion(.success(image))
        }
        else {
        
            let ecf = fileinfo.toMXECF()
            
            let loader = self.session.mediaManager.downloadEncryptedMedia(
                    fromMatrixContentFile: ecf,
                    mimeType: mimetype,
                    inFolder: "encrypted",
                    success: { maybePath in
                        guard let encrypted_filename = maybePath else {
                            completion(.failure(KSError(message: "Didn't get a path")))
                            return
                        }
                        // We got the encrypted bytes
                        // Now we need to decrypt
                        
                        // Open the I/O streams
                        guard let input = InputStream(fileAtPath: encrypted_filename),
                              let output = OutputStream(toFileAtPath: cache_filename, append: false) else {
                            completion(.failure(KSError(message: "Couldn't open I/O streams")))
                            return
                        }
                        
                        // Finally we can call the decryption routine
                        MXEncryptedAttachments.decryptAttachment(
                                ecf,
                                inputStream: input,
                                outputStream: output,
                                success: {
                                    // FIXME KLUDGE This is such a dirty hack
                                    // If we have the file now, just call ourselves again and we'll get the UIImage
                                    // As-is, this risks recursing forever if something happens to our downloaded file
                                    // The fix is to break out the code that handles the downloaded file into its own function
                                    self.downloadEncryptedImage(fileinfo: fileinfo, mimetype: mimetype, completion: completion)
                                },
                                failure: { error in
                                    let msg = "Failed to decrypt: \(error)"
                                    completion(.failure(KSError(message: msg)))
                                }
                            )
                    },
                    failure: { err in
                        let msg = "Failed to download encrypted data: \(err)"
                        completion(.failure(KSError(message: msg)))
                    }
            )
            if loader == nil {
                let msg = "Failed to start download"
                completion(.failure(KSError(message: msg)))
                return
            }
        
        }
    }
    
    func matrixApiCall(method: String, endpoint: String, body: Data?, contentType: String? = nil, completion: @escaping (Result<(HTTPURLResponse,Data?),MatrixError>)->Void) {
        let url = URL(string: endpoint, relativeTo: self.homeserver)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue(contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
        if let token = self.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let err = error {
                // FIXME This is where we can detect when we're offline etc
                print("MATRIX\tCouldn't make API call")
                completion(.failure(MatrixError(errcode: "M_UNKNOWN", error: "Couldn't make API call")))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let msg = "Couldn't parse response (not HTTP?)"
                print("MATRIX\t\(msg)")
                completion(.failure(MatrixError(errcode: "M_UNKNOWN", error: msg)))
                return
            }
            
            // FIXME Should we also throw an error if the response contains a Matrix error?
            // For now, we return success and let the completion handler deal with it.
            
            completion(.success((httpResponse,data)))
            return
        }
        task.resume()
    }
    
    func uploadImage(image original: UIImage, completion: @escaping (MXProgress<URL>) -> Void) {
        var smallImage: UIImage?
        if original.size.height > 256 || original.size.width > 256 {
            let maxSize = CGSize(width: CGFloat(256), height: CGFloat(256))
            smallImage = downscale_image(from: original, to: maxSize)
            if smallImage == nil {
                let msg = "Failed to downscale image to be uploaded"
                print(msg)
                completion(.failure(KSError(message: msg)))
                return
            }
        }
        let finalImage: UIImage = smallImage ?? original

        guard let data = finalImage.jpegData(compressionQuality: 0.5) else {
            let msg = "Failed to get JPEG data for image to be uploaded"
            print(msg)
            completion(.failure(KSError(message: msg)))
            return
        }
        
        // Need to handle the case where we're not running a full MXSession yet
        // This is for post-signup, pre-first-login
        // Usually we won't have a signupMxRc, but if we have one, we'll go for it first
        let restClient: MXRestClient = self.signupMxRc ?? self.session.matrixRestClient
        
        restClient.uploadContent(data, mimeType: "image/jpeg", timeout: TimeInterval(30.0)) { response in
            switch(response) {
            case .failure(let error):
                print("Failed to upload image \(error)")
            case .progress(let progress):
                print("Still working on uploading image: \(progress)")
            case .success(let url):
                print("Success!  Uploaded image to \(url)")
            }
            completion(response)
        }
    }
    
    func setAvatarImage(image: UIImage, completion: @escaping (MXResponse<URL>) -> Void) {
        print("Setting avatar image")
        self.uploadImage(image: image) { response1 in
            switch(response1) {
            case .failure(let error):
                print("Error: Failed to upload image for new avatar.  Error: \(error)")
                completion(.failure(error))
                break
            case .progress(let progress):
                print("Progress: New avatar upload is \(100 * progress.fractionCompleted)% complete")
                break
            case .success(let url):
                // 2020-11-18
                // I wonder if we're doing something wrong here.
                // Setting other profile info goes through session.myuser
                // Hmmm what if we tried that instead?
                //self.session.matrixRestClient.setAvatarUrl(url, completion: completion)
                // cvw: What was I thinking above?  Was the restClient just not working?
                //      This alternative version looks horrible in comparison to the one-liner above
                /*
                self
                    .session
                    .myUser
                    .setAvatarUrl(
                        url.absoluteString,
                        success: {
                            print("Successfully set avatar URL")
                            self.me().objectWillChange.send()
                            completion(.success(url))
                        },
                        failure: {error in
                            print("Failed to set avatar URL: \(error)")
                            completion(.failure(error!))
                        }
                    )
                */
                // And now we need to support setting our first avatar
                // before we've even logged in for the fist time.
                // (post-signup)
                let restClient: MXRestClient = self.signupMxRc ?? self.session.matrixRestClient
                restClient.setAvatarUrl(url) { response2 in
                    switch response2 {
                    case .success:
                        completion(.success(url))
                    case .failure(let err):
                        completion(.failure(err))
                    }
                }
            }
        }
    }
    
    func getDisplayName(userId: String, completion: @escaping (MXResponse<String>) -> Void) {
        session.matrixRestClient.displayName(forUser: userId) { response in
            switch(response) {
            case .failure(let error):
                print("Failed to get displayname for user \(userId): \(error)")
            case .success(let name):
                print("Got displayname [\(name)] for user \(userId)")
                /*
                // We should let the MatrixUser object decide to do this on its own
                if let user = self.users[userId] {
                    user.objectWillChange.send()
                }
                */
            }
            completion(response)
        }
    }

    
    func setDisplayName(name: String, completion: @escaping (MXResponse<Void>) -> Void) {

        if let restClient = self.signupMxRc {
            restClient.setDisplayName(name, completion: completion)
        }
        else {

            session
                .myUser
                .setDisplayName(
                    name,
                    success: {
                        let user = self.me()
                        user.objectWillChange.send()
                        completion(.success(()))
                    },
                    failure: { err in
                        completion(.failure(err!))
                    }
                )

            //self.session.matrixRestClient.setDisplayName(name, completion: completion)
        }
        
        /*
        guard let userId = self.userId else {
            let msg = "Can't set displayname when we don't have a user ID"
            let err = KSError(message: msg)
            completion(.failure(err))
        }
        let body = """
        {
        "displayname": "\(name)"
        }
        """
            .replacingOccurrences(of: "\n", with: "")
            .data(using: .utf8)
        let apiVersion = "r0"
        self.matrixApiCall(method: "PUT", endpoint: "_matrix/client/\(apiVersion)/profile/\(userId)/displayname", body: body) { response in
            switch response {
            case .success(let (httpResponse, responseData)):
                if httpResponse.statusCode == 200 {
                    completion(.success(name))
                } else {
                    let msg = "Failed to set display name"
                    let err = KSError(message: msg)
                    completion(.failure(err))
                }
            case .failure(let matrixError):
                completion(.failure(matrixError))
            }
        }
        */
    }
    
    func setStatusMessage(message: String, completion: @escaping (MXResponse<String>) -> Void) {
        session
            .myUser
            .setPresence(
                //MXPresenceUnknown,
                .online,
                andStatusMessage: message,
                success: {
                    let user = self.me()
                    user.objectWillChange.send()
                    completion(.success(message))
                },
                failure: { _ in
                    completion(.failure(KSError(message: "Failed to set status message")))
                }
            )
    }

    
    func _getDefaultDomain() -> String? {
        guard let server = self.homeserver?.host else {
            return nil
        }
        if server.starts(with: "matrix.") {
            return String(server.dropFirst(7))
        } else {
            return server
        }
    }
    
    
    func canonicalizeUserId(userId: String) -> String? {
        let defaultDomain = _getDefaultDomain()

        let lowerCased = userId.lowercased()
        //print("lowered \t= \(lowerCased)")
        let prefixed = lowerCased.starts(with: "@") ? lowerCased : "@" + lowerCased
        //print("prefixed \t= \(prefixed)")

        guard defaultDomain != nil || prefixed.contains(":") else {
            return nil
        }

        let suffixed = prefixed.contains(":") ? prefixed : prefixed + ":" + defaultDomain!
        //print("suffixed \t= \(suffixed)")
        let candidate = suffixed
        
        
        // Validate what we've got so far.
        // If it checks out, return it
        // Otherwise return nil
        let tokens = candidate.components(separatedBy: ":")
        if tokens.count == 2 {
            let localpart: String = tokens[0]
            let domain: String = tokens[1]
            
            // From https://matrix.org/docs/spec/appendices#identifier-grammar
            // > The localpart of a user ID is an opaque identifier for that user. It MUST NOT be empty, and MUST contain only the characters a-z, 0-9, ., _, =, -, and /.
            
            // First validate the localpart
            let range = NSRange(location: 0, length: localpart.utf16.count)
            //let regex = try! NSRegularExpression(pattern: "\\A([a-z]|[0-9]|\\.|_|=|-|\\/)+?\\z")
            // swiftlint:disable:next force_try
            let regex = try! NSRegularExpression(pattern: "\\A@([a-z]|[0-9]|\\.|_|=|-|\\/)+?\\z")

            guard let match = regex.firstMatch(in: localpart, options: [], range: range) else {
                print("Regex didn't match :(")
                return nil
            }
            
            // OK good enough for now...
            
            return candidate
        }
        
        return nil
    }
     
    func getUsersAndTheirRooms() -> [MatrixUser : Set<MatrixRoom>] {
        var invIndex: [MatrixUser: Set<MatrixRoom>] = [:]
        
        print("PEOPLE Getting users and their rooms")
        
        for circle in self.circles {
            print("PEOPLE Getting users and rooms for circle \(circle.name)")
            let circleIndex = circle.stream.invertedIndex
            for (user,rooms) in circleIndex {
                print("PEOPLE\tFound user \(user.displayName ?? user.id) with \(rooms.count) rooms")
                let currRooms = invIndex[user] ?? []
                let allRooms = currRooms.union(rooms)
                invIndex[user] = allRooms
            }
        }
        
        //self.objectWillChange.send()

        return invIndex
    }
    
    func verifyDevice(deviceId: String, userId: String, completion: @escaping (MXResponse<String>) -> Void) {
        guard let crypto = self.session.crypto else {
            completion(.failure(KSError(message: "No Matrix crypto")))
            return
        }
        
        let verified: MXDeviceVerification = .verified
        
        /* // Swift compiler bug?  It can't figure out what to do if I make this (Error?) instead of (Error)
        let handle_fail: (Error) -> Void = { err in
            completion(.failure(err))
        }
        */
        
        let handle_success: () -> Void = {
            completion(.success(deviceId))
        }
        
        crypto.setDeviceVerification(verified, forDevice: deviceId, ofUser: userId, success: handle_success, failure: { _ in
            completion(.failure(KSError(message: "Failed to verify device \(deviceId)")))
        })
    }
    
    func blockDevice(deviceId: String, userId: String, completion: @escaping (MXResponse<String>) -> Void) {
        guard let crypto = self.session.crypto else {
            completion(.failure(KSError(message: "No Matrix crypto")))
            return
        }
        
        let blocked: MXDeviceVerification = .blocked
        
        let handle_success: () -> Void = {
            completion(.success(deviceId))
        }
        
        crypto.setDeviceVerification(blocked, forDevice: deviceId, ofUser: userId, success: handle_success, failure: { _ in
            completion(.failure(KSError(message: "Failed to block device \(deviceId)")))
        })
    }
    
    func deleteDevice(deviceId: String, password: String, completion: @escaping (MXResponse<String>) -> Void) {
        guard let mxrc = session.matrixRestClient else {
            print("DELETE\tFailed: No matrix rest client")
            completion(.failure(KSError(message: "No Matrix rest client")))
            return
        }

        mxrc.getSession(toDeleteDevice: deviceId) { response1 in
            switch response1 {
            case .failure(let err):
                let msg = "Authentication failed: \(err)"
                print("DELETE:\t\(msg)")
                completion(.failure(KSError(message: msg)))
            case .success(let mxAuthSession):
                var params: [String: Any] = [:]
                params["type"] = "m.login.password"
                params["identifier"] = [
                    "type" : "m.id.user",
                    "user" : self.whoAmI()
                ]
                params["session"] = mxAuthSession.session

                // Now we have to figure out which version of the password we should send.
                // If we wrote down that we're using two different passwords, then it's
                // ok to just send the user's "raw" password here.
                // Otherwise we're using the bcrypt'ed version, so we need to hash
                // the password before we can send it.

                let keygenMethod: String? = UserDefaults.standard.string(forKey: "keygen_method[\(self.whoAmI())]")

                if keygenMethod == MatrixSecrets.KeygenMethod.fromTwoPasswords.rawValue {
                    params["password"] = password
                } else {
                    guard let secrets = self.generateSecretsFromSinglePassword(userId: self.whoAmI(), password: password) else {
                        let msg = "DELETEDEVICE\tFailed to generate secrets from username/password"
                        print(msg)
                        completion(.failure(KSError(message: msg)))
                        return
                    }
                    params["password"] = secrets.loginPassword
                }

                print("DELETE\tSo far so good...")

                mxrc.deleteDevice(deviceId, authParameters: params) { response2 in
                    switch response2 {
                    case .failure(let err):
                        let msg = "Failed to delete device \(deviceId)"
                        completion(.failure(KSError(message: msg)))
                    case .success:
                        print("DELETE\tSuccess deleting \(deviceId)")
                        // Also notify any Views for our current user
                        self.me().objectWillChange.send()
                        completion(.success(deviceId))
                    }
                }
            }
        }
        
    }
    
    func verify(userId: String, completion: @escaping (MXResponse<String>) -> Void) {
        guard let crypto = self.session.crypto else {
            completion(.failure(KSError(message: "No Matrix crypto")))
            return
        }
        
        crypto.setUserVerification(true, forUser: userId, success: {completion(.success(userId))}, failure: {_ in
            completion(.failure(KSError(message: "Failed to verify user \(userId)")))
        })
    }
    
    func unverify(userId: String, completion: @escaping (MXResponse<String>) -> Void) {
        guard let crypto = self.session.crypto else {
            completion(.failure(KSError(message: "No Matrix crypto")))
            return
        }
        /*
          // This won't work, because MatrixSDK asserts that the verificationStatus MUST BE true.
          // Fucking hell, guys.  What are we supposed to do when somebody loses their key?
        crypto.setUserVerification(false, forUser: userId, success: {completion(.success(userId))}, failure: {_ in
            completion(.failure(KSError(message: "Failed to unverify user \(userId)")))
        })
        */
    }
    
    func getTrustLevel(userId: String) -> MXUserTrustLevel {
        guard let crypto = self.session.crypto else {
            let trustLevel = MXUserTrustLevel()
            return trustLevel
        }
        return crypto.trustLevel(forUser: userId)
    }
    
    func getCryptoAlgorithm(roomId: String) -> String {
        guard let crypto = self.session.crypto else {
            return "Plaintext"
        }
        
        //return crypto.store.algorithm(forRoom: roomId)
        return "Encrypted/Unknown"
    }
    
    func getOlmSessions(deviceKey: String) -> [MXOlmSession] {
        return [] // Returning nothing since we no longer have access to the crypto store
        /*
        guard let crypto = self.session.crypto else {
            return []
        }
        guard let result = crypto.store.sessions(withDevice: deviceKey) else {
            return []
        }
        return result
        */
    }
    
    func getInboundGroupSessions() -> [MXOlmInboundGroupSession] {
        return [] // Returning nothing since our access to the crypto store went away
        /*
        guard let crypto = self.session.crypto else {
            return []
        }
        guard let sessions = crypto.store.inboundGroupSessions() else {
            return []
        }

        for session in sessions {
            print("CRYPTO\tFound session \(session.id)")
            print("CRYPTO\tFor roomId = \(session.roomId ?? "unknown")")
            if let room = self.getRoom(roomId: session.roomId),
               let name = room.displayName {
                print("CRYPTO\tRoom is \(name)")
            }
            print("CRYPTO\tOther keys claimed:")
            for (k,v) in session.keysClaimed {
                print("CRYPTO\t \(k) --> \(v)")
            }
            print("CRYPTO\t---")
        }
        return sessions
        */
    }

    func getOutboundGroupSessions() -> [MXOlmOutboundGroupSession] {
        return [] // We no longer have access to the crypto store.  Returning nothing for now.
        /*
        guard let crypto = self.session.crypto else {
            return []
        }
        return crypto.store.outboundGroupSessions()
        */
    }

    func ensureEncryption(roomId: String, completion: @escaping (MXResponse<Void>) -> Void) {
        guard let crypto = self.session.crypto else {
            return
        }
        crypto.ensureEncryption(inRoom: roomId,
                                success: {
                                    completion(.success(()))
                                },
                                failure: { _ in
                                    let err = KSError(message: "Failed to ensure encryption")
                                    completion(.failure(err))
                                }
        )
    }

    func tryToDecrypt(message: MatrixMessage, completion: @escaping (MXResponse<Void>) -> Void) {
        let tag = "TRYTODECRYPT"
        
        print("\(tag) Trying to decrypt message [\(message.id)]")
        
        guard let crypto = self.session.crypto else {
            completion(.failure(KSError(message: "\(tag) Couldn't get mxcrypto")))
            return
        }
        
        crypto.hasKeys(toDecryptEvent: message.mxevent) { hasKeys in
            if hasKeys {
                let decryptionResult = crypto.decryptEvent(message.mxevent, inTimeline: nil)
                if let content = decryptionResult?.clearEvent["content"] as? [String:Any] {
                    let decoder = DictionaryDecoder()
                    message.content = try? decoder.decode(MatrixMsgContent.self, from: content)
                    if message.content != nil {
                        print("\(tag) Decryption success!")
                        completion(.success(()))
                    } else {
                        let msg = "\(tag) Failed to decrypt message \(message.id)"
                        print(msg)
                        completion(.failure(KSError(message: msg)))
                    }
                }
            }
            else {
                crypto.reRequestRoomKey(for: message.mxevent)
                let msg = "\(tag) Don't have keys to decrypt"
                print(msg)
                completion(.failure(KSError(message: msg)))
            }
        }
    }

    func setRoomType(roomId: String, roomType: String, completion: @escaping (MXResponse<String>) -> Void) {
        let mxrc = self.signupMxRc ?? self.session.matrixRestClient

        if let restClient = mxrc {
            restClient
                .sendStateEvent(toRoom: roomId,
                                eventType: .custom(EVENT_TYPE_ROOMTYPE),
                                content: ["type": roomType],
                                stateKey: "",
                                completion: completion)
        } else {
            let msg = "No Matrix rest client"
            let err = KSError(message: msg)
            completion(.failure(err))
        }
    }
    
    func setAccountData(_ data: [String : String], for dataType: String, completion: @escaping (MXResponse<Void>) -> Void) {
        
        if let restClient = self.signupMxRc {
            restClient
                .setAccountData(data,
                                for: .other(dataType),
                                completion: completion)
        } else {
            self.session.matrixRestClient
                .setAccountData(data,
                                for: .other(dataType),
                                completion: completion)
        }
        
    }
    
    func setRoomAvatar(roomId: String, image: UIImage, completion: @escaping (MXResponse<Void>) -> Void) {
        if let restClient = self.signupMxRc {
            // We must not have logged in yet
            // Use the signup MXRC to get it done
            self.uploadImage(image: image) { response1 in
                switch response1 {
                case .failure(let err):
                    completion(.failure(err))
                case .progress(let progress):
                    // Do nothing for now
                    break
                case .success(let url):
                    restClient.setAvatar(ofRoom: roomId, avatarUrl: url) { response2 in
                        switch response2  {
                        case .failure(let err):
                            completion(.failure(err))
                        case .success:
                            completion(.success(()))
                        }
                    }
                }
            }
        } else {
            if let room = self.getRoom(roomId: roomId) {
                room.setAvatarImage(image: image, completion: completion)
            }
        }
    }
    
}
