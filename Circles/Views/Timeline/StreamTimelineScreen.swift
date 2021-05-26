//
//  StreamTimelineScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/6/20.
//

import SwiftUI

struct StreamTimelineScreen: View {
    @ObservedObject var stream: SocialStream
    
    var body: some View {
        StreamTimeline(stream: stream)
            .navigationBarTitle(stream.name)
    }
}

/*
struct StreamTimelineScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamTimelineScreen()
    }
}
*/
