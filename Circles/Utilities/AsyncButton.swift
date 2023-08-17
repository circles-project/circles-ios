//
//  AsyncButton.swift
//  Circles
//  * Based on https://swiftbysundell.com/articles/building-an-async-swiftui-button/
//  Created by Charles Wright on 4/21/22.
//

import SwiftUI

struct AsyncButton<Label: View>: View {
    var role: ButtonRole?
    var action: () async throws -> Void
    @ViewBuilder var label: () -> Label

    @State private var pending = false

    func runAction() {
        pending = true
    
        Task {
            do {
                try await action()
            } catch {
                print("AsyncButton: Action failed")
            }
            await MainActor.run {
                pending = false
            }
        }
    }
    
    var body: some View {
        Button(
            role: role,
            action: runAction,
            label: {
                label()
            }
        )
        .disabled(pending)
    }
}
