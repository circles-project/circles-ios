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

    @State var emailAddress: String = ""

    @Binding var secret: String
    
    enum FocusField {
        case email
    }
    @FocusState var focus: FocusField?
    
    var addressIsValid: Bool {
        // https://stackoverflow.com/questions/201323/how-can-i-validate-an-email-address-using-a-regular-expression
        let regex = #/(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/#
        guard let match = try? regex.wholeMatch(in: emailAddress)
        else {
            return false
        }
        return true
    }
    
    func submit() async throws {
        if addressIsValid {
            guard let secret = try? await session.doEmailLoginRequestTokenStage(email: emailAddress)
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
            Text("Authenticate with email")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            Text("We will send a short 6-digit code to your email address to verify your identity.")
                .lineLimit(2)
            
            Spacer()
            
            Text("You have the following addresses enrolled:")
            ScrollView {
                ForEach(addresses, id: \.self) { address in
                    Text(address)
                        .foregroundColor(.gray)
                }
            }
            .padding(.leading)
            
            HStack {
                TextField("you@example.com", text: $emailAddress, prompt: Text("Email address"))
                    .customEmailTextFieldStyle(contentType: .emailAddress, keyboardType: .emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focus, equals: .email)
                    //.focused($inputFocused)
                    //.frame(width: 300.0, height: 40.0)
                    .onSubmit {
                        Task {
                            try await submit()
                        }
                    }
                    .onAppear {
                        self.focus = .email
                    }
                    .padding()
                Button(action: {
                    self.emailAddress = ""
                }) {
                    Image(systemName: SystemImages.xmark.rawValue)
                        .foregroundColor(.gray)
                }
            }
            
            AsyncButton(action: submit) {
                Text("Request Code")
            }
            .buttonStyle(BigBlueButtonStyle())
            .disabled(!addressIsValid)
            
            Spacer()
            
        }
        .padding()

    }
}
