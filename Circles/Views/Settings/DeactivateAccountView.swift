//
//  DeactivateAccountView.swift
//  Circles
//
//  Created by Charles Wright on 7/6/23.
//

import SwiftUI
import Matrix

struct DeactivateAccountView: View {
    @ObservedObject var store: CirclesStore
    var session: CirclesApplicationSession
    @State private var showAlert = false
    @State private var errorMessage = ""
    
    var showErrorMessageView: some View {
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
        ZStack {
            showErrorMessageView
            VStack {
                VStack {
                    Label("Warning", systemImage: "exclamationmark.triangle")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Deactivating an account is permanent, and cannot be undone.")
                }
                .foregroundColor(.red)
                
                Spacer()
                
                VStack {
                    Text("To permanently deactivate your account press button bellow and follow the instructions.")
                    Button(role: .destructive, action: {
                        showAlert = true
                    }) {
                        Label("Deactivate my account", systemImage: "xmark.bin")
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            if showAlert {
                let userId = session.matrix.creds.userId.stringValue
                let customViewModel = DeactivateAccountAlertModel(userId: userId,
                                                                  title: "Deactivation",
                                                                  message: "To delete your account, type in your full user id \(userId) below.")
                GeometryReader { geometry in
                    DeactivateAccountAlertView(model: customViewModel,
                                               onConfirm: {
                                                    Task {
                                                        do {
                                                            try await self.store.deactivate()
                                                        } catch {
                                                            errorMessage = error.localizedDescription
                                                        }
                                                    }
                                                },
                                                onCancel: {
                                                    showAlert = false
                                                }
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
            }
        }
    }
}

/*
struct DeactivateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        DeactivateAccountView()
    }
}
*/
