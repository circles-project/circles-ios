//
//  View+Extensions.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/6/24.
//

import SwiftUI

struct BigBlueButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(width: 300.0, height: 40.0)
            .foregroundColor(.white)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct CustomEmailTextFieldStyle: ViewModifier {
    var contentType: UITextContentType
    var keyboardType: UIKeyboardType
    
    func body(content: Content) -> some View {
        content
            .textContentType(contentType)
            .keyboardType(keyboardType)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
    }
}

extension View {
    func customEmailTextFieldStyle(contentType: UITextContentType,
                              keyboardType: UIKeyboardType) -> some View {
        self.modifier(CustomEmailTextFieldStyle(contentType: contentType,
                                                keyboardType: keyboardType))
    }
}
