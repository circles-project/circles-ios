//
//  UiaView.swift
//  Circles
//
//  Created by Charles Wright on 6/22/23.
//

import SwiftUI
import Matrix

struct UiaView: View {
    var session: CirclesSession
    //var matrix: Matrix.Session
    @ObservedObject var uia: UIAuthSession
    
    var body: some View {
        VStack {
            Text("Authentication Required")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            Spacer()
            
            AsyncButton(action: {
                try await session.cancelUIA()
            }) {
                Text("Cancel")
            }
            .padding()
        }
    }
}

/*
struct UiaView_Previews: PreviewProvider {
    static var previews: some View {
        UiaView()
    }
}
*/
