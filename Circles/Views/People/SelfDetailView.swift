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
    @ObservedObject var profile: ContainerRoom<Matrix.Room>
    @ObservedObject var circles: ContainerRoom<CircleSpace>
    
    @State var showPicker = false
    @State var showConfirmRemove = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    VStack(alignment: .center) {
                        let me = profile.session.me
                        UserAvatarView(user: me)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 240, height: 240)
                        
                        Text(me.displayName ?? me.userId.username)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(me.userId.stringValue)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
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
