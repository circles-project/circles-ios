//  Copyright 2023 FUTO Holdings Inc
//
//  PhotosUploadView.swift
//  Circles
//
//  Created by Charles Wright on 6/15/23.
//

import SwiftUI
import PhotosUI
import Matrix

struct PhotosUploadView: View {
    typealias UploadTask = Task<Void,Error>
    
    var room: Matrix.Room
    @State var task: UploadTask?
    @Binding var items: [PhotosPickerItem]
    @Binding var total: Int
    @State var current: PhotosPickerItem?

    
    var body: some View {
        VStack(alignment: .center) {
            if items.isEmpty && current != nil {
                Text("Done!")
                    .font(.headline)
                    .fontWeight(.bold)
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .frame(width: 80, height: 80, alignment: .center)
            } else {
                let ratio = Float(total-items.count) / Float(total)
                ProgressView(value: ratio) {
                    Text("Uploading \(total-items.count) of \(total)...")
                }
                .padding(10)
                AsyncButton(role: .destructive, action: {
                    if let t = task {
                        t.cancel()
                    }
                }) {
                    Text("Cancel")
                }
                .padding(10)
            }
        }
        .padding(10)
        .onAppear {
            task = task ?? UploadTask(priority: .background) {

                while !items.isEmpty {
                    current = items.removeFirst()
                    if let data = try? await current?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        try await room.sendImage(image: img)
                    }
                }
                current = nil
                task = nil
                total = 0
            }
        }
    }
}

/*
struct PhotosUploadView_Previews: PreviewProvider {
    static var previews: some View {
        PhotosUploadView()
    }
}
*/
