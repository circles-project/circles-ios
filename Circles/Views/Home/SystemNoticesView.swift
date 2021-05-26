//
//  SystemNoticesView.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 3/3/21.
//

import SwiftUI

struct SystemNoticesView: View {
    var store: KSStore
    
    var body: some View {
        VStack(alignment: .leading) {
            if let room = store.getSystemNoticesRoom() {
                TimelineView(room: room)
                    .padding(.leading)
            } else {
                Text("No current notices")
            }
        }
    }
}

struct SystemNoticesScreen: View {
    var store: KSStore
    
    var body: some View {
        SystemNoticesView(store: store)
            .navigationBarTitle(Text("System Notices"))
            .padding()
    }
}

/*
struct SystemNoticesView_Previews: PreviewProvider {
    static var previews: some View {
        SystemNoticesView()
    }
}
*/
