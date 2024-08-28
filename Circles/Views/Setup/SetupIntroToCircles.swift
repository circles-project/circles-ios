//
//  SetupIntroToCircles.swift
//  Circles
//
//  Created by Charles Wright on 5/30/24.
//

import SwiftUI

struct SetupIntroToCircles: View {
    @Binding var stage: SetupScreen.Stage
    
    var body: some View {
        let elementWidth = UIScreen.main.bounds.width - 48
        let elementHeight: CGFloat = 48.0
        ZStack {
            Color.greyCool200
            
            VStack {
                CirclesHelpView()
                
                Button(action: {
                    stage = .circlesSetup
                }) {
                    Text("Next: Set up my circles")
                }
                .buttonStyle(BigRoundedButtonStyle(width: elementWidth, height: elementHeight))
                .font(
                    CustomFonts.nunito16
                        .weight(.bold)
                )
                .padding(.bottom, 38)
            }
        }
    }
}
