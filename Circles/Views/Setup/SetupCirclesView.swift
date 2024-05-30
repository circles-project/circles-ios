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

struct SetupCirclesView: View {
    var store: CirclesStore
    var matrix: Matrix.Session
    @ObservedObject var user: Matrix.User // me

    @State var friendsAvatar: UIImage?
    @State var familyAvatar: UIImage?
    @State var communityAvatar: UIImage?
    
    @State var circles: [CircleSetupInfo] = []
    
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
                ForEach(circles) { info in
                    SetupCircleCard(matrix: matrix, user: user, info: info)
                }

            }

            Label("NOTE: Circle names and cover images are not encrypted", systemImage: "exclamationmark.shield")
                .font(.headline)
                .foregroundColor(.orange)

            Spacer()

            AsyncButton(action: {
                self.pending = true
                try await store.createSpaceHierarchy(displayName: user.displayName ?? user.userId.username,
                                                     circles: circles,
                                                     onProgress: handleProgressUpdate)
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
        .onAppear {
            user.refreshProfile()
        }
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
