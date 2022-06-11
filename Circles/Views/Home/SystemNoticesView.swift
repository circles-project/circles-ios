//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  SystemNoticesView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 3/3/21.
//

import SwiftUI

struct SystemNoticesView: View {
    var store: LegacyStore
    @State var selectedMessage: MatrixMessage?
    
    var body: some View {
        VStack(alignment: .leading) {
            if let room = store.getSystemNoticesRoom() {
                TimelineView(room: room)
                    .padding(.leading)
            } else {
                Text("No current notices")
                Spacer()
            }
        }
    }
}

struct SystemNoticesScreen: View {
    var store: LegacyStore
    
    var body: some View {
        VStack {
            Label("System Notices", systemImage: "exclamationmark.triangle.fill")
                .font(.title2)
                .padding()

            SystemNoticesView(store: store)
                .navigationBarTitle(Text("System Notices"))
                .padding()
        }
    }
}

/*
struct SystemNoticesView_Previews: PreviewProvider {
    static var previews: some View {
        SystemNoticesView()
    }
}
*/
