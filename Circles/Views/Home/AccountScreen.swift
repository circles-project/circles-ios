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
    @State var deactivationPassword = ""

    @State var displayName = ""
    @State var statusMessage = ""

    @State var showPicker = false
    @State var newImage: UIImage?

    @State var profileImage = UIImage(systemName: "person.crop.square")

    var threepidList: some View {
        //TextField("Email Address", text: $emailAddress)
        //TextField("Mobile Number", text: $mobileNumber)
        ForEach(thirdPartyIds, id: \.self) { threePid in
            Text(threePid.address)
        }

    }

    /*
    var profileImage: Image {
        Image(uiImage: user.avatarImage ?? UIImage(systemName: "person.crop.square")!)
    }
    */
    
    var body: some View {

        Form {

            Section(header: Text("Public Profile")) {

                Image(uiImage: profileImage!)
                    .resizable()
                    .scaledToFit()
                    //.frame(width: 200, height: 200)
                    //.clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                Button(action: {
                    self.showPicker = true
                }) {
                    Label("Change photo", systemImage: "person.crop.square")
                }
                .sheet(isPresented: $showPicker) {
                    ImagePicker(selectedImage: $newImage) { maybeImg in
                        if let img = maybeImg {
                            user.matrix.setAvatarImage(image: img) { response in
                                if response.isSuccess {
                                    print("Successfully changed avatar image")
                                    //user.objectWillChange.send()
                                    self.profileImage = img
                                }
                                self.newImage = nil
                            }
                        }
                    }
                }

                HStack {
                    Text("Name")

                    TextField(user.displayName ?? "Name", text: $displayName) { (editing) in
                        if !editing {
                            if !displayName.isEmpty {
                                user.matrix.setDisplayName(name: displayName) { response in
                                    if response.isSuccess {
                                        user.objectWillChange.send()
                                    }
                                    self.displayName = ""
                                }
                            }
                        }
                    }
                    .disableAutocorrection(true)
                }

                HStack {
                    Text("User ID")

                    Text(user.id)
                        .foregroundColor(.gray)
                }

                HStack {
                    Text("Status Message")

                    TextField(user.statusMsg ?? "(none)", text: $statusMessage)  { (editing) in
                        if !editing {
                            if !statusMessage.isEmpty {
                                user.matrix.setStatusMessage(message: statusMessage) { response in
                                    if response.isSuccess {
                                        user.objectWillChange.send()
                                    }
                                    self.statusMessage = ""
                                }
                            }
                        }
                    }
                }

            }

            Section(header: Text("Contact Information")) {
                threepidList
            }

            Section(header: Text("Password")) {
                SecureField("Old Password", text: $oldPassword)
                SecureField("New Password", text: $newPassword)
                SecureField("Repeat new password", text: $repeatPassword)
                Button(action: {
                    // Submit password change to the homeserver
                    user.matrix.changeMyPassword(oldPassword: oldPassword, newPassword: newPassword) { response in
                        if response.isSuccess {
                            self.oldPassword = ""
                            self.newPassword = ""
                            self.repeatPassword = ""
                        }
                    }
                }) {
                    Label("Update my password", systemImage: "key.fill")
                }
                .disabled( oldPassword.isEmpty || newPassword.isEmpty || newPassword != repeatPassword )
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

            Section(header: Text("Account Deletion")) {
                if showConfirmDelete {
                    SecureField("Password", text: $deactivationPassword)

                    Button(action: {

                        user.matrix.deleteMyAccount(password: oldPassword) { response in
                            self.showConfirmDelete = false
                            self.deactivationPassword = ""

                            if response.isSuccess {
                                self.presentation.wrappedValue.dismiss()
                            }
                        }
                    }) {
                        Label("Really deactivate my account", systemImage: "person.fill.xmark")
                    }
                    .disabled(deactivationPassword.isEmpty)
                } else {
                    Button(action: {
                        self.showConfirmDelete = true
                    }) {
                        Label("Deactivate My Account", systemImage: "person.fill.xmark")
                            .foregroundColor(.red)
                    }
                }
                /*
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
                */
            }
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

            self.profileImage = user.avatarImage
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
