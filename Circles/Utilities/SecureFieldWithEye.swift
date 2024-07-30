//
//  EyeSecureField.swift
//  Circles
//
//  Created by Charles Wright on 8/2/21.
//

import SwiftUI

struct SecureFieldWithEye: View {
    @Binding var password: String
    @State private var isSecure: Bool = true
    @FocusState private var isFocused: Bool
    var isNewPassword: Bool = false
    var placeholder: String = "Password"

    var body: some View {
        HStack {
            if isSecure {
                SecureField(placeholder, text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 40)
                    .focused($isFocused)
                    .textContentType(isNewPassword ? .newPassword : .password)
            } else {
                TextField(placeholder, text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 40)
                    .focused($isFocused)
                    .textContentType(isNewPassword ? .newPassword : .password)
            }
            
            Button(action: {
                isSecure.toggle()
                isFocused = true
            }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(isSecure ? .gray : .blue)
            }
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
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
