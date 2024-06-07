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
    @StateObject private var toastManager = ToastManager()
    private var paymentQueue = SKPaymentQueue.default()
    private var countryCode = SKPaymentQueue.default().storefront?.countryCode
    
    public static var logger = os.Logger(subsystem: "Circles", category: "Circles")
    
    init() {
        // We need to register all of our custom types with the Matrix library, so it can decode them for us
        Matrix.registerAccountDataType(EVENT_TYPE_CIRCLES_CONFIG, CirclesConfigContent.self)
        
        print("CirclesApp: Done with init()")
    }

    var body: some Scene {
            WindowGroup {
                ContentView(store: store)
                    .environmentObject(store)
                    .environmentObject(toastManager)
                    .overlay(
                        VStack {
                            if toastManager.isShowing {
                                ToastView(message: toastManager.message)
                                    .padding(.top, 50)
                                    .transition(.move(edge: .top))
                                    .zIndex(1)
                            }
                            Spacer()
                        }
                    )
                    .edgesIgnoringSafeArea(.all)
            }
        }
}
