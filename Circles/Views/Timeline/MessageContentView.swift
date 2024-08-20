//
//  MessageContentView.swift
//  Circles
//
//  Created by Charles Wright on 8/20/24.
//

import SwiftUI
import Matrix

struct MessageContentView: View {
    @ObservedObject var message: Matrix.Message
    @AppStorage("mediaViewWidth") var mediaViewWidth: Double = 0
    
    var body: some View {
        VStack {
            // If the message has been edited/replaced, then we should show the new content
            // Otherwise we should show the original content
            let current = message.replacement ?? message
            
            if let content = current.content as? Matrix.MessageContent {
                switch(content.msgtype) {
                case M_TEXT:
                    if let textContent = content as? Matrix.mTextContent {
                        TextContentView(textContent.body)
                            .font(Font.custom("Inter", size: 14))
                            .padding(.horizontal, 3)
                            .padding(.vertical, 5)
                    }
                    else {
                        EmptyView()
                    }
                    
                case M_IMAGE:
                    //let newWidth = isThreaded ? mediaViewWidth - 20 : mediaViewWidth
                    ImageContentView(message: current)
                    
                case M_VIDEO:
                    VideoContentView(message: current)
                
                // Poll event handling is temporary until proper support is implemented
                case ORG_MATRIX_MSC3381_POLL_START:
                    if let pollContent = content as? PollStartContent {
                        let pollText = "Poll: \(pollContent.message)\n\n"
                        let answersText = pollContent.start.answers.enumerated().map { "\t\($0): \($1.answer.body)\n" }.joined()
                                                
                        TextContentView(pollText + answersText)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 5)
                    }
                    else {
                        EmptyView()
                    }

                case ORG_MATRIX_MSC3381_POLL_RESPONSE:
                    if let pollContent = current.event.content as? PollResponseContent,
                       let pollId = pollContent.relatesTo.eventId,
                       let poll = current.room.timeline[pollId]?.event.content as? PollStartContent,
                       let vote = poll.start.answers.filter({ $0.id == pollContent.selections.first }).first {

                        if poll.start.kind == PollStartContent.PollStart.Kind.open {
                            TextContentView("Voted for \(vote.answer.body)")
                                .padding(.horizontal, 3)
                                .padding(.vertical, 5)
                        }
                        else {
                            TextContentView("Voted")
                                .padding(.horizontal, 3)
                                .padding(.vertical, 5)
                        }
                    }
                    else {
                        EmptyView()
                    }
                
                case ORG_MATRIX_MSC3381_POLL_END:
                    if let pollContent = current.event.content as? PollEndContent {
                        TextContentView(pollContent.text)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 5)
                    }
                    else {
                        EmptyView()
                    }
                    
                default:
                    Text("This version of Circles can't display this message yet (\"\(message.type)\")")
                        .foregroundColor(.red)
                
                } // end switch
                
            } else if current.type == M_ROOM_ENCRYPTED {
                VStack {
                    BasicImage(systemName: SystemImages.lockRectangle.rawValue)
                        .foregroundColor(Color.gray)
                        .frame(width: 240, height: 240)
                        .padding()
                    VStack {
                        Label("Could not decrypt message", systemImage: SystemImages.exclamationmarkTriangle.rawValue)
                            .font(.title2)
                            .fontWeight(.semibold)
                        if DebugModel.shared.debugMode {
                            Text("Message id: \(message.id)")
                                .font(.footnote)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .background(
                        Color.greyCool400
                            .opacity(0.5)
                    )
                    .padding(.bottom, 2)
                }
                 .onAppear {
                     print("Trying to decrypt message \(current.eventId) ...")
                     Task {
                         try await current.decrypt()
                     }
                 }
            } else {
                Text("Oh no! Something went wrong.  Circles failed to parse a message of type \"\(current.type)\".")
                    .foregroundColor(.red)
            }
        }
    }
}

