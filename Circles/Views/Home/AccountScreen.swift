//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  AccountScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 3/3/21.
//

import SwiftUI
import Matrix

struct AccountScreen: View {
    @ObservedObject var user: Matrix.User
    @Environment(\.presentationMode) var presentation
    
    //@State var emailAddress = ""
    //@State var mobileNumber = ""
    //@State var thirdPartyIds = [MXThirdPartyIdentifier]()
    
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

    @State var newRecoveryPassphrase = ""
    
    var profileSection: some View {
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
                        let _ = Task {
                            try await user.session.setMyAvatarImage(img)
                            self.profileImage = img
                            self.newImage = nil
                        }
                    }
                }
            }

            HStack {
                Text("Name")

                TextField(user.displayName ?? "Name", text: $displayName)
                    .onSubmit {
                        if !displayName.isEmpty {
                            let _ = Task {
                                try await user.session.setMyDisplayName(displayName)
                                self.displayName = ""
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

                TextField("New status", text: $statusMessage)
                    .onSubmit {
                        if !statusMessage.isEmpty {
                            let _ = Task {
                                try await user.session.setMyStatus(message: statusMessage)
                                self.statusMessage = ""
                            }
                        }
                    }
            }

        }
    }
    
    var encryptedBackupSection: some View {
        Section(header: Text("Encrypted Backup")) {
            Text("TBD")
        }
    }
    
    var accountDeletionSection: some View {
        Section(header: Text("Account Deletion")) {
            Text("TBD")
        }
    }
    
    var body: some View {

        Form {

            profileSection

            encryptedBackupSection

            accountDeletionSection

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
