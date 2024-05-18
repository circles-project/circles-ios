//
//  SignupStartForm.swift
//  Circles
//
//  Created by Charles Wright on 9/8/21.
//

import SwiftUI
import StoreKit
import Matrix

struct SignupStartForm: View {
    //var matrix: MatrixInterface
    @ObservedObject var session: SignupSession
    @AppStorage("debugMode") private var debugMode: Bool = false
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
                .frame(minHeight: 100)

            if let freeFlow = state.flows.first(where: { flow in
                flow.stages.contains(AUTH_TYPE_FREE_SUBSCRIPTION) &&
                    !flow.stages.contains(AUTH_TYPE_GOOGLE_SUBSCRIPTION) &&
                    !flow.stages.contains(AUTH_TYPE_APPSTORE_SUBSCRIPTION)
            }) {
                AsyncButton(action: {
                    //selectedFlow = tokenFlow
                    await session.selectFlow(flow: freeFlow)
                }) {
                    Text("Sign up for free")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
            } else {
                Label("Subscriptionless signup is not available at this time.  Please try again later.", systemImage: "exclamationmark.triangle")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Button(action: {}) {
                    Text("Sign up for free")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .disabled(true)
            }

            Spacer()
                .frame(minHeight: 20)

            let appleFlow = state.flows.first(where: {
                $0.stages.contains(AUTH_TYPE_APPSTORE_SUBSCRIPTION)
            })
            if appleFlow == nil {
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
            
            if debugMode {
                VStack {
                    let flows = state.flows
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

/*
struct SignupStartForm_Previews: PreviewProvider {
    static var previews: some View {
        SignupScreen()
    }
}
*/
