//
//  EyeSecureField.swift
//  Circles
//
//  Created by Charles Wright on 8/2/21.
//

import SwiftUI

struct EyeSecureField: View {
    let label: String
    @Binding var text: String
    @State var showText: Bool = false

    var body: some View {
        HStack {
            if showText {
                TextField(label, text: $text)
                    .disableAutocorrection(true)
                Button(action: {self.showText.toggle()}) {
                    Image(systemName: "eye.slash")
                        .foregroundColor(.gray)
                }
            } else {
                SecureField(label, text: $text)
                    .disableAutocorrection(true)
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
