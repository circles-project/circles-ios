//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  TermsScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/19/21.
//

import SwiftUI
import WebKit
import MatrixSDK

struct TermsScreen: View {
    @ObservedObject var store: KSStore
    var terms: MXServiceTerms
    @StateObject var webViewStore = WebViewStore()
    @State var toReview: [MXLoginPolicyData] = []
    @State var acceptedTermsURLs: [String] = []
    @State var toAccept: [MXLoginPolicyData] = []
    
    var body: some View {
        VStack {
            Text("Review Terms or Service")
                .font(.title)
                .fontWeight(.bold)
            /*
            if !policiesToReview.isEmpty {
                VStack(alignment: .leading) {
                    ForEach(policiesToReview, id: \.self) { policyData in
                        let name = policyData.name
                        let url = policyData.url
                        HStack {
                            Text(name)
                            Text(url)
                        }
                    }
                }
            }
            */
            if let policy = toReview.first {
                WebView(webView: webViewStore.webView)
                    .onAppear {
                        let req = URLRequest(url: URL(string: policy.url)!)
                        self.webViewStore.webView.load(req)
                    }
                HStack {
                    /*
                    Spacer()
                    Button(action: {}) {
                        Label("Decline", systemImage: "xmark")
                            .foregroundColor(Color.red)
                    }
                    Spacer()
                    */
                    Button(action: {
                        toAccept.append(policy)
                        toReview.removeAll(where: {
                            $0.url == policy.url
                        })
                        print("Accepted \(policy.name)")
                        if let newPolicy = toReview.first {
                            let req = URLRequest(url: URL(string: newPolicy.url)!)
                            self.webViewStore.webView.load(req)
                        }
                        else {
                            // Submit all the accepted terms to the server
                            store.acceptTerms(urls: toAccept.map { $0.url }) { response in
                                if response.isSuccess {
                                    print("Successfully accepted terms")
                                }
                            }
                        }
                    }) {
                        //Text("Accept")
                        Label("Accept and Continue", systemImage: "checkmark")
                    }
                    //Spacer()
                }
                .padding()
            } else {
                Spacer()
                VStack(alignment: .leading) {
                    ForEach(toAccept, id: \.self) { policy in
                        HStack {
                            Text(policy.name)
                            Spacer()
                            Image(systemName: "checkmark.rectangle.fill")
                                .foregroundColor(Color.green)
                        }
                        .font(.headline)
                        .padding(.horizontal, 20)
                    }
                }
                Spacer()
                Button(action: {}) {
                    Text("Accept \(toAccept.count) service agreements")
                }
                Spacer()
            }
            
        }
        .onAppear {
            self.terms.terms( {maybeTerms, maybeAccepted in
                guard let policies = maybeTerms?.policies else {
                    return
                }
                for (id, policy) in policies {
                    print("TERMS\tGot policy \(id) version \(policy.version)")
                    let lang = "en"
                    if let policyData = policy.data[lang] {
                        self.toReview.append(policyData)
                    }
                }
                self.acceptedTermsURLs = maybeAccepted ?? []
                print("TERMS\tGot \(acceptedTermsURLs.count) accepted terms")
                for acceptedURL in acceptedTermsURLs {
                    print("TERMS\tAlready accepted \(acceptedURL)")
                }
            },
            failure: { err in
                
            })
        }
    }
}

/*
struct AcceptTermsScreen_Previews: PreviewProvider {
    static var previews: some View {
        AcceptTermsScreen()
    }
}
*/
