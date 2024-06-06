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
    
    @State private var errorMessage = ""
    @State private var pending = false

    func runAction() {
        pending = true
    
        Task {
            do {
                try await action()
            } catch {
                if let error = error as? CustomErrors {
                    errorMessage = error.errorDescription ?? "Unknown error"
                } else {
                    errorMessage = error.localizedDescription
                }
                print("AsyncButton: Action failed")
            }
            await MainActor.run {
                pending = false
            }
        }
    }
    
    private var showErrorMessageView: some View {
        VStack {
            if errorMessage != "" {
                ToastView(titleMessage: errorMessage)
                Text("")
                    .onAppear {
                        errorMessage = ""
                    }
            }
        }
    }
    
    var body: some View {
        VStack {
            showErrorMessageView
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
}
