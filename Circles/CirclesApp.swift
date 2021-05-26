//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CirclesApp.swift
//  Circles for iOS
//
//  Created by Charles Wright on 5/25/21.
//

import SwiftUI

@main
struct CirclesApp: App {
    @StateObject private var store = KSStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .environmentObject(store)
        }
    }
}
