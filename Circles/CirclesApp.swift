//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CirclesApp.swift
//  Circles for iOS
//
//  Created by Charles Wright on 5/25/21.
//

import SwiftUI
import StoreKit

@main
struct CirclesApp: App {
    @StateObject private var store = KSStore()
    @StateObject private var iapObserver = AppStoreInterface()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .environmentObject(store)
                .environmentObject(iapObserver)
                .onAppear {
                    SKPaymentQueue.default().add(iapObserver)
                    iapObserver.fetchProducts(matchingIdentifiers: ["social.kombucha.circles.membership.standard_3_month", "com.temporary.id.nonconsumable.a", "com.temporary.id.nonconsumable.b"])
                }
                .onDisappear {
                    SKPaymentQueue.default().remove(iapObserver)
                }
        }
    }
}
