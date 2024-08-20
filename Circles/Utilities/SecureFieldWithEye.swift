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
    var height: CGFloat = 40

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
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: height)
                    .focused($focus, equals: .secure)
                    .opacity(showText ? 0 : 1)
                    .textContentType(isNewPassword ? .newPassword : .password)
                
                TextField(placeholder, text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: height)
                    .focused($focus, equals: .text)
                    .opacity(showText ? 1 : 0)
                    .textContentType(isNewPassword ? .newPassword : .password)
            }

            Button(action: {
                showText.toggle()
            }) {
                Image(systemName: showText ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(showText ? .gray : .blue)
            }
        }
        .onChange(of: focus) { newValue in
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
            if focus != nil {
                DispatchQueue.main.async {
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
