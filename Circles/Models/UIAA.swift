//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  UIAA.swift
//  Circles for iOS
//
//  Created by Charles Wright on 4/26/21.
//

import Foundation

public struct UiaaAuthFlow: Codable {
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

public struct mLoginTermsParams: Codable {
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
        var en: LocalizedPolicy?
    }
    
    var policies: [String:PolicyInfo]
}

//typealias UiaaStateParams = [String: [String:String]]?
public struct UiaaParams: Codable {
    var terms: mLoginTermsParams?
}

public struct UiaaSessionState: Codable {
    var errcode: String?
    var error: String?
    var flows: [UiaaAuthFlow]
    var params: UiaaParams?
    var completed: [String]?
    var session: String
}

public struct UiaaSessionStateBare: Codable {
    var session: String
}
