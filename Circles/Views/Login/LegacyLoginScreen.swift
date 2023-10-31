//
//  LegacyLoginScreen.swift
//  Circles
//
//  Created by Charles Wright on 10/31/23.
//

import SwiftUI
import Matrix

struct LegacyLoginScreen: View {
    @ObservedObject var session: LegacyLoginSession
    @State var password: String = ""
    @State var showPassword = false
    
    var body: some View {
        VStack {
            Text("Enter password for \(session.userId.stringValue)")
            
            SecureFieldWithEye(label: "Password", text: $password, showText: showPassword)
                .onSubmit {
                    Task {
                        try await session.login(password: password)
                    }
                }
        }
    }
}

