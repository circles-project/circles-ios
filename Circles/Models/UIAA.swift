//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  UIAA.swift
//  Circles for iOS
//
//  Created by Charles Wright on 4/26/21.
//

import Foundation
import AnyCodable

public enum UIAA {
    
    struct Flow: Codable {
        var stages: [String]
        
        func isSatisfiedBy(completed: [String]) -> Bool {
            completed.starts(with: stages)
        }

        mutating func pop(stage: String) {
            if stages.starts(with: [stage]) {
                stages = Array(stages.dropFirst())
            }
        }
    }
    
    /*
    // Attempt 1: Make the Matrix UIAA params a dictionary of dictionaries
    //            - Doesn't work because some params (eg m.login.terms) are more complex than this
    //typealias UiaaStateParams = [String: [String:String]]?

    // Attempt 2: Make the Matrix UIAA params a custom struct with special cases for the auth types that we know about
    //            - This is actually the right way to go, it just needs a bit more work.
    //            - And this implementation didn't work for the new homegrown UIA implementation
    public struct UiaaParams: Codable {
        var terms: mLoginTermsParams?
        var appStore: AppleSubscriptionParams?

        enum CodingKeys: String, CodingKey {
            case terms = "terms"
            case appStore = "social.kombucha.login.subscription.apple"
        }
    }
    */

    // Attempt 3: "F*** it, make my compile problems go away"
    //            - This works to make it compile, but Swift throws a warning: Casting back from AnyCodable will always fail.
    //            - We need to go back to the drawing board and actually make approach #2 work
    //typealias UiaaParams = [String: AnyCodable]

    // Attempt 4: Bite the bullet; Manually wrangle the Codable compliance ourselves
    public struct Params {
        private var items: [String: Any]
        
        subscript(index: String) -> Any? {
            get {
                return items[index]
            }
            set(newValue) {
                items[index] = newValue
            }
        }
    }
    
    public struct SessionState: Codable {
        var errcode: String?
        var error: String?
        var flows: [Flow]
        var params: Params?
        var completed: [String]?
        var session: String

        func hasCompleted(stage: String) -> Bool {
            guard let completed = completed else {
                return false
            }
            return completed.contains(stage)
        }
    }
}

extension UIAA.Flow: Identifiable {
    var id: String {
        stages.joined(separator: " ")
    }
}

extension UIAA.Flow: Equatable {
    static func != (lhs: UIAA.Flow, rhs: UIAA.Flow) -> Bool {
        if lhs.stages.count != rhs.stages.count {
            return true
        }
        for (l,r) in zip(lhs.stages, rhs.stages) {
            if l != r {
                return true
            }
        }
        return false
    }
}

extension UIAA.Flow: Hashable {
    public func hash(into hasher: inout Hasher) {
        for stage in stages {
            hasher.combine(stage)
        }
    }
}

public struct TermsParams: Codable {
    struct PolicyInfo: Codable {
        struct LocalizedPolicy: Codable {
            var name: String
            var url: URL
        }
        
        var version: String
        // FIXME this is the awfulest f**king kludge I think I've ever written
        // But the Matrix JSON struct here is pretty insane
        // Rather than make a proper dictionary, they throw the version in the
        // same object with the other keys of what should be a natural dict.
        // Parsing this properly is going to be something of a shitshow.
        // But for now, we do it the quick & dirty way...
        //var en: LocalizedPolicy?
        // UPDATE (2022-04-22)
        // - The trick to making this work is to realize: There is no spoon.  m.login.terms is not in the Matrix spec. :)
        // - Therefore we don't need to slavishly stick to this messy design.
        // - We can really do whatever we want here.
        // - Really the basic structure from Matrix is pretty good.  It just needs a little tweak.
        var localizations: [String: LocalizedPolicy]
    }
    
    var policies: [String:PolicyInfo]
}


public struct AppleSubscriptionParams: Codable {
    var productIds: [String]
}

public struct PasswordEnrollParams: Codable {
    var minimumLength: Int
}

public struct EmailLoginParams: Codable {
    var addresses: [String]
}

public struct BSSpekeOprfParams: Codable {
    var curve: String
    var hashFunction: String
}

public struct BSSpekeEnrollParams: Codable {
    struct PHFParams: Codable {
        var name: String
        var iterations: UInt
        var blocks: UInt
    }
    var blindSalt: String
    var phfParams: PHFParams
}

public struct BSSpekeVerifyParams: Codable {
    struct PHFParams: Codable {
        var name: String
        var iterations: UInt
        var blocks: UInt
    }
    var B: String  // Server's ephemeral public key
    var blindSalt: String
    var phfParams: PHFParams
}


extension UIAA.Params: Codable {
    
