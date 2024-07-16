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
        VStack {
            CirclesHelpView()
            
            Button(action: {
                stage = .circlesSetup
            }) {
                Text("Next: Set up my circles")
            }
            .buttonStyle(BigRoundedButtonStyle())
            
            Spacer()
        }
    }
}
