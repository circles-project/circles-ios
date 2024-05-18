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
    @State var userIdString: String = ""
    @State var showConfirmation = false
    
    var body: some View {
        VStack {
            let userId = session.matrix.creds.userId
            VStack {
                Label("Warning", systemImage: "exclamationmark.triangle")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Deactivating an account is permanent, and cannot be undone.")
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(.red)
            
            Spacer()
            
            VStack {
                Text("To permanently deactivate your account, enter your user ID and tap the button below.")
                    .multilineTextAlignment(.center)
                TextField("User ID", text: $userIdString, prompt: Text(userId.stringValue))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(width: 300.0, height: 40.0)
                
                let fullUserIdString = "@\(userIdString):\(userId.domain)"
                Button(role: .destructive, action: {
                    showConfirmation = true
                }) {
                    Label("Deactivate my account", systemImage: "xmark.bin")
                }
                .buttonStyle(.bordered)
                .disabled(fullUserIdString != userId.stringValue)
                .confirmationDialog("Confirm deactivation",
                                    isPresented: $showConfirmation,
                                    actions: {
                                        AsyncButton(role: .destructive, action: {
                                            try await self.store.deactivate()
                                        }) {
                                            Text("Permanently deactivate")
                                        }
                                    },
                                    message: {
                                        Text("Last chance to reconsider")
                                    }
                )
            }
            
            Spacer()
        }
        .padding()
    }
}

/*
struct DeactivateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        DeactivateAccountView()
    }
}
*/
