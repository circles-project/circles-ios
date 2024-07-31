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
    var screenWidthWithOffsets: CGFloat = 0
    @State var content: MarkdownContent?
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        let color = Color.white
        VStack {
            if let content = self.content {
                VStack {
                    ScrollView {
                        Text("Review \(policy.en?.name ?? policy.name) (version \(policy.version))")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom)
                        
                        Markdown(content)
                        //.padding()
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .background(color)
                    
                    VStack {
                        Button(action: {
                            self.presentation.wrappedValue.dismiss()
                        }) {
                            Text("Accept")
                        }
                        .buttonStyle(BigRoundedButtonStyle(width: screenWidthWithOffsets, height: 48))
                        
                        Button(action: {
                            self.presentation.wrappedValue.dismiss()
                        }) {
                            Text("Reject")
                        }
                        .buttonStyle(BigRoundedButtonStyle(width: screenWidthWithOffsets, height: 48, color: color, textColor: .black))
                    }
                    .frame(width: screenWidthWithOffsets + 48, height: 109)
                    .background(color)
                    .padding(.bottom, 0)
                }
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

struct TermsOfServiceForm: View {
    enum DocumentToShow {
        case privacyPolicy
        case termAndConditions
    }
    
    var params: TermsParams
    var session: UIAuthSession
    
    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    @State var isPrivacyPolicyShown = false
    @State var isTermAndConditionsShown = false
    
    func customViewWith(title: String,
                        version: String,
                        screenWidth: CGFloat,
                        document: DocumentToShow) -> some View {
        HStack {
            Image(SystemImages.page.rawValue)
                .frame(width: 23.2, height: 29)
                .padding(.leading, 20)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(
                        CustomFonts.nunito14
                            .weight(.heavy)
                    )
                    .foregroundColor(Color.greyCool1100)
                
                Text(version)
                    .font(CustomFonts.outfit11)
                    .foregroundColor(Color.greyCool800)
            }
            
            Spacer()
            
            Image(SystemImages.acceptedCircle.rawValue)
                .frame(width: 28, height: 28)
            
            Button {
                switch document {
                case .privacyPolicy: isPrivacyPolicyShown = true
                case .termAndConditions: isTermAndConditionsShown = true
                }
            } label: {
                Text("")
                Image(SystemImages.forwardArrow.rawValue)
            }
            .frame(width: 48, height: 48)
            .padding(.trailing, 20)
        }
        .frame(width: screenWidth, height: 61.0)
        .background(Color.white)
    }
    
    var body: some View {
        let policies = params.policies
        let screenWidthWithOffsets = UIScreen.main.bounds.width - 48
        
        VStack(alignment: .leading) {
            Text("Read and agree to the terms")
                .font(
                    CustomFonts.nunito20
                        .weight(.heavy)
                )
                .foregroundColor(Color.greyCool1100)
                .padding(.top, 85)
            
            Text("Please read our Privacy Policy and Terms & Conditions carefully. By agreeing to these terms, you ensure a secure and enjoyable experience on our platform.")
                .font(
                    CustomFonts.nunito14
                        .weight(.semibold)
                )
                .foregroundColor(Color.greyCool900)
                .frame(width: screenWidthWithOffsets, alignment: .topLeading)
            
            customViewWith(title: "Privacy Policy",
                           version: "v 1.3",
                           screenWidth: screenWidthWithOffsets,
                           document: .privacyPolicy)
            customViewWith(title: "Terms & Conditions",
                           version: "v 1.3",
                           screenWidth: screenWidthWithOffsets,
                           document: .termAndConditions)
            Spacer()
            Text("Please take a moment to read our Privacy Policy and Terms & Conditions. These documents explain how we handle your data and the rules for using our app, ensuring a safe and transparent experience for all users.")
                .font(
                    CustomFonts.nunito12
                        .weight(.medium)
                )
                .foregroundColor(Color.greyCool800)
                .frame(width: screenWidthWithOffsets, alignment: .leading)
                        
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
                    .foregroundStyle(Color.white)
            }
            .frame(width: screenWidthWithOffsets, height: 48)
            .background(Color.accentColor)
            .cornerRadius(8)
            .font(
                CustomFonts.nunito16
                    .weight(.bold)
            )
            .padding(.top, 27)
            .padding(.bottom, 38)
            .sheet(isPresented: $isPrivacyPolicyShown) {
                TermsOfServicePolicySheet(policy: policies[0],
                                          screenWidthWithOffsets: screenWidthWithOffsets)
            }
            .sheet(isPresented: $isTermAndConditionsShown) {
                TermsOfServicePolicySheet(policy: policies[1],
                                          screenWidthWithOffsets: screenWidthWithOffsets)
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
