//
//  EmailEnrollForm.swift
//  Circles
//
//  Created by Charles Wright on 3/31/23.
//

import Foundation
import SwiftUI
import Combine
import Matrix
import MarkdownUI

struct EmailEnrollRequestTokenForm: View {
    var session: any UIASession
    
    //@FocusState var inputFocused
    @State var showingKeyboard = false

    @Binding var secret: String
    @State var address = ""
    
    enum FocusField {
        case email
    }
    @FocusState var focus: FocusField?
    
    var addressIsValid: Bool {
        // https://stackoverflow.com/questions/201323/how-can-i-validate-an-email-address-using-a-regular-expression
        let regex = #/(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/#
        guard let _ = try? regex.wholeMatch(in: address) // let match
        else {
            return false
        }
        return true
    }
    
    // Inspired by https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/
    private var keyboardPublisher: AnyPublisher<CGFloat,Never> {
        Publishers.Merge(
            NotificationCenter.default
                              .publisher(for: UIResponder.keyboardWillShowNotification)
                              .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
                              .map { $0.height },
            NotificationCenter.default
                              .publisher(for: UIApplication.keyboardWillHideNotification)
                              .map { _ in CGFloat(0) }
        )
        .eraseToAnyPublisher()
    }
    
    func submit() async throws {
        if addressIsValid {
            guard let secret = try? await session.doEmailEnrollRequestTokenStage(email: address, subscribeToList: true)
            else {
                print("Failed to request email token")
                return
            }
 
            await MainActor.run {
                self.secret = secret
            }
        }
    }
    
    var body: some View {
        VStack {
            Text("Verify your email address")
                .font(.title2)
                .fontWeight(.bold)
            Text("We will send a short 6-digit code to your email address to verify your identity")
            
            // Extra call to .init() because SwiftUI actually uses different contructors based on whether you pass a string literal or a String
            // https://developer.apple.com/forums/thread/683632
            let markdown = "We will never sell your information or use it for advertising. See our [Privacy Policy](\(PRIVACY_POLICY_URL)) for more information."
            Text(.init(markdown))
                .padding(.vertical)
            
            TextField("you@example.com", text: $address, prompt: Text("Email address"))
                .customEmailTextFieldStyle(contentType: .emailAddress, keyboardType: .emailAddress)
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

            Spacer()
            
            AsyncButton(action: submit) {
                Text("Request Code")
            }
            .buttonStyle(BigBlueButtonStyle())
            .disabled(!addressIsValid)
            
        }
        .padding()
        .onReceive(keyboardPublisher) {
            if $0 == 0 {
                self.showingKeyboard = false
            } else {
                self.showingKeyboard = true
            }
        }
    }
}
