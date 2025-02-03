//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CirclesApp.swift
//  Circles for iOS
//
//  Created by Charles Wright on 5/25/21.
//

import SwiftUI
import StoreKit
import os
import Matrix

let EVENT_TYPE_CIRCLES_CONFIG_V2 = "org.futo.circles.config.v2"

struct CirclesConfigContentV2: Codable {
    var root: RoomId
    var groups: RoomId
    var galleries: RoomId
    var people: RoomId
    var profile: RoomId // aka Shared Circles
    var timelines: RoomId
}

@main
struct CirclesApp: App {
    @UIApplicationDelegateAdaptor(CirclesAppDelegate.self) var appDelegate

    @StateObject private var store = CirclesStore()
    private var paymentQueue = SKPaymentQueue.default()
    private var countryCode = SKPaymentQueue.default().storefront?.countryCode
    
    public static var logger = os.Logger(subsystem: "Circles", category: "Circles")
    
    init() {
        // We need to register all of our custom types with the Matrix library, so it can decode them for us
        Matrix.registerAccountDataType(EVENT_TYPE_CIRCLES_CONFIG_V1, CirclesConfigContentV1.self)
        Matrix.registerAccountDataType(EVENT_TYPE_CIRCLES_CONFIG_V2, CirclesConfigContentV2.self)
        
        print("CirclesApp: Done with init()")
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .environmentObject(store)
                .onAppear {
                    print("CirclesApp: onAppear")
                }
        }
    }
}
