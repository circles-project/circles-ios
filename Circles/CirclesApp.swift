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

                    // The Kombucha subscriptions should come from the server in a UIAA stage
                    // For now, we need the BYOS options
                    // We can store those in the app bundle as Apple explains here https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/loading_in-app_product_identifiers
                    guard let productIdentifiers = BringYourOwnServer.loadProducts() else {
                        print("CIRCLES\tFailed to load BYOS product ids")
                        return
                    }

                    iapObserver.fetchProducts(matchingIdentifiers: productIdentifiers)
                }
                .onDisappear {
                    SKPaymentQueue.default().remove(iapObserver)
                }
        }
    }
}
