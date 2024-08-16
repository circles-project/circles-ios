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
        
        // Also register our custom room types, so the Matrix library can automatically create Room's of the proper type when it sees the state for a new room
        Matrix.registerRoomType(ROOM_TYPE_GROUP, GroupRoom.self)
        Matrix.registerRoomType(ROOM_TYPE_CIRCLE, Matrix.Room.self)
        Matrix.registerRoomType(ROOM_TYPE_PHOTOS, GalleryRoom.self)
        
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
