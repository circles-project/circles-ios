//
//  RoomAutoPaginator.swift
//  Circles
//
//  Created by Charles Wright on 8/16/24.
//

import SwiftUI
import Matrix

struct RoomAutoPaginator: View {
    @ObservedObject var room: Matrix.Room
    @State var loading = false
    
    private func paginate() async {
        self.loading = true
        do {
            try await room.paginate()
        } catch {
            print("Paginate failed")
        }
        self.loading = false
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Spacer()
            
            if loading {
                ProgressView("Loading...")
            }
            else if room.canPaginate {
                AsyncButton(action: {
                    await paginate()
                }) {
                    Text("Load more")
                }
                .task {
                    await paginate()
                }
            } else if DebugModel.shared.debugMode {
                Text("Not currently loading; Can't paginate")
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
    }
}