    enum CodingKeys: String, CodingKey {
        case mLoginTerms = "m.login.terms"
        case mLoginPassword = "m.login.password"
        case mLoginDummy = "m.login.dummy"
        case mEnrollPassword = "m.enroll.password"
        case mEnrollEmailRequestToken = "m.enroll.email.request_token"
        case mEnrollEmailSubmitToken = "m.enroll.email.submit_token"
        case mLoginEmailRequestToken = "m.login.email.request_token"
        case mLoginEmailSubmitToken = "m.login.email.submit_token"
        case mEnrollBSSpekeOprf = "m.enroll.bsspeke-ecc.oprf"
        case mEnrollBSSpekeSave = "m.enroll.bsspeke-ecc.save"
        case mLoginBSSpekeOprf = "m.login.bsspeke-ecc.oprf"
        case mLoginBSSpekeVerify = "m.login.bsspeke-ecc.verify"
        case mLoginSubscriptionApple = "org.futo.subscription.apple"
    }

    
    public init(from decoder: Decoder) throws {
        self.items = .init()
        
        // Approach:
        // - Define a whole bunch of coding keys, based on the known auth types
        // - Get a container from the decoder
        // - Attempt to decode each element in the container, using its coding key to determine its type
        // - After we decode each thing, stick it in the internal dictionary keyed by its coding key (ie its auth type)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // This is painful but it works.
        // Why can't our CodingKeys be CaseIterable when they have associated values?  This could be so much cleaner...
        
        if let appleParams = try? container.decode(AppleSubscriptionParams.self, forKey: .mLoginSubscriptionApple) {
            self.items[CodingKeys.mLoginSubscriptionApple.rawValue] = appleParams
        }
        
        if let termsParams = try? container.decode(TermsParams.self, forKey: .mLoginTerms) {
            self.items[CodingKeys.mLoginTerms.rawValue] = termsParams
        }
        
        if let passwordParams = try? container.decode(PasswordEnrollParams.self, forKey: .mEnrollPassword) {
            self.items[CodingKeys.mEnrollPassword.rawValue] = passwordParams
        }
        
        if let emailParams = try? container.decode(EmailLoginParams.self, forKey: .mLoginEmailRequestToken) {
            self.items[CodingKeys.mLoginEmailRequestToken.rawValue] = emailParams
        }
        
        if let bsspekeParams = try? container.decode(BSSpekeOprfParams.self, forKey: .mEnrollBSSpekeOprf) {
            self.items[CodingKeys.mEnrollBSSpekeOprf.rawValue] = bsspekeParams
        }
        
        if let bsspekeParams = try? container.decode(BSSpekeOprfParams.self, forKey: .mLoginBSSpekeOprf) {
            self.items[CodingKeys.mLoginBSSpekeOprf.rawValue] = bsspekeParams
        }
        
        if let bsspekeParams = try? container.decode(BSSpekeEnrollParams.self, forKey: .mEnrollBSSpekeSave) {
            self.items[CodingKeys.mEnrollBSSpekeSave.rawValue] = bsspekeParams
        }
        
        if let bsspekeParams = try? container.decode(BSSpekeVerifyParams.self, forKey: .mLoginBSSpekeVerify) {
            self.items[CodingKeys.mLoginBSSpekeVerify.rawValue] = bsspekeParams
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Now we need to look at what all we've got
        // * Try to pull each possible thing out of the dictionary, and if we find it, cast it to its real type
        // * Encode it into the container
        // This function is going to wind up essentially mirroring the `decode()` function above
        // - For each `if let foo` up there, we'll have the exact same `if let foo` down here
        
        if let appleParams = items[CodingKeys.mLoginSubscriptionApple.rawValue] as? AppleSubscriptionParams {
            try container.encode(appleParams, forKey: .mLoginSubscriptionApple)
        }
        
        if let termsParams = items[CodingKeys.mLoginTerms.rawValue] as? TermsParams {
            try container.encode(termsParams, forKey: .mLoginTerms)
        }
        
        if let passwordParams = items[CodingKeys.mEnrollPassword.rawValue] as? PasswordEnrollParams {
            try container.encode(passwordParams, forKey: .mEnrollPassword)
        }
        
        if let emailParams = items[CodingKeys.mLoginEmailRequestToken.rawValue] as? EmailLoginParams {
            try container.encode(emailParams, forKey: .mLoginEmailRequestToken)
        }
        
        if let bsspekeParams = items[CodingKeys.mEnrollBSSpekeOprf.rawValue] as? BSSpekeOprfParams {
            try container.encode(bsspekeParams, forKey: .mEnrollBSSpekeOprf)
        }
        
        if let bsspekeParams = items[CodingKeys.mLoginBSSpekeOprf.rawValue] as? BSSpekeOprfParams {
            try container.encode(bsspekeParams, forKey: .mLoginBSSpekeOprf)
        }
        
        if let bsspekeParams = items[CodingKeys.mEnrollBSSpekeSave.rawValue] as? BSSpekeEnrollParams {
            try container.encode(bsspekeParams, forKey: .mEnrollBSSpekeSave)
        }
        
        if let bsspekeParams = items[CodingKeys.mLoginBSSpekeVerify.rawValue] as? BSSpekeVerifyParams {
            try container.encode(bsspekeParams, forKey: .mLoginBSSpekeVerify)
        }
    }
}
