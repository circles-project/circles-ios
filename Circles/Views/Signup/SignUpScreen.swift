//  Copyright 2021 Kombucha Digital Privacy Systems LLC
//
//  SignupScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/28/21.
//

import SwiftUI
import MatrixSDK

struct SignupAccountInfo {
    var displayName: String = ""
    var username: String = ""
    var password: String = ""
    var emailAddress: String = ""
    var userId: String = ""
}

struct SignupScreen: View {
    @EnvironmentObject var appStore: AppStoreInterface

    //var matrix: MatrixInterface
    //@Binding var uiaaState: UiaaSessionState?
    @Binding var session: SignupSession?

    @State var selectedFlow: UIAA.Flow?
    @State var creds: MXCredentials?
    @State var emailSessionId: String?

    @State var accountInfo = SignupAccountInfo()

    // And this one is a fake "flow" for the post-signup account setup process
    @State var postSignupFlow = UIAA.Flow(stages: ["avatar", "circles"])
    
    var body: some View {
        VStack {
            if let currentSession = session {
                switch currentSession.state {
                case .notInitialized:
                    ProgressView()
                        .onAppear() {
                            let task = Task {
                                try await currentSession.initialize()
                            }
                        }
                case .initialized(let state):
                    Text("Start screen goes here")
                    SignupStartForm(session: $session, state: state, selectedFlow: $selectedFlow)
                case .inProgress(let state, let flow):
                    // Text("Forms for the various stages go here")
                    if let stage = flow.stages.first {
                        Text("Current stage is \(stage)")
                    } else {
                        // FIXME: Uh oh, looks like we ran out of stages...
                    }
                case .finished:
                    Text("All done!")
                }
            } else {
                ProgressView()
                    .onAppear {
                        self.session = SignupSession(SIGNUP_HOMESERVER_URL)
                    }
            }
        }
    }

    /*
    var body: some View {
        VStack {
            if let flow = selectedFlow {

                if let stage = flow.stages.first {
                    switch stage {
                    case LOGIN_STAGE_TOKEN_KOMBUCHA,
                         LOGIN_STAGE_TOKEN_MATRIX,
                         LOGIN_STAGE_TOKEN_MSC3231:
                        TokenForm(tokenType: stage, session: session, authFlow: $selectedFlow)
                    case LOGIN_STAGE_TERMS_OF_SERVICE:
                        TermsOfServiceForm(session: session, authFlow: $selectedFlow)
                    case LOGIN_STAGE_VERIFY_EMAIL:
                        if emailSessionId != nil {
                            ValidateEmailForm(matrix: matrix, authFlow: $selectedFlow, emailSid: $emailSessionId, accountInfo: $accountInfo, creds: $creds)
                        } else {
                            AccountInfoForm(matrix: matrix, authFlow: $selectedFlow, stage: stage, accountInfo: $accountInfo, emailSid: $emailSessionId)
                        }
                    case LOGIN_STAGE_APPLE_SUBSCRIPTION:
                        AppStoreSubscriptionForm(matrix: matrix, uiaaState: $uiaaState, authFlow: $selectedFlow)
                    default:
                        Text("Stage is [\(stage)]")
                    }
                } else {
                    let stage = postSignupFlow.stages.first
                    switch stage {
                    case "avatar":
                        AvatarForm(matrix: matrix, pseudoFlow: $postSignupFlow)
                    case "circles":
                        CirclesForm(matrix: matrix, displayName: accountInfo.displayName, pseudoFlow: $postSignupFlow)
                    case nil:
                        AllDoneForm(matrix: matrix, userId: accountInfo.userId, uiaaState: $uiaaState)
                    default:
                        Text("Stage is [\(stage ?? "(none)")]")
                    }

                }
                
            } else {
                SignupStartForm(matrix: matrix, uiaaState: $uiaaState, selectedFlow: $selectedFlow)
            }

        }
        .onAppear {
            // Start the process of fetching the App Store products, so that it will be loaded by the time the user decides to tap the App Store button
            if appStore.membershipProducts.isEmpty {
                // Get the productIds from the initial UIAA state
                // Ask the App Store interface to load information on them
                if let params = uiaaState?.params?["org.futo.subscription.apple"] as? AppleSubscriptionParams {
                    let productIds = params.productIds
                    appStore.fetchProducts(matchingIdentifiers: productIds)
                }
            }
        }
    }
     */

}

/*
struct SignupScreen_Previews: PreviewProvider {
    static var previews: some View {
        SignupScreen()
    }
}
*/
