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

    var matrix: MatrixInterface
    //@Binding var selectedScreen: LoggedOutScreen.Screen
    @Binding var uiaaState: UiaaSessionState?

    @State var selectedFlow: UiaaAuthFlow?
    @State var creds: MXCredentials?
    @State var emailSessionId: String?

    @State var accountInfo = SignupAccountInfo()

    // And this one is a fake "flow" for the post-signup account setup process
    @State var postSignupFlow = UiaaAuthFlow(stages: ["avatar", "circles"])

    var body: some View {
        VStack {
            if let flow = selectedFlow {

                if let stage = flow.stages.first {
                    switch stage {
                    case LOGIN_STAGE_SIGNUP_TOKEN:
                        TokenForm(matrix: matrix, authFlow: $selectedFlow)
                    case LOGIN_STAGE_TERMS_OF_SERVICE:
                        TermsOfServiceForm(matrix: matrix, authFlow: $selectedFlow)
                    case LOGIN_STAGE_VERIFY_EMAIL:
                        if emailSessionId != nil {
                            ValidateEmailForm(matrix: matrix, authFlow: $selectedFlow, emailSid: $emailSessionId, accountInfo: $accountInfo, creds: $creds)
                        } else {
                            AccountInfoForm(matrix: matrix, authFlow: $selectedFlow, stage: stage, accountInfo: $accountInfo, emailSid: $emailSessionId)
                        }
                    case LOGIN_STAGE_APPLE_SUBSCRIPTION:
                        AppStoreSubscriptionForm(matrix: matrix, uiaaState: $uiaaState)
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
                if let params = uiaaState?.params?.appStore {
                    appStore.fetchProducts(matchingIdentifiers: params.productIds)
                }
            }
        }
    }
}

/*
struct SignupScreen_Previews: PreviewProvider {
    static var previews: some View {
        SignupScreen()
    }
}
*/
