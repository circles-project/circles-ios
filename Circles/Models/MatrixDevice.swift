//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  MatrixDevice.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/20/21.
//

import Foundation
import MatrixSDK

class MatrixDevice: ObservableObject, Identifiable {
    private let info: MXDeviceInfo
    let id: String // For Identifiable
    //let userId: String
    let matrix: MatrixInterface
    
    init(from info: MXDeviceInfo, on matrix: MatrixInterface) {
        self.info = info
        self.id = info.deviceId
        //self.userId = userId
        self.matrix = matrix
    }
    
    var userId: String {
        info.userId
    }
    
    var user: MatrixUser? {
        matrix.getUser(userId: info.userId)
    }
    
    var displayName: String? {
        info.displayName
    }
    
    var fingerprint: String? {
        info.fingerprint
    }
    
    var isVerified: Bool {
        guard let trustLevel = info.trustLevel else {
            return false
        }
        return trustLevel.isVerified
    }
    
    var isBlocked: Bool {
        guard let trustLevel = info.trustLevel else {
            return false
        }
        return trustLevel.localVerificationStatus == .blocked
    }
    
    var isCrossSigningVerified: Bool {
        guard let trustLevel = info.trustLevel else {
            return false
        }
        return trustLevel.isCrossSigningVerified
    }
    
    var isLocallyVerified: Bool {
        guard let trustLevel = info.trustLevel else {
            return false
        }
        return trustLevel.isLocallyVerified
    }
    
    func verify() {
        self.matrix.verifyDevice(deviceId: self.id, userId: self.userId) { response in
            if response.isSuccess {
                self.objectWillChange.send()
            }
        }
    }
    
    func block() {
        self.matrix.blockDevice(deviceId: self.id, userId: self.userId) { response in
            if response.isSuccess {
                self.objectWillChange.send()
            }
        }
    }
    
    var sessions: [MXOlmSession] {
        // FIXME I don't think this is what we're supposed to provide
        // I think it really wants the public key here, not just its fingerprint
        //guard let deviceKey = self.fingerprint else {
        guard let deviceKey = self.info.identityKey else {
            return []
        }
        return matrix.getOlmSessions(deviceKey: deviceKey)
    }
    
    var key: String {
        self.info.identityKey
    }
}

extension MatrixDevice: Hashable {
    // For Equatable
    static func == (lhs: MatrixDevice, rhs: MatrixDevice) -> Bool {
        return lhs.id == rhs.id
    }
    
    // For Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
