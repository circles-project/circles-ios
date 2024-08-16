//
//  RoomAutoPaginator.swift
//  Circles
//
//  Created by Charles Wright on 8/16/24.
//

import SwiftUI
import Matrix

struct RoomAutoPaginator: View {
    var room: Matrix.Room
    @State var loading = false
    
    var body: some View {
        HStack(alignment: .top) {
            Spacer()
            
            if loading {
                ProgressView("Loading...")
            }
            else if room.canPaginate {
                AsyncButton(action: {
                    self.loading = true
                    do {
                        try await room.paginate()
                    } catch {
                        print("Paginate failed")
                    }
                    self.loading = false
                }) {
                    Text("Load more")
                }
                .onAppear {
                    self.loading = true
                    let _ = Task {
                        do {
                            try await room.paginate()
                        } catch {
                            print("Paginate failed")
                        }
                        self.loading = false
                    }
                }
            } else { //if DebugModel.shared.debugMode {
                Text("Not currently loading; Can't paginate")
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
    }
}
