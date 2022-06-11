//
//  SignupStartForm.swift
//  Circles
//
//  Created by Charles Wright on 9/8/21.
//

import SwiftUI
import StoreKit

struct SignupStartForm: View {
    //var matrix: MatrixInterface
    @ObservedObject var session: SignupSession
    var store: CirclesStore
    //@Binding var selectedScreen: LoggedOutScreen.Screen
    var state: UIAA.SessionState

    //@Binding var selectedFlow: UIAA.Flow?

    var body: some View {
        VStack {
            Text("Sign up for Circles")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Spacer()

            let tokenFlow = state.flows.first(where: {
                $0.stages.contains(LOGIN_STAGE_TOKEN_KOMBUCHA) ||
                    $0.stages.contains(LOGIN_STAGE_TOKEN_MATRIX) ||
                    $0.stages.contains(LOGIN_STAGE_TOKEN_MSC3231)
            })
            if tokenFlow != nil {
                Text("Already have a Circles token?")
            } else {
                Label("Token signup is not available at this time.  Please try again later.", systemImage: "exclamationmark.triangle")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            AsyncButton(action: {
                //selectedFlow = tokenFlow
                await session.selectFlow(flow: tokenFlow!)
            }) {
                Text("Sign up with token")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled( nil == tokenFlow )


            Spacer()

            let appleFlow = state.flows.first(where: {
                $0.stages.contains(LOGIN_STAGE_APPLE_SUBSCRIPTION)
            })
            if appleFlow != nil {
                Text("No token?  No problem.")
            } else {
                Label("New paid subscriptions are currently unavailable.  Please try again later.", systemImage: "exclamationmark.triangle")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            AsyncButton(action: {
                //selectedFlow = appleFlow
                await session.selectFlow(flow: appleFlow!)
            }) {
                Text("New Circles subscription")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled( nil == appleFlow || !SKPaymentQueue.canMakePayments() )

            Spacer()
            
            if CIRCLES_DEBUG {
                VStack {
                    if let flows = state.flows {
                        ForEach(flows, id: \.self) { flow in
                            Text("Auth flow:")
                                .font(.body)
                            ForEach(flow.stages, id: \.self) { stage in
                                Text(stage)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }
}

/*
struct SignupStartForm_Previews: PreviewProvider {
    static var previews: some View {
        SignupScreen()
    }
}
*/
