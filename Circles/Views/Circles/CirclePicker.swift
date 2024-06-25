//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CirclePicker.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/10/20.
//

import SwiftUI
import Matrix

struct CirclePicker: View {
    //@ObservedObject var container: ContainerRoom<CircleSpace>
    @EnvironmentObject var appSession: CirclesApplicationSession
    @Binding var selected: Set<CircleSpace>
    
    var body: some View {
        ScrollView {
            VStack(spacing: 5) {
                let container = appSession.circles
                //List {
                let rooms = container.rooms.values.sorted { $0.timestamp < $1.timestamp }
                
                ForEach(rooms) { circle in
                    //Text(circle.roomId.stringValue)
                    Button(action: {
                        if selected.contains(circle) {
                            selected.remove(circle)
                        }
                        else {
                            selected.insert(circle)
                        }
                    }) {
                        HStack {
                            Image(systemName: selected.contains(circle) ? SystemImages.checkmarkCircle.rawValue : SystemImages.circle.rawValue)
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.gray)

                            RoomAvatarView(room: circle.wall ?? circle, avatarText: .none)
                                .clipShape(Circle())
                                .frame(width: 50, height: 50)
                            Text(circle.name ?? "unnamed")
                                //.fontWeight(.bold)
                            Spacer()
                        }
                        .padding()
                        //.foregroundColor(Color.white)
                        //.background(Color.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
        }
    }
}

/*
struct StreamPicker_Previews: PreviewProvider {
    static var previews: some View {
        StreamPicker()
    }
}
 */
