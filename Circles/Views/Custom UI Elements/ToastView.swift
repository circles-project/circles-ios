//
//  ToastView.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 5/30/24.
//

import SwiftUI
import JDStatusBarNotification


import SwiftUI

struct ToastView: View {
    var message: String
    
    var body: some View {
        Text(message)
            .padding()
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.top, 50)
    }
}

import Combine

class ToastManager: ObservableObject {
    @Published var isShowing = false
    @Published var message = ""
    
    func showToast(message: String) {
        self.message = message
        withAnimation {
            self.isShowing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.isShowing = false
            }
        }
    }
}

/*
#Preview {
    ToastView(message: "My toast",
              style: .simple)
}
*/
