//
//  TermsOfServiceForm.swift
//  Circles
//
//  Created by Charles Wright    on 9/7/21.
//

import SwiftUI
import Matrix
import MarkdownUI

struct TermsOfServicePolicySheet: View {
    var policy: TermsParams.Policy
    @State var content: MarkdownContent?
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        VStack {
            if let content = self.content {
                ScrollView {
                    Text("Review \(policy.en?.name ?? policy.name) (version \(policy.version))")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Markdown(content)
                        //.padding()
                    
                    Button(action: {
                        self.presentation.wrappedValue.dismiss()
                    }) {
                        Text("Got it")
                    }
                    .buttonStyle(BigBlueButtonStyle())
                }
                .padding()
            } else {
                Spacer()
                ProgressView {
                    Text("Loading \(policy.en?.name ?? policy.name)...")
                }
                .onAppear {
                    Task {
                        guard let url = policy.en?.markdownUrl
                        else {
                            // FIXME Set error message
                            return
                        }
                        let request = URLRequest(url: url)
                        let (data, response) = try await URLSession.shared.data(for: request)
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
            } // end else
        } // end VStack
    } // end body
}

struct TermsOfServicePolicyRow: View {
    var policy: TermsParams.Policy
    @State var showSheet = false
    var body: some View {
        Button(action: {
            self.showSheet = true
        }) {
            Label("\(policy.en?.name ?? policy.name) v\(policy.version)", systemImage: "doc.plaintext")
                .padding(5)
        }
        .sheet(isPresented: $showSheet) {
            TermsOfServicePolicySheet(policy: policy)
        }
    }
}

struct TermsOfServiceForm: View {
    var params: TermsParams
    var session: UIAuthSession
    
    @State var accept = false
    
    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    let stage = AUTH_TYPE_TERMS

    var body: some View {
        VStack {
            Text("Review and accept terms")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            VStack(alignment: .leading) {
                ForEach(params.policies, id: \.name) { policy in
                    TermsOfServicePolicyRow(policy: policy)
                }
                .padding(.leading)
            }
            
            Toggle(isOn: $accept) {
                Text("I accept these terms")
            }
            .frame(width: 300)
            .padding(.vertical)
            
            AsyncButton(action: {
                // User has accepted all of the policies
                // Tell the server that we accept its terms
                do {
                    try await session.doTermsStage()
                } catch {
                    // Tell the user that we hit an error
                    print("SIGNUP/TERMS\tTerms stage failed")
                    self.alertTitle = "Oh no! Something went wrong"
                    self.alertMessage = "Failed to complete Terms of Service stage"
                    self.showAlert = true
                }
            }) {
                Text("Accept and Continue")
            }
            .buttonStyle(BigBlueButtonStyle())
            .disabled(accept == false)

            Spacer()
            
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
