//
//  SelfDetailView.swift
//  Circles
//
//  Created by Charles Wright on 7/31/23.
//

import SwiftUI
import UIKit
import CoreImage
import Matrix

struct SelfDetailView: View {
    @ObservedObject var matrix: Matrix.Session
    @ObservedObject var profile: ContainerRoom<Matrix.Room>
    @ObservedObject var circles: ContainerRoom<CircleSpace>
    
    func generateQRCode() -> UIImage? {
        guard let data = profile.roomId.stringValue.data(using: String.Encoding.ascii)
        else {
            print("Failed to get UTF-8 data")
            return nil
        }
        print("Generating QR code for \(data.count) bytes")
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("Q", forKey: "inputCorrectionLevel")
            let transform = CGAffineTransform(scaleX: 10, y: 10)


            if let outputImage = filter.outputImage {
                let transformedImage = outputImage.transformed(by: transform)
                //return UIImage(ciImage: outputImage)
                return UIImage(ciImage: transformedImage)
            } else {
                print("Failed to generate QR image")
            }
        } else {
            print("Failed to initialize CIFilter for QR code")
        }

        return nil
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {

                HStack {
                    Spacer()
                    VStack(alignment: .center) {
                        Image(uiImage: matrix.avatar ?? UIImage(systemName: "person.circle")!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 180, height: 180)
                            .clipShape(Circle())
                        
                        Text(matrix.displayName ?? matrix.creds.userId.username)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(matrix.creds.userId.stringValue)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        /*
                         if let qr = self.generateQRCode() {
                         Image(uiImage: qr)
                         //.resizable()
                         //.scaledToFit()
                         //.frame(width: 120, height: 120)
                         .border(Color.red)
                         } else {
                         Text("🙁")
                         }
                         */
                    }
                    Spacer()
                }
                
                Divider()
                Text("VISIBLE CIRCLES")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                if profile.rooms.isEmpty {
                    Text("No circles are visible to my connections.")
                        .padding()
                    Button(action: {}) {
                        Label("Add circle(s)", systemImage: "plus.circle")
                    }
                    .padding(.leading)
                } else {
                    ForEach(profile.rooms) { room in
                        HStack {
                            RoomAvatar(room: room)
                                .frame(width: 80, height: 80)
                            Text(room.name ?? "??")
                                .font(.title3)
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(Text("Me"))
    }
}

/*
struct SelfDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SelfDetailView()
    }
}
*/
