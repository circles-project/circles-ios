//
//  DeactivateAccountCustomAlertView.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 5/21/24.
//

import SwiftUI

struct CustomAlertModel {
    let userId: String
    let title: String
    let message: String
}

struct CustomAlertView: View {
    @State private var text = ""
    var model: CustomAlertModel
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack {
            Text(model.title)
                .font(.headline)
            Text(model.message)
                .font(.subheadline)
            TextField(model.userId, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                        
            AsyncButton(role: .destructive, action: {
                onConfirm()
            }) {
                Text("Permanently deactivate")
            }
            .disabled(text != model.userId)
            
            Button("Cancel") {
                onCancel()
            }
            .padding()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding(.horizontal, 60)
    }
}
