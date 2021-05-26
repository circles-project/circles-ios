//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  SignUpScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 3/4/21.
//

import SwiftUI
import MatrixSDK
import WebKit

struct SignUpScreen: View {
    var matrix: MatrixInterface
    @Binding var selectedScreen: LoggedOutScreen.Screen
    
    @SceneStorage("signupToken") var signupToken: String = ""
    @State var displayName: String = ""
    @SceneStorage("signupEmail") var emailAddress: String = ""
    @State var username: String = ""
    @State var password: String = ""
    @State var repeatPassword: String = ""
    @State var emailToken: String = ""
    @State var avatarImage: UIImage?

    @State var friendsAvatar: UIImage?
    @State var familyAvatar: UIImage?
    @State var communityAvatar: UIImage?
    
    @State var showPicker = false
    @State var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @State var emailSid = ""
    
    @State var webViewStore = WebViewStore()
    
    @State var showHelpForToken = false
    @State var showHelpForUsername = false
    
    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    
    let helpTextForToken = """
    In order to sign up for the service, every new user must present a valid registration token.

    If you found out about the app from a friend or from a posting online, you should be able to get a signup token from the same source.
    """
    
    let helpTextForTokenFailed = """
    Failed to validate token
    """
    
    let helpTextForEmailCode = """
    We sent a 6-digit code to your email address to validate your account.

    Enter the code here to verify that this address belongs to you.
    """
    
    let helpTextForEmailFailed = """
    We couldn't validate the code that you entered.

    Tap "Try Again" to send another code.
    """
    
    let helpTextForUsername = """
    Your username is how other users on the service will identify you.

    The username must consist of at least 8 characters, including at least two letters [a-z].

    If you like, you can also use the numeric digits [0-9] and/or a few special characters like the dash, underscore, and period or "dot".
    """
    
    let helpTextForPassword = """
    The passphrase must be a phrase of four or more words, with at least 16 characters in total length.  Spaces at the beginning and end are ignored.

    The passphrase must contain at least three spaces between words, and at least one numeric digit [0-9].

    Punctuation characters are good, too, but don't make it *too* complicated.  A passphrase that you can't remember doesn't do you any good.
    """
    
    enum HelpItem: String, Identifiable {
        var id: String {
            return self.rawValue
        }
        
        case signupToken
        case tokenFailed
        case emailCode
        case emailFailed
        case username
        case password
    }
    @State var showHelpItem: HelpItem?
    
    enum SignupStage: String, Identifiable {
        var id: String {
            return self.rawValue
        }
        case validateToken
        case acceptTermsOfService
        case getUsernameAndPassword
        //case getEmail
        case validateEmail
        case getAvatarImage
        case setupCircles
        case allDone
    }
    @State var stage: SignupStage = .validateToken
    
    // XXX ok this is a total kludge but it's cleaner than
    // having the sequencing information spread all over the
    // following View implementations...
    // Who ever heard of a linked list anyway? (sigh)
    var next: [SignupStage: SignupStage] = [
        .validateToken: .acceptTermsOfService,
        .acceptTermsOfService: .getUsernameAndPassword,
        //.getUsernameAndPassword: .getEmail,
        //.getEmail: .validateEmail,
        .getUsernameAndPassword: .validateEmail,
        .validateEmail: .getAvatarImage,
        .getAvatarImage: .setupCircles,
        .setupCircles: .allDone
    ]
    
    var logo: some View {
        RandomizedCircles()
            .clipped()
            .frame(minWidth: 100,
                   idealWidth: 150,
                   maxWidth: 200,
                   minHeight: 100,
                   idealHeight: 150,
                   maxHeight: 200,
                   alignment: .center)
    }
    
    var tokenForm: some View {
        VStack {
            let currentStage: SignupStage = .validateToken
            Text("Step 1: Validate your token")
                .font(.headline)
            
            HStack {
                TextField("abcd-efgh-1234-5678", text: $signupToken)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Spacer()
                Button(action: {showHelpItem = .signupToken}) {
                    Image(systemName: "questionmark.circle")
                }
            }
            .frame(width: 300.0, height: 40.0)
            
            Button(action: {
                if signupToken.isEmpty {
                    return
                }
                // Call out to the server to validate our token
                // If successful, set stage = .getEmail
                matrix.signupDoTokenStage(token: signupToken) { response in
                    switch response {
                    case .failure(let err):
                        print("SIGNUP\tToken stage failed: \(err)")
                        self.showHelpItem = .tokenFailed
                    case .success:
                        self.stage = next[currentStage]!
                    }
                }
            }) {
                Text("Validate Token")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }

            
            if KOMBUCHA_DEBUG {
                Spacer()
                
                Text(matrix.signupGetSessionId() ?? "Error: No signup session")
                    .font(.footnote)
            }
        }
    }
    
