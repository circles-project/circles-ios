//
//  ReactionsButtonStyle.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/5/24.
//

import SwiftUI

struct ReactionsButtonStyle: ButtonStyle {
    var buttonColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], 7)
            .padding([.leading, .trailing], 12)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(buttonColor, lineWidth: 2)
            )
            .foregroundColor(.gray)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaleEffect(configuration.isPressed ? 0.65 : 1.0)
    }
}
