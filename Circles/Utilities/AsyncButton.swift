//
//  AsyncButton.swift
//  Circles
//  * Based on https://swiftbysundell.com/articles/building-an-async-swiftui-button/
//  Created by Charles Wright on 4/21/22.
//

import SwiftUI
import JDStatusBarNotification

struct AsyncButton<Label: View>: View {
    var role: ButtonRole?
    var errorMessage: String?
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
                
                await ToastPresenter.shared.showToast(message: errorMessage ?? error.localizedDescription)
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