    var termsOfServiceForm: some View {
        VStack {
            let currentStage: SignupStage = .acceptTermsOfService

            Text("Step N. Review terms of service")
                .font(.headline)
            WebView(webView: webViewStore.webView)
                .onAppear {
                    let req = URLRequest(url: URL(string: "https://beta.kombucha.social/_matrix/consent")!)
                    self.webViewStore.webView.load(req)
                }
                .font(.body)
            Button(action: {
                matrix.signupDoTermsStage { response in
                    if response.isSuccess {
                        self.stage = next[currentStage]!
                    }
                }
            }) {
                Text("Got it")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }

        }
    }
    
    var validateEmailForm: some View {
        VStack {
            let currentStage: SignupStage = .validateEmail

            Text("Step 3. Validate your email address")
                .font(.headline)
            
            HStack {
                TextField("123456", text: $emailToken)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    //.frame(width: 300.0, height: 40.0)
                Spacer()
                Button(action: {showHelpItem = .emailCode}) {
                    Image(systemName: "questionmark.circle")
                }
            }
            .frame(width: 300.0, height: 40.0)
            
            Button(action: {
                guard !emailToken.isEmpty else {
                    return
                }
                // Call out to the server to validate our email address
                matrix.signupValidateEmailAddress(sid: self.emailSid, token: self.emailToken) { response1 in
                    if response1.isSuccess {
                        // Next we need to do the UIAA stage for the email identity
                        matrix.signupDoEmailStage(username: self.username, password: self.password, sid: self.emailSid) { response2 in
                            switch response2 {
                            case .success(let maybeCreds):
                                print("Email UIAA stage success!")
                                if let creds = maybeCreds {
                                    print("Creds: user id = \(creds.userId!)")
                                    print("Creds: device id = \(creds.deviceId!)")
                                    print("Creds: access token = \(creds.accessToken!)")
                                    
                                    if self.displayName.isEmpty {
                                        self.stage = next[currentStage]!
                                    } else {
                                        matrix.setDisplayName(name: self.displayName) { response in
                                            if response.isSuccess {
                                                self.stage = next[currentStage]!
                                            }
                                        }
                                    }
                                } else {
                                    print("Email UIAA stage succeeded, but registration is not yet complete")
                                }
                            case .failure(let err):
                                print("Email UIAA stage failed")
                            }

                        }
                    } else {
                        print("Email code validation failed")
                    }
                }
            }) {
                Text("Verify Code from Email")
            }
            .padding()
            .frame(width: 300.0, height: 40.0)
            .foregroundColor(.white)
            .background(Color.accentColor)
            .cornerRadius(10)
            
            Button(action: {
                self.stage = .getUsernameAndPassword
            }) {
                Text("Go Back")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.red)
                    //.background(Color.accentColor)
                    .cornerRadius(10)
            }

        }
    }
    
    var usernameAndPasswordForm: some View {
        VStack {
            let currentStage: SignupStage = .getUsernameAndPassword

            Text("Step N. Set up username and password")
                .font(.headline)
            
            Text("Your name and email address")
                .font(.headline)
                .padding(.top)
            
            HStack {
                TextField("Your Name", text: $displayName)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                Spacer()
                Button(action: {
                    self.showAlert = true
                    self.alertTitle = "Name"
                    self.alertMessage = "Your name as you would like it to appear to others"
                }) {
                    Image(systemName: "questionmark.circle")
                }
            }
            .frame(width: 300.0, height: 40.0)
            
            HStack {
                TextField("you@example.com", text: $emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Spacer()
                Button(action: {
                    self.showAlert = true
                    self.alertTitle = "Email Address"
                    self.alertMessage = "Must be a currently valid and active address.  Don't worry -- we will only use this address for security and other alerts about your account.  We don't send spam, and we don't sell your address."
                }) {
                    Image(systemName: "questionmark.circle")
                }
            }
            .frame(width: 300.0, height: 40.0)
            
            Text("Your new acount")
                .font(.headline)
                .padding(.top)
            
            HStack {
                TextField("New Username", text: $username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Spacer()
                Button(action: {showHelpItem = .username}) {
                    Image(systemName: "questionmark.circle")
                }
            }
            .frame(width: 300.0, height: 40.0)

            HStack {
                SecureField("New Passphrase", text: $password)
                Spacer()
                Button(action: {showHelpItem = .password}) {
                    Image(systemName: "questionmark.circle")
                }
            }
            .frame(width: 300.0, height: 40.0)
                
            SecureField("Repeat Passphrase", text: $repeatPassword)
                .frame(width: 300.0, height: 40.0)
            
            Button(action: {
                guard !password.isEmpty,
                      password == repeatPassword,
                      !username.isEmpty else {
                    return
                }
                // Call out to the server to send the verification mail
                matrix.signupRequestEmailToken(email: emailAddress) { response in
                    if case let .success(sid) = response {
                        self.emailSid = sid
                        // If successful, set stage = .validateEmail
                        stage = next[currentStage]!
                    } else {
                        // :( Couldn't validate email
                        print(":( Couldn't send validation email")
                    }
                }
            }) {
                Text("Submit")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(password.isEmpty || password != repeatPassword)

            
        }
    }
    
    var allDoneForm: some View {
        VStack {
            let currentStage: SignupStage = .validateToken

            Text("Registration is complete!")
                .font(.headline)
            
            Spacer()
            
            Button(action: {
                //self.selectedScreen = .login
                matrix.finishSignupAndConnect()
            }) {
                Text("Next: Log in")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }

            
            Spacer()
        }
    }
    
    var avatar: Image {
        if let img = self.avatarImage {
            return Image(uiImage: img)
        } else {
            return Image(systemName: "person.crop.square")
        }
    }
    
    var avatarForm: some View {
        VStack {
            let currentStage: SignupStage = .getAvatarImage
            
            Text("Upload a profile photo")
                .font(.headline)
                .fontWeight(.bold)
            
            avatar
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 160, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Button(action: {
                self.showPicker = true
                self.pickerSourceType = .photoLibrary
            }) {
                Label("Choose a photo from my device's library", systemImage: "photo.fill")
            }

            Button(action: {
                self.showPicker = true
                self.pickerSourceType = .camera
            }) {
                Label("Take a new photo", systemImage: "camera")
            }
            
            Spacer()
            
            Button(action: {
                // Upload the image and set it as our avatar
                if let img = self.avatarImage {
                    self.matrix.setAvatarImage(image: img) { response in
                        if response.isSuccess {
                            self.stage = next[currentStage]!
                        }
                    }
                }
            }) {
                Text("Next")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }

        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(selectedImage: $avatarImage,
                        sourceType: self.pickerSourceType)
        }
    }
    
    var circlesForm: some View {
        ScrollView {
            let currentStage: SignupStage = .setupCircles
            VStack(alignment: .center) {
                Text("Setup your circles")
                Divider()
                
                // FIXME lol what's a ForEach?
                // But seriously it's unreasonably difficult to
                // iterate over a Dictionary containing bindings.
                // So, sigh, f*** it.  We can do it the YAGNI way.
                SetupCircleCard(matrix: matrix, circleName: "Friends", userDisplayName: self.displayName, avatar: self.$friendsAvatar)
                Divider()
                
                SetupCircleCard(matrix: matrix, circleName: "Family", userDisplayName: self.displayName, avatar: self.$familyAvatar)
                Divider()
                
                SetupCircleCard(matrix: matrix, circleName: "Community", userDisplayName: self.displayName, avatar: self.$communityAvatar)
                Divider()
                                
                Spacer()
                
                Button(action: {                    
                    // Create all the Rooms for the Circles
                    // After we create each one, set its avatar
                    
                    var dgroup = DispatchGroup()
                    var error: Error?
                    
                    dgroup.enter()
                    let friendsId = SocialCircle.randomId()
                    let friendsTag = "social.kombucha.circles.\(friendsId)"
                    self.createCircleRoom(name: "Friends", tag: friendsTag, avatar: self.friendsAvatar) { response in
                        if response.isFailure {
                            error = error ?? KSError(message: "Failed to create circle \"Friends\"")
                        }
                        dgroup.leave()
                    }
                    
                    dgroup.enter()
                    let familyId = SocialCircle.randomId()
                    let familyTag = "social.kombucha.circles.\(familyId)"
                    self.createCircleRoom(name: "Family", tag: familyTag, avatar: self.familyAvatar) { response in
                        if response.isFailure {
                            error = error ?? KSError(message: "Failed to create circle \"Family\"")
                        }
                        dgroup.leave()
                    }
                    
                    dgroup.enter()
                    let communityId = SocialCircle.randomId()
                    let communityTag = "social.kombucha.circles.\(communityId)"
                    self.createCircleRoom(name: "Community", tag: communityTag, avatar: self.communityAvatar) { response in
                        if response.isFailure {
                            error = error ?? KSError(message: "Failed to create circle \"Community\"")
                        }
                        dgroup.leave()
                    }
                    
                    dgroup.notify(queue: .main) {
                        guard error == nil else {
                            print("SETUP\tNotify: There were problems; Not saving circles")
                            return
                        }
                        
                        let data = [familyId: "Family",
                                    friendsId: "Friends",
                                    communityId: "Community"]
                        matrix.setAccountData(data, for: EVENT_TYPE_CIRCLES) { response in
                            if response.isSuccess {
                                print("SETUP\tSaved circles data")
                                self.stage = next[currentStage]!
                            }
                        }
                    }
                    
                }) {
                    Text("Next")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                
            }
            .padding()
        }
    }
    
    private func createCircleRoom(name: String, tag: String, avatar: UIImage?, completion: @escaping (MXResponse<Void>)->Void) {
        matrix.createRoom(name: name, with: tag, insecure: false) { response1 in
            switch response1 {
            case .failure(let err):
                print("SETUP\tFailed to create a room for circle \(name)")
                completion(.failure(err))
            case .success(let roomId):
                print("SETUP\tCreated room \(roomId) for circle \(name)")

                matrix.addTag(ROOM_TAG_OUTBOUND, toRoom: roomId) { response2 in
                    if response2.isFailure {
                        let msg = "Failed to add outbound tag for circle \(name)"
                        print("SETUP\t\(msg)")
                        let err = KSError(message: msg)
                        completion(.failure(err))
                    } else {
                        print("SETUP\tAdded outbound tag for circle \(name)")
                        
                        if let image = avatar {
                            matrix.setRoomAvatar(roomId: roomId, image: image) { response3 in
                                if response3.isFailure {
                                    let msg = "Failed to set avatar for circle \(name)"
                                    print("SETUP\t\(msg)")
                                    let err = KSError(message: msg)
                                    completion(.failure(err))
                                } else {
                                    print("SETUP\tSet avatar for circle \(name)")
                                    completion(.success(()))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // Pyramid of DOOOOOOOM
    
    var body: some View {
        VStack {
            logo
        
            Text("Sign Up")
                .font(.title)
                .fontWeight(.bold)
            
            switch stage {
            case .validateToken:
                tokenForm
            case .acceptTermsOfService:
                termsOfServiceForm
            case .getUsernameAndPassword:
                usernameAndPasswordForm
            case .validateEmail:
                validateEmailForm
            case .getAvatarImage:
                avatarForm
            case .setupCircles:
                circlesForm
            case .allDone:
                allDoneForm
            }
            
            Spacer()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(self.alertTitle),
                  message: Text(self.alertMessage),
                  dismissButton: .default(Text("OK"))
            )
        }
        /*
        .alert(item: $showHelpItem) { item in
            switch item {
            case .signupToken:
                return Alert(title: Text("Signup Token"),
                      message: Text(helpTextForToken),
                      dismissButton: .default(Text("OK"))
                )
            case .tokenFailed:
                return Alert(title: Text("Token Failure"),
                      message: Text(helpTextForTokenFailed),
                      dismissButton: .default(Text("OK"))
                )
            case .emailCode:
                return Alert(title: Text("Email Code"),
                             message: Text(helpTextForEmailCode),
                             dismissButton: .default(Text("OK"))
                )
            case .emailFailed:
                return Alert(title: Text("Email Validation Failed"),
                      message: Text(helpTextForEmailFailed),
                      dismissButton: .default(Text("OK"))
                )
            case .username:
                return Alert(title: Text("Username"),
                      message: Text(helpTextForUsername),
                      dismissButton: .default(Text("OK"))
                )
            case .password:
                return Alert(title: Text("Passphrase"),
                      message: Text(helpTextForPassword),
                      dismissButton: .default(Text("OK"))
                )
            }
        }
        */
    }
}

/*
struct SignUpScreen_Previews: PreviewProvider {
    static var previews: some View {
        SignUpScreen()
    }
}
*/
