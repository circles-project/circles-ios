//
//  ViewModifier+Extensions.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/6/24.
//

import SwiftUI

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
