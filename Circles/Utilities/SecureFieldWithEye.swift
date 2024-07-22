//
//  EyeSecureField.swift
//  Circles
//
//  Created by Charles Wright on 8/2/21.
//

import SwiftUI

private struct KeyboardControllableTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    var isSecure: Bool
    var placeholder: String
    var isNewPassword: Bool = false
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: KeyboardControllableTextField
        
        init(_ parent: KeyboardControllableTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFirstResponder = true
            }
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFirstResponder = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.text = text
        textField.isSecureTextEntry = isSecure
        textField.borderStyle = .roundedRect
        textField.returnKeyType = .done
        textField.placeholder = placeholder
        textField.textContentType = isNewPassword ? .newPassword : .password
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChangeSelection(_:)), for: .editingChanged)
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        DispatchQueue.main.async {
            uiView.text = text
            uiView.isSecureTextEntry = isSecure
            if isFirstResponder {
                uiView.becomeFirstResponder()
            } else {
                uiView.resignFirstResponder()
            }
        }
    }
}

struct SecureFieldWithEye: View {
    let label: String
    var isNewPassword: Bool = false
    var height: CGFloat = 40.0
    @Binding var text: String
    @State var showText: Bool = false
    @State private var isSecure: Bool = true
    @State var isFirstResponder: Bool = true

    var body: some View {
        HStack {
            KeyboardControllableTextField(text: $text,
                                          isFirstResponder: $isFirstResponder,
                                          isSecure: isSecure,
                                          placeholder: label,
                                          isNewPassword: isNewPassword)
            .frame(height: height)
            
            Button(action: {
                isSecure.toggle()
                isFirstResponder = true
            }) {
                Image(systemName: self.isSecure ? SystemImages.eyeSlashFill.rawValue : SystemImages.eyeFill.rawValue)
                    .foregroundColor(self.isSecure ? .gray : .blue)
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
