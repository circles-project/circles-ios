//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  LoggedOutScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 3/4/21.
//

import SwiftUI

struct LoggedOutScreen: View {
    var store: KSStore

    @State var uiaaState: UiaaSessionState?

    /*
    enum Screen: String {
        case login
        case signupMain
        case tokenSignup
        case appstoreSignup
        // FIXME Replace .signup with these once we're in the App Store
        //case subscribe
        //case register
    }
    
    @State var screen: Screen = .login
    */
    
    var body: some View {
        /*
        switch screen {
        case .login:
            LoginScreen(matrix: store, selectedScreen: $screen)
        case .signupMain:
            SignupScreen(matrix: store, selectedScreen: $screen)
        case .tokenSignup:
            TokenSignUpScreen(matrix: store, selectedScreen: $screen)
        case .appstoreSignup:
            AppStoreSignUpScreen(matrix: store, selectedScreen: $screen)
        }
        */

        if uiaaState == nil {
            LoginScreen(matrix: store, uiaaState: $uiaaState)
        } else {
            SignupScreen(matrix: store, uiaaState: $uiaaState)
        }

    }
}

struct LoggedOutScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoggedOutScreen(store: KSStore())
    }
}
