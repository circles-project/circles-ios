//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ProfileScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Matrix

struct ProfileAddEmailView: View {
    @ObservedObject var user: Matrix.User
    @State var email: String = ""
    @State var showValidationSection = false
    @State var token: String = ""
    //@Binding var addresses: [String]
    
    var body: some View {
        Form {
            Section(header: Text("Add New Email Address")) {
            
                TextField("Email Address", text: $email)
                    .autocapitalization(.none)
                    //.multilineTextAlignment(.center)
                    //.textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    self.showValidationSection = true
                }) {
                    Label("Send validation mail", systemImage: "paperplane")
                }
            }
            if showValidationSection {
                Section(header: Text("Validate New Address")) {
                    TextField("Validation Token", text: $token)
                        .autocapitalization(.none)
                    Button(action: {
                        // Contact the server to verify that the token is correct
                        // If it checks out, add the new email address
                        
                    }) {
                        Text("Verify Token")
                    }
                }
            }
        }
    }
}

struct ProfileScreen: View {
    @ObservedObject var user: Matrix.User
    @State var displayName = ""
    @State var statusMessage = ""
    @State var emailAddresses: [String] = [] // FIXME this should come from the MatrixUser
    @State var newEmail = ""
    
    @State var showPicker = false
    @State var newImage: UIImage?
    
    var image: Image {
        if let img = newImage ?? user.avatar {
            return Image(uiImage: img)
        }
        else {
            return Image(systemName: "person.fill")
        }
    }
    
    var body: some View {
       // NavigationView {
            Form {
                Section(header: Text("Public Profile")) {
                    VStack(alignment: .center) {
                        image
                            .resizable()
                            .scaledToFit()
                            //.frame(width: 200, height: 200)
                            //.clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            //.padding(5)
                    }
                    Button(action: {self.showPicker = true}) {
                        Text("Choose Photo")
                    }
                    .sheet(isPresented: $showPicker) {
                        ImagePicker(selectedImage: $newImage) { maybeImg in
                            if let img = maybeImg {
                                let _ = Task {
                                    try await user.session.setMyAvatarImage(img)
                                    self.newImage = nil
                                }
                            }
                        }
                    }
                
                    //TextField("Display Name", text: $displayName)
                    HStack {
                        TextField(text: $displayName, prompt: Text(user.displayName ?? "")) {
                            Text("Name")
                        }
                        .onSubmit {
                            if !displayName.isEmpty {
                                let _ = Task {
                                    try await user.session.setMyDisplayName(displayName)
                                    self.displayName = ""
                                }
                            }
                        }
                        .multilineTextAlignment(.trailing)
                        .disableAutocorrection(true)
                    }
                
                    HStack {
                        TextField(text: $statusMessage, prompt: Text(user.statusMessage ?? "")) {
                            Text("Status message")
                        }
                            .onSubmit {
                                if !statusMessage.isEmpty {
                                    let _ = Task {
                                        try await user.session.setMyStatus(message: statusMessage)
                                        self.statusMessage = ""
                                    }
                                }
                            }

                        .multilineTextAlignment(.trailing)
                    }

                }
                
                /*
                Section(header: HStack{
                    Text("Public Email Addresses")

                }) {
                    ForEach(emailAddresses, id: \.self) { email in
                        HStack {
                            Text(email)
                            Spacer()
                            Button(action: {
                                // FIXME Also actually remove the 3pid
                                self.emailAddresses.removeAll(where: {
                                    $0 == email
                                })
                            }) {
                                Image(systemName: "trash.circle")
                            }
                        }
                    }
                    NavigationLink(destination: ProfileAddEmailView(user: user)) {
                        Label("Add New Email", systemImage: "plus.circle")
                    }
                }
                */
                
            }
            .navigationBarTitle("My Profile", displayMode: .inline)
       // }
    }
}

/*
struct ProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        ProfileScreen()
    }
}
 */
