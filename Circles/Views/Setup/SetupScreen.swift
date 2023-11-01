//
//  SetupScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/9/22.
//

import SwiftUI

struct SetupScreen: View {

    @ObservedObject var session: SetupSession
    var store: CirclesStore
    
    var body: some View {
        switch session.state {
        case .profile:
            AvatarForm(session: session)
        case .circles(let displayName):
            CirclesForm(session: session, displayName: displayName)
        case .allDone(let config):
            AllDoneForm(store: store, matrix: session.client, config: config)
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
