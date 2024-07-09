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
    
    @State var circles: [CircleSetupInfo] = [
        CircleSetupInfo(name: "Family"),
        CircleSetupInfo(name: "Friends")
    ]
    
    @State var showNewCircleSheet = false
    
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

            Text("Create your circles")
                .font(.title2)
                .fontWeight(.bold)

            List {
                ForEach(circles) { info in
                    HStack {
                        SetupCircleCard(matrix: matrix, user: user, info: info)
                        
                        Spacer()
                        
                        Button(role: .destructive, action: {
                            circles.removeAll { $0.name == info.name }
                        }) {
                            Image(systemName: SystemImages.minusCircleFill.rawValue)
                        }
                    }
                }
            }
            .listStyle(.inset)

            Button(action: {
                showNewCircleSheet = true
            }) {
                Label("Add a new circle", systemImage: "plus.circle")
            }
            .padding()
            .sheet(isPresented: $showNewCircleSheet) {
                SetupAddNewCircleSheet(me: user, circles: $circles)
            }
            
            Spacer()

            Label("NOTE: Circle names and cover images are not encrypted", systemImage: SystemImages.exclamationmarkShield.rawValue)
                .font(.headline)
                .foregroundColor(.orange)

            Spacer()

            AsyncButton(action: {
                self.pending = true
                self.totalSteps = Double(10 + circles.count)
                try await store.createSpaceHierarchy(displayName: user.displayName ?? user.userId.username,
                                                     circles: circles,
                                                     onProgress: handleProgressUpdate)
                self.pending = false
            }) {
                Text("Next")
            }
            .buttonStyle(BigBlueButtonStyle())
            .disabled(circles.isEmpty)

        }
        .padding()
        .frame(maxWidth: 700)
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
                .frame(maxWidth: 600)
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
