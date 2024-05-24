//
//  UiaOverlayView.swift
//  Circles
//
//  Created by Charles Wright on 7/10/23.
//

import SwiftUI
import Matrix

// This type is necessary because we need a View that observes the Matrix Session,
// in order to catch the change in its UIA session.
// This view is used in the main ContentView in the app, to overlay on top of the
// main tabbed interface for the app's normal operation.
struct UiaOverlayView: View {
    @ObservedObject var circles: CirclesApplicationSession
    @ObservedObject var matrix: Matrix.Session
    
    var body: some View {
        if let uia = matrix.uiaSession,
           !uia.isFinished
        {
            //Color.gray.opacity(0.5)
            UiaView(session: circles, uia: uia)
                .frame(minWidth: 325, maxWidth: 500, maxHeight: 700, alignment: .center)
                .background(in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

/*
struct UiaOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        UiaOverlayView()
    }
}
*/
