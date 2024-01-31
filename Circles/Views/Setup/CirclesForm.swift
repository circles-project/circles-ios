//
//  CirclesForm.swift
//  Circles
//
//  Created by Charles Wright on 9/7/21.
//

import os
import SwiftUI
import PhotosUI
import Matrix

struct CirclesForm: View {
    var store: CirclesStore
    var matrix: Matrix.Session
    let displayName: String

    @State var friendsAvatar: UIImage?
    @State var familyAvatar: UIImage?
    @State var communityAvatar: UIImage?
    @State var currentStep = 0.0
    @State var totalSteps = 15.0
    @State var status: String = "Waiting for input"
    @State var pending = false

    let stage = "circles"
    
    func handleProgressUpdate(current: Int, total: Int, message: String) {
        self.currentStep = Double(current)
        self.totalSteps = Double(total)
        self.status = message
    }

    var mainForm: some View {
        VStack(alignment: .center) {
            //let currentStage: SignupStage = .setupCircles

            Text("Set up your circles")
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

            AsyncButton(action: {
                let circles: [(String, UIImage?)] = [
                    ("Friends", friendsAvatar),
                    ("Family", familyAvatar),
                    ("Community", communityAvatar),
                ]
                self.pending = true
                try await store.createSpaceHierarchy(displayName: displayName, circles: circles, onProgress: handleProgressUpdate)
                self.pending = false
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
    
    struct CircleInfo {
        var name: String
        var avatar: UIImage?
    }
   
    
    var body: some View {
        ZStack {
            mainForm
            
            if pending {
                Color.gray.opacity(0.5)
                
                ProgressView(value: currentStep, total: totalSteps) {
                    Text("\(status)...")
                        .font(.headline)
                }
                .padding(20)
                .background(in: RoundedRectangle(cornerRadius: 10))
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
