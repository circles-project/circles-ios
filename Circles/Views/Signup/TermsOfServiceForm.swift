//
//  TermsOfServiceForm.swift
//  Circles
//
//  Created by Charles Wright    on 9/7/21.
//

import SwiftUI
import Matrix

struct TermsOfServiceForm: View {
    //var matrix: MatrixInterface
    var session: SignupSession
    //@Binding var selectedScreen: LoggedOutScreen.Screen
    //@Binding var authFlow: UIAA.Flow?

    @State var webViewStore = WebViewStore()

    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    let stage = AUTH_TYPE_TERMS
    
    let langCode = Bundle.main.preferredLocalizations[0]

    var url: URL {
        /*
        let termsparams = matrix.signupGetRequiredTerms()
        let privacyPolicy = termsparams?.policies["privacy"]
        let fallbackUrlString = "https://matrix.kombucha.social/_matrix/consent"
        let url = privacyPolicy?.en?.url ?? URL(string: fallbackUrlString)!
        return url
        */
        let hsURL = session.url
        let fallbackURL = URL(string: "https://\(hsURL.host!)/_matrix/consent")!

        return fallbackURL
    }

    var body: some View {
        VStack {
            //let currentStage: SignupStage = .acceptTermsOfService

            Text("Review terms of service")
                .font(.title)
                .fontWeight(.bold)

            WebView(webView: webViewStore.webView)
                .onAppear {
                    let req = URLRequest(url: self.url)
                    self.webViewStore.webView.load(req)
                }
                .font(.body)

            AsyncButton(action: {
                
                do {
                    try await session.doTermsStage()
                } catch {
                    // Tell the user that we hit an error
                    print("SIGNUP/TERMS\tTerms stage failed")
                    self.alertTitle = "Something went wrong"
                    self.alertMessage = "Failed to complete Terms of Service stage"
                    self.showAlert = true
                }

            }) {
                Text("Got it")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle),
                      message: Text(alertMessage),
                      dismissButton: .cancel(Text("OK"))
                )
            }
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
