//
//  EyeSecureField.swift
//  Circles
//
//  Created by Charles Wright on 8/2/21.
//

import SwiftUI

struct SecureFieldWithEye: View {
    let label: String
    @Binding var text: String
    @State var showText: Bool = false

    var body: some View {
        HStack {
            if showText {
                TextField(label, text: $text)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                Button(action: {self.showText.toggle()}) {
                    Image(systemName: "eye")
                        .foregroundColor(Color.accentColor)
                }
            } else {
                SecureField(label, text: $text)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                Button(action: {self.showText.toggle()}) {
                    Image(systemName: "eye")
                        .foregroundColor(.gray)
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
