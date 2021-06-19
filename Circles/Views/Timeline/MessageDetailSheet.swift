//
//  MessageDetailSheet.swift
//  Circles
//
//  Created by Charles Wright on 6/14/21.
//

import SwiftUI

struct MessageDetailSheet: View {
    @ObservedObject var message: MatrixMessage
    var displayStyle: MessageDisplayStyle = .timeline
    var body: some View {
        VStack {
            MessageCard(message: message, displayStyle: displayStyle)

            Text("Type: \(message.type)")
            Text("Relates to: \(message.relatesToId ?? "none")")
        }
    }
}

/*
struct MessageDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        MessageDetailSheet()
    }
}
*/
