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

// From our Figma design
extension Color {
    static let base_000 = Color(hex: "#FFFFFF")
    static let grey100 = Color(hex: "#F7F8F9")
    static let grey200 = Color(hex: "#EFF1F3")
    static let grey300 = Color(hex: "#E8EAEE")
    static let grey400 = Color(hex: "#DEE1E6")
    static let grey500 = Color(hex: "#BFC6CF")
    static let grey600 = Color(hex: "#A2ACBA")
    static let grey700 = Color(hex: "#8692A4")
    static let grey800 = Color(hex: "#69788F")
    static let grey900 = Color(hex: "#525F72")
    static let grey1000 = Color(hex: "#3E4856")
    static let grey1100 = Color(hex: "#2A303A")
    static let grey1200 = Color(hex: "#181B21")
    static let primary100 = Color(hex: "#4D1FBF")
    static let primary200 = Color(hex: "#F3EEFF")
    static let primary300 = Color(hex: "#EEE7FF")
    static let primary400 = Color(hex: "#E7DDFF")
    static let primary500 = Color(hex: "#CFBCFF")
    static let primary600 = Color(hex: "#B79AFF")
    static let primary700 = Color(hex: "#A079FF")
    static let primary800 = Color(hex: "#8553FF")
    static let primary900 = Color(hex: "#6528FA")
    static let primary1000 = Color(hex: "#351583")
    static let primary1200 = Color(hex: "#1F0C4D")
    static let orange100 = Color(hex: "#FFF7F5")
    static let orange200 = Color(hex: "#FFEDE7")
    static let orange300 = Color(hex: "#FFDACE")
    static let orange400 = Color(hex: "#FFB49B")
    static let orange500 = Color(hex: "#FF8B64")
    static let orange600 = Color(hex: "#FF8B64")
    static let orange700 = Color(hex: "#E66D44")
    static let orange800 = Color(hex: "#BD5A38")
    static let orange900 = Color(hex: "#96472D")
    static let orange1000 = Color(hex: "#713622")
    static let orange1100 = Color(hex: "#4D2517")
    static let orange1200 = Color(hex: "#2B150D")
    static let yellow100 = Color(hex: "#FFF9E7")
    static let yellow200 = Color(hex: "#FFF0C8")
    static let yellow300 = Color(hex: "#FFEAB1")
    static let yellow400 = Color(hex: "#FFDF86")
    static let yellow500 = Color(hex: "#FBBB0C")
    static let yellow600 = Color(hex: "#D9A20A")
    static let yellow700 = Color(hex: "#B98909")
    static let yellow800 = Color(hex: "#977107")
    static let yellow900 = Color(hex: "#785906")
    static let yellow1000 = Color(hex: "#221A02")
    static let yellow1200 = Color(hex: "#221A02")
    static let success100 = Color(hex: "#E8FEE5")
    static let success200 = Color(hex: "#CCFEC4")
    static let success300 = Color(hex: "#B0FDA4")
    static let success400 = Color(hex: "#8DF97D")
    static let success500 = Color(hex: "#7CDB6D")
    static let success600 = Color(hex: "#6CBD5F")
    static let success700 = Color(hex: "#5BA150")
    static let success800 = Color(hex: "#4B8442")
    static let success900 = Color(hex: "#3B6834")
    static let success1000 = Color(hex: "#2D4F28")
    static let success1100 = Color(hex: "#1E351B")
    static let success1200 = Color(hex: "#111E0F")
    
    // From the color sheets in Figma
    static let greyCool100 = Color(
        light: Color(red: 0.97, green: 0.97, blue: 0.98),
        dark: Color(red: 0.04, green: 0.04, blue: 0.04)
    )
    static let greyCool200 = Color(
        light: Color(red: 0.94, green: 0.95, blue: 0.95),
        dark: Color(red: 0.07, green: 0.07, blue: 0.08)
    )
    static let greyCool300 = Color(
        light: Color(red: 0.91, green: 0.92, blue: 0.93),
        dark: Color(red: 0.09, green: 0.1, blue: 0.11)
    )
    static let greyCool400 = Color(
        light: Color(red: 0.88, green: 0.88, blue: 0.89),
        dark: Color(red: 0.12, green: 0.13, blue: 0.15)
    )
    static let greyCool500 = Color(
        light: Color(red: 0.76, green: 0.78, blue: 0.80),
        dark: Color(red: 0.2, green: 0.21, blue: 0.24)
    )
    static let greyCool600 = Color(
        light: Color(red: 0.66, green: 0.67, blue: 0.71),
        dark: Color(red: 0.27, green: 0.28, blue: 0.32)
    )
    static let greyCool700 = Color(
        light: Color(red: 0.55, green: 0.57, blue: 0.61),
        dark: Color(red: 0.35, green: 0.36, blue: 0.41)
    )
    static let greyCool800 = Color(
        light: Color(red: 0.41, green: 0.47, blue: 0.56),
        dark: Color(red: 0.43, green: 0.45, blue: 0.51)
    )
    static let greyCool900 = Color(
        light: Color(red: 0.35, green: 0.37, blue: 0.42),
        dark: Color(red: 0.54, green: 0.56, blue: 0.60)
    )
    static let greyCool1000 = Color(
        light: Color(red: 0.24, green: 0.28, blue: 0.34),
        dark: Color(red: 0.66, green: 0.67, blue: 0.71)
    )
    static let greyCool1100 = Color(
        light: Color(red: 0.16, green: 0.19, blue: 0.23),
        dark: Color(red: 0.8, green: 0.8, blue: 0.82)
    )
    static let greyCool1200 = Color(
        light: Color(red: 0.10, green: 0.11, blue: 0.12),
        dark: Color(red: 0.91, green: 0.91, blue: 0.92)
    )

    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = scanner.string.startIndex
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

