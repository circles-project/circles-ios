//
//  TermsOfServiceForm.swift
//  Circles
//
//  Created by Charles Wright    on 9/7/21.
//

import SwiftUI

struct TermsOfServiceForm: View {
    var matrix: MatrixInterface
    //@Binding var selectedScreen: LoggedOutScreen.Screen
    @Binding var authFlow: UiaaAuthFlow?

    @State var webViewStore = WebViewStore()
    @State var pending = false

    let stage = LOGIN_STAGE_TERMS_OF_SERVICE

    var body: some View {
        VStack {
            //let currentStage: SignupStage = .acceptTermsOfService

            Text("Review terms of service")
                .font(.title)
                .fontWeight(.bold)

            WebView(webView: webViewStore.webView)
                .onAppear {
                    let req = URLRequest(url: URL(string: "https://kombucha.social/_matrix/consent")!)
                    self.webViewStore.webView.load(req)
                }
                .font(.body)

            Button(action: {
                self.pending = true
                matrix.signupDoTermsStage { response in
                    if response.isSuccess {
                        // Done with this stage, let's move on to the next
                        //self.stage = next[currentStage]!
                        authFlow?.pop(stage: self.stage)
                    }
                    self.pending = false
                }
            }) {
                Text("Got it")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(pending)
        }
    }
}

/*
struct TermsOfServiceStage_Previews: PreviewProvider {
    static var previews: some View {
        TermsOfServiceStage()
    }
}
*/
