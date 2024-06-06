//
//  ViewModifier+Extensions.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/6/24.
//

import SwiftUI

struct CustomTextInButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(width: 300.0, height: 40.0)
            .foregroundColor(.white)
            .background(Color.accentColor)
            .cornerRadius(10)
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
    func customTextInButtonStyle() -> some View {
        self.modifier(CustomTextInButtonStyle())
    }
    
    func customEmailTextFieldStyle(contentType: UITextContentType,
                              keyboardType: UIKeyboardType) -> some View {
        self.modifier(CustomEmailTextFieldStyle(contentType: contentType,
                                                keyboardType: keyboardType))
    }
}
