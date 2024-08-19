//
//  EyeSecureField.swift
//  Circles
//
//  Created by Charles Wright on 8/2/21.
//

import SwiftUI

struct SecureFieldWithEye: View {
    @Binding
    var password: String
    var isNewPassword: Bool = false
    var placeholder: String = "Password"

    @State
    private var showText: Bool = false

    private enum Focus {
        case secure, text
    }

    @FocusState
    private var focus: Focus?

    @Environment(\.scenePhase)
    private var scenePhase

    var body: some View {
        HStack {
            ZStack {
                SecureField(placeholder, text: $password)
                    .focused($focus, equals: .secure)
                    .opacity(showText ? 0 : 1)
                    .textContentType(isNewPassword ? .newPassword : .password)
                TextField(placeholder, text: $password)
                    .focused($focus, equals: .text)
                    .opacity(showText ? 1 : 0)
                    .textContentType(isNewPassword ? .newPassword : .password)
            }

            Button(action: {
                showText.toggle()
            }) {
                Image(systemName: showText ? "eye.slash.fill" : "eye.fill")
            }
        }
        .onChange(of: focus) { newValue in
            // if the PasswordField is focused externally, then make sure the correct field is actually focused
            if newValue != nil {
                focus = showText ? .text : .secure
            }
        }
        .onChange(of: scenePhase) { newValue in
            if newValue != .active {
                showText = false
            }
        }
        .onChange(of: showText) { newValue in
            if focus != nil { // Prevents stealing focus to this field if another field is focused, or nothing is focused
                DispatchQueue.main.async { // Needed for general iOS 16 bug with focus
                    focus = newValue ? .text : .secure
                }
            }
        }
    }
}

/*
struct EyeSecureField_Previews: PreviewProvider {
    static var previews: some View {
        EyeSecureField()
    }
}
*/
