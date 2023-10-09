//
//  SelfDetailView.swift
//  Circles
//
//  Created by Charles Wright on 7/31/23.
//

import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
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
        
        // https://developer.apple.com/documentation/coreimage/ciqrcodegenerator
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel") // 25%

        if let result = filter.outputImage {
            // Scale up the QR code by a factor of 10x
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let transformedImage = result.transformed(by: transform)
            
            // For whatever reason, we MUST convert to a CGImage here, using the CIContext.
            // If we do not do this (eg by trying to create a UIImage directly from the CIImage),
            // then we get nothing but a blank square for our QR code. :(
            let context = CIContext()
            if let cgImg = context.createCGImage(transformedImage, from: transformedImage.extent) {
                let ui = UIImage(cgImage: cgImg)
                //print("QR code image is \(ui.size.height) x \(ui.size.width)")
                return ui
            } else {
                print("Failed to create UIImage from transformed image")
                return nil
            }
            
        } else {
            print("Failed to generate QR image")
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
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Text(matrix.displayName ?? matrix.creds.userId.username)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(matrix.creds.userId.stringValue)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                         if let qr = self.generateQRCode() {
                             Image(uiImage: qr)
                                //.resizable()
                                //.scaledToFit()
                                //.frame(width: 120, height: 120)
                                .border(Color.red)
                         } else {
                             Text("🙁 Failed to generate QR code")
                         }
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
                            RoomAvatar(room: room, avatarText: .roomInitials)
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
