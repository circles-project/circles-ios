//
//  SetupScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/9/22.
//

import SwiftUI
import Matrix

struct SetupScreen: View {
    var store: CirclesStore
    @ObservedObject var matrix: Matrix.Session
    
    @State var displayName: String?
    
    var body: some View {
        
        if let name = displayName {
            CirclesForm(store: store, matrix: matrix, displayName: name)
        } else {
            AvatarForm(matrix: matrix, displayName: $displayName)
        }
    }
}

/*
struct SetupScreen_Previews: PreviewProvider {
    static var previews: some View {
        SetupScreen()
    }
}
*/
