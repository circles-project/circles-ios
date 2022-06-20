//
//  SetupScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/9/22.
//

import SwiftUI

struct SetupScreen: View {
    /*
    var creds: MatrixCredentials
    */
    @ObservedObject var session: SetupSession
    var store: CirclesStore
    
    var body: some View {
        switch session.state {
        case .profile:
            AvatarForm(session: session)
        case .circles:
            CirclesForm(session: session, displayName: session.displayName)
        case .allDone:
            AllDoneForm(store: store, userId: session.creds.userId)
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
