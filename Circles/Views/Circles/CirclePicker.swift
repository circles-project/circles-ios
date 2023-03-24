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
    @ObservedObject var container: ContainerRoom<CircleSpace>
    @Binding var selected: Set<CircleSpace>
    
    var body: some View {
        VStack {
            List {
                ForEach(container.rooms) { circle in
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
                }
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
