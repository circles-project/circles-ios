//
//  TermsOfServiceForm.swift
//  Circles
//
//  Created by Charles Wright    on 9/7/21.
//

import SwiftUI
import Matrix
import MarkdownUI

struct TermsOfServiceForm: View {
    //var matrix: MatrixInterface
    var params: TermsParams
    var session: UIAuthSession
    //@Binding var selectedScreen: LoggedOutScreen.Screen
    //@Binding var authFlow: UIAA.Flow?
    @State var policies: [TermsParams.Policy]
    @State var accepted: [TermsParams.Policy]
    @State var content: MarkdownContent?
    //@State var webViewStore = WebViewStore()
    
    private var urlSession: URLSession
    
    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    let stage = AUTH_TYPE_TERMS
    
    init(params: TermsParams, session: UIAuthSession) {
        self.params = params
        self.session = session
        
        self.policies = params.policies
        self.urlSession = URLSession(configuration: .default)
        self.accepted = []
    }

    var body: some View {
        VStack {
            //let currentStage: SignupStage = .acceptTermsOfService
            
            if let policy = self.policies.first {
                Text("Review \(policy.name) (\(policy.version))")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let content = self.content {
                    ScrollView {
                        Markdown(content)
                            .padding()
                    }
                } else {
                    Spacer()
                    ProgressView {
                        Text("Loading...")
                    }
                    .onAppear {
                        Task {
                            guard let url = policy.en?.markdownUrl
                            else {
                                // FIXME Set error message
                                return
                            }
                            let request = URLRequest(url: url)
                            let (data, response) = try await urlSession.data(for: request)
                            guard let httpResponse = response as? HTTPURLResponse,
                                  httpResponse.statusCode == 200,
                                  let string = String(data: data, encoding: .utf8)
                            else {
                                // FIXME Set error message
                                return
                            }
                            self.content = MarkdownContent(string)
                        }
                    }
                    Spacer()
                }
                
                AsyncButton(action: {
                    let acceptedPolicy = self.policies.removeFirst()
                    self.accepted.append(acceptedPolicy)
                    self.content = nil
                }) {
                    Text("Got it")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                
            } else {
                Spacer()
                Text("All policies accepted")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                VStack(alignment: .leading) {
                    ForEach(accepted, id: \.name) { policy in
                        Label("\(policy.name) \(policy.version)", systemImage: "checkmark.square")
                            .padding(.vertical, 2)
                    }
                    .padding(.leading)
                }
                AsyncButton(action: {
                    // User has accepted all of the policies
                    // Tell the server that we accept its terms
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
                    Text("Submit")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                Spacer()
            }

        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle),
                  message: Text(alertMessage),
                  dismissButton: .cancel(Text("OK"))
            )
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
