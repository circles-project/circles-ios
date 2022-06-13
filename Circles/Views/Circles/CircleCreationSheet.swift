//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CircleCreationSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/13/20.
//

import SwiftUI

struct CircleCreationSheet: View {
    @ObservedObject var store: LegacyStore
    @Environment(\.presentationMode) var presentation
    
    @State private var circleName: String = ""
    @State private var rooms: Set<MatrixRoom> = []
    @State private var avatarImage: UIImage? = nil
    
    @State var newUserIds: [String] = []
    @State var newestUserId: String = ""
    
    var buttonBar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            })
            {
                Text("Cancel")
            }
            
            Spacer()
            
            Button(action: {
                /*
                print("Creating a Stream with \(self.rooms.count) channels:")
                for room in self.rooms {
                    print("\t\(room.displayName ?? room.id)")
                }
                 */
                store.createCircle(name: circleName, rooms: Array(rooms)) { response in
                    switch(response) {
                    case .failure(let err):
                        print("Failed to create Circle: \(err)")
                    case .success(let circle):
                        print("Created stream \(circle.name)")
                        store.saveCircles() { _ in }
                        self.presentation.wrappedValue.dismiss()
                    }
                }

            }) {
                //Text("Create stream \"\(streamName)\" with \(rooms.count) channels")
                Text("Create")
                    .fontWeight(.bold)
            }
            .disabled(circleName.isEmpty)
            //.padding()
        }
        .font(.subheadline)
    }
    
    var mockup: some View {
        HStack {
            ZStack {
                let cardSize: CGFloat = 120

                Circle()
                    .foregroundColor(Color.gray)
                    .opacity(0.80)
                    .frame(width: cardSize, height: cardSize)
                
                if let img = avatarImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardSize, height: cardSize)
                        //.clipped()
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .shadow(radius: 5)
                        .padding(5)
                }
            }
            
            VStack(alignment: .leading) {
                let user = store.me()
                Text(user.displayName ?? user.id)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(circleName)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
    }

    var body: some View {
        VStack {
            buttonBar
                        
            Text("New Circle")
                .font(.headline)
                .fontWeight(.bold)
            
            mockup
                .padding()
            
            TextField("Circle name", text: $circleName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Spacer()
            
            VStack(alignment: .leading) {
                Text("Invite Followers")
                    .fontWeight(.bold)
                HStack {
                    TextField("User ID (e.g. @alice)", text: $newestUserId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                    
                    Button(action: {
                        if let canonicalUserId = store.canonicalizeUserId(userId: newestUserId) {
                            self.newUserIds.append(canonicalUserId)
                        }
                        self.newestUserId = ""
                    }) {
                        Text("Add")
                    }
                }
                
                List {
                    ForEach(newUserIds, id: \.self) { userId in
                        if let user = store.getUser(userId: userId) {
                            MessageAuthorHeader(user: user)
                        }
                        else {
                            //Text(userId)
                            DummyMessageAuthorHeader(userId: userId)
                        }
                    }
                    .onDelete(perform: { indexSet in
                        self.newUserIds.remove(atOffsets: indexSet)
                    })
                }
                
            }

        }
        .padding()
    }
}

/*
struct StreamCreationSheet_Previews: PreviewProvider {
    static var previews: some View {
        CircleCreationSheet(store: LegacyStore())
    }
}
*/
