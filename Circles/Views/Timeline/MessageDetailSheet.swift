//
//  MessageDetailSheet.swift
//  Circles
//
//  Created by Charles Wright on 6/14/21.
//

import SwiftUI

struct MessageDetailSheet: View {
    @ObservedObject var message: MatrixMessage
    @Environment(\.presentationMode) var presentation
    var displayStyle: MessageDisplayStyle = .timeline

    @State var selectedMessage: MatrixMessage? = nil
    @State var sheetType: TimelineSheetType? = nil

    var buttonBar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Close")
            }

            Spacer()
        }
        .padding(5)
    }

    var body: some View {
        VStack {
            buttonBar

            ScrollView {
                LazyVStack {
                    MessageCard(message: message, displayStyle: displayStyle)
                        //.padding(.top, 5)

                    RepliesView(room: message.room, parent: message,
                                expanded: true,
                                selectedMessage: $selectedMessage,
                                sheetType: $sheetType)

                    //Text("Type: \(message.type)")
                    //Text("Relates to: \(message.relatesToId ?? "none")")

                }
                .padding([.leading, .trailing], 3)
            }
            Spacer()
        }
        //.padding(5)

    }
}

/*
struct MessageDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        MessageDetailSheet()
    }
}
*/
