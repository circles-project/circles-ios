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
        ZStack {
            Color.greyCool200
            
            VStack(alignment: .center) {
                let elementWidth = UIScreen.main.bounds.width - 48
                let elementHeight: CGFloat = 48.0
                //let currentStage: SignupStage = .setupCircles
                
                Text("Create your circles")
                    .font(
                        CustomFonts.nunito20
                            .weight(.heavy)
                    )
                    .foregroundColor(Color.greyCool1100)
                
                List {
                    ForEach(circles) { info in
                        ZStack {
                            HStack {
                                SetupCircleCard(matrix: matrix, user: user, info: info)
                                    .background(Color.greyCool200)
                                
                                Spacer()
                                
                                Button(role: .destructive, action: {
                                    circles.removeAll { $0.name == info.name }
                                }) {
                                    Image(systemName: SystemImages.minusCircleFill.rawValue)
                                }
                            }
                        }
                    }
                    .background(Color.greyCool200)
                }
//                .listStyle(.inset)
                .background(Color.greyCool200)
                
                Button(action: {
                    showNewCircleSheet = true
                }) {
                    Label("Add a new circle", systemImage: "plus.circle")
                }
                .padding()
                .sheet(isPresented: $showNewCircleSheet) {
                    SetupAddNewCircleSheet(me: user, circles: $circles)
                }
                .font(CustomFonts.nunito16)
                
                Spacer()
                
                Label("NOTE: Circle names and cover images are not encrypted", systemImage: SystemImages.exclamationmarkShield.rawValue)
                    .font(CustomFonts.nunito16)
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
                .buttonStyle(BigRoundedButtonStyle(width: elementWidth, height: elementHeight))
                .font(
                    CustomFonts.nunito16
                        .weight(.bold)
                )
                .padding(.bottom, 38)
                .disabled(circles.isEmpty)
            }
            .frame(maxWidth: 700)
            .onAppear {
                user.refreshProfile()
            }
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
