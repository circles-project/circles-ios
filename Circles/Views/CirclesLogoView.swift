//
//  CirclesLogoView.swift
//  Circles
//
//  Created by Charles Wright on 11/10/23.
//

import SwiftUI

struct CirclesLogoView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let imageName = colorScheme == .dark ? "circles-logo-dark" : "circles-logo-light"
        BasicImage(name: imageName)
    }
}

#Preview {
    CirclesLogoView()
}
