//
//  AsyncButton.swift
//  Circles
//  * Based on https://swiftbysundell.com/articles/building-an-async-swiftui-button/
//  Created by Charles Wright on 4/21/22.
//

import SwiftUI

struct AsyncButton<Label: View>: View {
    var action: () async -> Void
    @ViewBuilder var label: () -> Label

    @State private var pending = false

    var body: some View {
        Button(
            action: {
                pending = true
            
                Task {
                    await action()
                    pending = false
                }
            },
            label: {
                label()
            }
        )
        .disabled(pending)
    }
}
