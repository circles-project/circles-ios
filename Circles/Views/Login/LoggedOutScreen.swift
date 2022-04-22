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

    @State var signupSession: SignupSession?
    
    var body: some View {

        if let session = signupSession {
            SignupScreen(session: $signupSession)
        } else {
            LoginScreen(matrix: store, signupSession: $signupSession)
        }

    }
}

struct LoggedOutScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoggedOutScreen(store: KSStore())
    }
}
