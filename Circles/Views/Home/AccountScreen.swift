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
    @Environment(\.presentationMode) var presentation
    
    //@State var emailAddress = ""
    //@State var mobileNumber = ""
    @State var thirdPartyIds = [MXThirdPartyIdentifier]()
    
    @State var oldPassword = ""
    @State var newPassword = ""
    @State var repeatPassword = ""
    
    @State var membershipLevel = "Free(Beta)"
    @State var membershipExpiry = Date(timeIntervalSinceNow: TimeInterval(0))

    @State var showConfirmDelete = false

    var threepidList: some View {
        //TextField("Email Address", text: $emailAddress)
        //TextField("Mobile Number", text: $mobileNumber)
        ForEach(thirdPartyIds, id: \.self) { threePid in
            Text(threePid.address)
        }

    }
    
    var body: some View {
        Form {
            Section(header: Text("Contact Information")) {
                threepidList
            }
            .onAppear {
                user.matrix.get3Pids { response in
                    guard case let .success(maybe3pids) = response else {
                        print("Failed to get 3pids")
                        return
                    }
                    if let tpids = maybe3pids {
                        print("Got \(tpids.count) 3pids from Matrix")
                        self.thirdPartyIds = tpids
                    } else {
                        print("Got no 3pids from the Matrix query")
                    }
                }
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
                Button(action: {
                    self.showConfirmDelete = true
                }) {
                    Text("Deactivate My Account")
                        .foregroundColor(.red)
                }
                .actionSheet(isPresented: $showConfirmDelete) {
                    ActionSheet(title: Text("Confirm Account Deactivation"),
                                message: Text("Do you really want to deactivate your account?\nWARNING: This operation cannot be undone."),
                                buttons: [
                                    .cancel { self.showConfirmDelete = false },
                                    .destructive(Text("Yes, permanently deactivate my account")) {
                                        user.matrix.pause()
                                        // delete account
                                        self.showConfirmDelete = false
                                        self.presentation.wrappedValue.dismiss()
                                    }
                                ]
                    )
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
