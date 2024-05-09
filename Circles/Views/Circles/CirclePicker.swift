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
        VStack {
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
                        VStack {
                            if selected.contains(circle) {
                                HStack {
                                    //Image(systemName: "checkmark.circle")
                                    Text(circle.name ?? "unnamed")
                                        .fontWeight(.bold)
                                    Spacer()
                                }
                                .padding()
                                .foregroundColor(Color.white)
                                .background(Color.blue)
                            } else {
                                HStack {
                                    //Image(systemName: "circle")
                                    Text(circle.name ?? "unnamed")
                                        .fontWeight(.bold)
                                    Spacer()
                                }
                                .padding()
                            }
                        }

                    }
                //}
            }
            .padding(.horizontal)
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
