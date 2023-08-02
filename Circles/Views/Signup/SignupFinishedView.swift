//
//  SignupFinishedView.swift
//  Circles
//
//  Created by Charles Wright on 8/1/23.
//

import SwiftUI
import Matrix

struct SignupFinishedView: View {
    var store: CirclesStore
    var creds: Matrix.Credentials
    
    var body: some View {
        VStack {
            Spacer()
            Text("Successfully signed up!")
                .font(.headline)
            
            AsyncButton(action: {
                do {
                    print("Doing nothing because we don't have the SSSS key here")
                    //try await store.beginSetup(creds: creds)
                } catch {
                    
                }
            }) {
                Text("Next: Set Up")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            Spacer()
        }
    }
}
