//
//  EmailLoginRequestTokenForm.swift
//  Circles
//
//  Created by Charles Wright on 3/25/24.
//

import Foundation
import SwiftUI
import Combine
import Matrix
import MarkdownUI

struct EmailLoginRequestTokenForm: View {
    var session: any UIASession
    var addresses: [String]
    
    @State var selectedAddress: String?

    @Binding var secret: String
    
    func submit() async throws {
        if let address = selectedAddress {
            guard let secret = try? await session.doEmailLoginRequestTokenStage(email: address)
            else {
                print("Failed to request email token")
                return
            }
 
            await MainActor.run {
                self.secret = secret
            }
        } else {
            print("submit() - Error: No email address selected")
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Authenticate with email")
                .font(.title2)
                .fontWeight(.bold)
            Text("We will send a short 6-digit code to your email address to verify your identity")
                .lineLimit(2)
            
            Picker("Email Address", selection: $selectedAddress) {
                ForEach(addresses, id: \.self) { address in
                    // The .tag(Optional()) bit is necessary because our selection is an optional type
                    // See https://developer.apple.com/documentation/swiftui/view/tag(_:)
                    Text(address).tag(Optional(address))
                }
            }
            .onAppear {
                if addresses.count == 1,
                   let address = addresses.first
                {
                    self.selectedAddress = address
                }
            }
            

            Spacer()
            
            AsyncButton(action: submit) {
                Text("Request Code")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(selectedAddress == nil)
            
            Spacer()
            
        }
        .padding()

    }
}
