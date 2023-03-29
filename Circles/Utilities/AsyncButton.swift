//
//  AsyncButton.swift
//  Circles
//  * Based on https://swiftbysundell.com/articles/building-an-async-swiftui-button/
//  Created by Charles Wright on 4/21/22.
//

import SwiftUI

struct AsyncButton<Label: View>: View {
    var action: () async throws -> Void
    @ViewBuilder var label: () -> Label

    @State private var pending = false

    func runAction() {
        pending = true
    
        Task(priority: .medium) {
            try await action()
            await MainActor.run {
                pending = false
            }
        }
    }
    
    var body: some View {
        Button(
            action: runAction,
            label: {
                label()
            }
        )
        .disabled(pending)
    }
}
