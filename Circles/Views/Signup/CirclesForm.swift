//
//  CirclesForm.swift
//  Circles
//
//  Created by Charles Wright on 9/7/21.
//

import SwiftUI
import MatrixSDK

struct CirclesForm: View {
    var matrix: MatrixInterface

    @Binding var displayName: String

    @State var friendsAvatar: UIImage?
    @State var familyAvatar: UIImage?
    @State var communityAvatar: UIImage?

    @State var showPicker = false
    @State var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary

    @State var pending = false

    var body: some View {
        VStack(alignment: .center) {
            //let currentStage: SignupStage = .setupCircles

            Text("Setup your circles")
                .font(.title)
                .fontWeight(.bold)

            Divider()

            VStack(alignment: .leading) {
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
            }

            Label("NOTE: Circle names and cover images are not encrypted", systemImage: "exclamationmark.shield")
                .font(.headline)
                .foregroundColor(.orange)

            Spacer()

            Button(action: {
                // Create all the Rooms for the Circles
                // After we create each one, set its avatar

                self.pending = true

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
                        self.pending = false
                        return
                    }

                    let data = [familyId: "Family",
                                friendsId: "Friends",
                                communityId: "Community"]
                    matrix.setAccountData(data, for: EVENT_TYPE_CIRCLES) { response in
                        if response.isSuccess {
                            print("SETUP\tSaved circles data")
                            //self.stage = next[currentStage]!
                        }
                        self.pending = false
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
            .disabled(pending)

        }
        .padding()
    }

    private func createCircleRoom(name: String, tag: String, avatar: UIImage?, completion: @escaping (MXResponse<Void>)->Void) {
        matrix.createRoom(name: name, type: ROOM_TYPE_CIRCLE, tag: tag, insecure: false) { response1 in
            switch response1 {
            case .failure(let err):
                print("SETUP\tFailed to create a room for circle \(name)")
                completion(.failure(err))
            case .success(let roomId):
                print("SETUP\tCreated room \(roomId) for circle \(name)")

                matrix.setRoomType(roomId: roomId, roomType: ROOM_TYPE_CIRCLE) { response2 in

                    if response2.isFailure {
                        let msg = "Failed to set room type for circle \(name)"
                        let err = KSError(message: msg)
                        completion(.failure(err))
                    }
                    else {
                        matrix.addTag(ROOM_TAG_OUTBOUND, toRoom: roomId) { response3 in
                            if response3.isFailure {
                                let msg = "Failed to add outbound tag for circle \(name)"
                                print("SETUP\t\(msg)")
                                let err = KSError(message: msg)
                                completion(.failure(err))
                            } else {
                                print("SETUP\tAdded outbound tag for circle \(name)")

                                if let image = avatar {
                                    matrix.setRoomAvatar(roomId: roomId, image: image) { response4 in
                                        if response4.isFailure {
                                            let msg = "Failed to set avatar for circle \(name)"
                                            print("SETUP\t\(msg)")
                                            let err = KSError(message: msg)
                                            completion(.failure(err))
                                        } else {
                                            print("SETUP\tSet avatar for circle \(name)")
                                            completion(.success(()))
                                        }
                                    }
                                } else {
                                    completion(.success(()))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}

/*
struct CirclesForm_Previews: PreviewProvider {
    static var previews: some View {
        CirclesForm()
    }
}
*/
