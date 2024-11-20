//
//  ButtonStyle+Extensions.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/7/24.
//

import SwiftUI

struct BigRoundedButtonStyle: ButtonStyle {
    var width: CGFloat = 300.0
    var height: CGFloat = 40.0
    var color: Color = .accentColor
    var borderWidth: CGFloat = 0
    var textColor: Color = .white
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: borderWidth)
            )
            .foregroundColor(textColor)
            .background(configuration.isPressed ? color.opacity(0.8) : color)
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
                RoundedRectangle(cornerRadius: 10)
                    .stroke(buttonColor, lineWidth: 2)
            )
            .background(Color.greyCool400)
            .foregroundColor(.greyCool1000)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.65 : 1.0)
    }
}
