//
//  ButtonStyle+Extensions.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/7/24.
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
