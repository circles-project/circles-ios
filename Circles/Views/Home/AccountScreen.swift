//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  AccountScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 3/3/21.
//

import SwiftUI
import MatrixSDK

struct AccountScreen: View {
    @ObservedObject var user: MatrixUser
    
    @State var emailAddress = ""
    @State var mobileNumber = ""
    
    @State var oldPassword = ""
    @State var newPassword = ""
    @State var repeatPassword = ""
    
    @State var membershipLevel = "Free(Beta)"
    @State var membershipExpiry = Date(timeIntervalSinceNow: TimeInterval(0))
    
    var body: some View {
        Form {
            Section(header: Text("Contact Information")) {
                TextField("Email Address", text: $emailAddress)
                TextField("Mobile Number", text: $mobileNumber)
            }
            Section(header: Text("Password")) {
                TextField("Old Password", text: $oldPassword)
                TextField("New Password", text: $newPassword)
                TextField("Repeat new password", text: $repeatPassword)
            }
            Section(header: Text("Subscription Information")) {
                HStack {
                    Text("Membership Level")
                    Spacer()
                    Text(membershipLevel)
                        .foregroundColor(Color.gray)
                    Image(systemName: "chevron.right")
                }
                HStack {
                    Text("Paid Through")
                    Spacer()
                    Text(membershipExpiry, style: .date)
                        .foregroundColor(Color.gray)
                }
            }
        }
    }
}

/*
struct AccountScreen_Previews: PreviewProvider {
    static var previews: some View {
        AccountScreen()
    }
}
*/
