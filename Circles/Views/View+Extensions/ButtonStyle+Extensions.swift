//
//  ButtonStyle+Extensions.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/7/24.
//

import SwiftUI

struct BigRoundedButtonStyle: ButtonStyle {
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

struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .foregroundColor(.white)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ReactionsButtonStyle: ButtonStyle {
    var buttonColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], 6)
            .padding([.leading, .trailing], 6)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(buttonColor, lineWidth: 2)
            )
            .background(Color.greyCool400)
            .foregroundColor(.gray)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.65 : 1.0)
    }
}
