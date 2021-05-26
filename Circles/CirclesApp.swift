//
//  CirclesApp.swift
//  Circles
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
