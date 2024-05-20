//
//  Color+background.swift
//  Circles
//
//  Created by Charles Wright on 4/13/23.
//

import Foundation

import SwiftUI

// https://stackoverflow.com/q/60672626
public extension Color {

    #if os(macOS)
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
    static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    #endif
}

extension Color {
    func randomColor(from name: String) -> Color {
        let colorChoice: Int = name.chars.reduce(0, { acc, str in
            guard let asciiValue = Character(str).asciiValue
            else {
                return acc
            }
            
            return acc + Int(asciiValue)
        })
        
        let colors = CIRCLES_COLORS
        return colors[colorChoice % colors.count]
    }
}
