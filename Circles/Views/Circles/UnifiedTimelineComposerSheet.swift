//
//  UnifiedTimelineComposerSheet.swift
//  Circles
//
//  Created by Charles Wright on 7/12/24.
//

import SwiftUI
import Matrix

struct UnifiedTimelineComposerSheet: View {
    @ObservedObject var timelines: TimelineSpace
    @State var selectedRoom: Matrix.Room?
    @Environment(\.presentationMode) var presentation
    @State var createMyFirstCircle = false
    
    var body: some View {
        let circles = timelines.circles
        let me = timelines.session.me
        
        if let room = selectedRoom {
            PostComposer(room: room)
        } else if circles.count == 1,
                  let onlyCircle = circles.first
        {
            PostComposer(room: onlyCircle)
        } else if circles.count > 1 {
            VStack(alignment: .center) {
                Spacer()
                
                Text("You have \(circles.count) circles. Which one would you like to share with?")
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(circles) { circle in
                            Button(action: {
                                self.selectedRoom = circle
                            }) {
                                TimelineOverviewCard(room: circle, user: me)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: 400)
                
                Spacer()
                
                Button(role: .destructive, action: {
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                }
                .padding()
            }
        } else if createMyFirstCircle {
            CircleCreationSheet(container: timelines)
        } else {
            VStack(alignment: .center) {
                Text("It looks like you don't have any circles yet. Would you like to create one now?")
                
                Button(action: {
                    self.createMyFirstCircle = true
                }) {
                    Text("Create my first circle")
                }
                
                Button(role: .destructive, action: {
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                }
                .padding()
            }
        }
    }
}
