//
//  LoginScreen.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 10/30/20.
//

import SwiftUI

struct LoginScreen: View {
    var matrix: MatrixInterface
    @Binding var selectedScreen: LoggedOutScreen.Screen

    @State var username: String = ""
    @State var password: String = ""
    
    var logo: some View {
        RandomizedCircles()
            .clipped()
            .frame(minWidth: 100,
                   idealWidth: 200,
                   maxWidth: 300,
                   minHeight: 100,
                   idealHeight: 200,
                   maxHeight: 300,
                   alignment: .center)
    }
    
    var body: some View {
        VStack(alignment: .center) {
                    
            logo
            
            Text("Kombucha.social")
                .font(.headline)
                .fontWeight(.bold)
            Text("Circles")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Username", text: $username)
                .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                .disableAutocorrection(true)
                .frame(width: 300.0, height: 40.0)

            SecureField("Password", text: $password)
                .frame(width: 300.0, height: 40.0)

            Button(action: {
                self.matrix.login(username: self.username, password: self.password)
            }) {
                Text("Log In")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }

            
            Spacer()
            
            Text("Not a member?")
            Button(action: {
                self.matrix.startNewSignupSession { response in
                    if response.isSuccess {
                        self.selectedScreen = .signup
                    }
                }
            }) {
                Text("Sign Up")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }


        }
        .padding(.horizontal)
    }

}

/*
struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen(matrix: KSStore())
    }
}
*/
