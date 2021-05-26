//
//  InvitationCard.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/6/20.
//

import SwiftUI
import MatrixSDK



struct InvitationCard: View {
    @ObservedObject var room: InvitedRoom
    //@State var showAcceptSheet = false
    @Binding var showAcceptSheet: Bool
    @State var showDeclineAlert = false
    //@State var joinedRoom: MatrixRoom? = nil
    
    var body: some View {
        
        //if room.isPending || showAcceptSheet {
        if room.isPending {
            card
                .frame(minWidth: 200, maxWidth: 400, minHeight: 200, maxHeight: 300, alignment: .center)

                /*
                .sheet(isPresented: $showAcceptSheet) {
                    let joinedRoom = room.matrix.getRoom(roomId: room.id)!
                    InvitationAcceptSheet(room: joinedRoom)
                }
                */
        }
        else {
            EmptyView()
        }
        
    }
    
    func accept() {
        print("ACCEPT Accepting invitation to \(room.displayName ?? room.id)")
        room.join() { response1 in
            switch(response1) {
            case .success(let matrixroom):
                //self.joinedRoom = matrixroom
                print("ACCEPT Success joining room \(matrixroom.displayName ?? matrixroom.id)")
                
                // Now we finally have access to the full room state
                // But I think we need to reset our timeline and other data,
                // because when we first init'd we didn't have the full info
                // UPDATE: Actually the MatrixRoom.init() does this for us now
                //joinedRoom.initTimeline()
                //joinedRoom.refresh()
                
                // Here is where we need to figure out what kind of Room it is
                // Is this a Circle?  Then we need to ask the user where we should follow it.
                //   Also, we should tag it with "following" regardless of what the user decides.
                matrixroom.getRoomType { response2 in
                    switch(response2) {
                    case .failure(let err):
                        // Couldn't get room type.  Oh well.
                        // Hopefully it's just not a room that this app should care about
                        print("ACCEPT Failed to get room type")

                    case .success(let roomtype):
                        print("ACCEPT Success fetching room type: Got [\(roomtype)]")
                        switch(roomtype) {
                        case ROOM_TYPE_CIRCLE:
                            // Tag the room as a Circle that we're following
                            matrixroom.addTag(tag: ROOM_TAG_FOLLOWING) { response3 in
                                switch(response3) {
                                case .failure:
                                    print("ACCEPT Failed to set room tag Circle")
                                case .success:
                                    print("ACCEPT Successfully set room tag Circle")
                                }
                            }
                            // Show the "accept" dialog so the user can decide whether to add it to any Circles
                            self.showAcceptSheet = true
                            // Fetch some messages
                            //room.paginate(count: 10)
                            
                        case ROOM_TYPE_GROUP:
                            print("We just joined a group!")
                            // Tag the room as a Group
                            matrixroom.addTag(tag: ROOM_TAG_GROUP) { response3 in
                                switch(response3) {
                                case .failure(let err):
                                    print("ACCEPT Failed to set room tag Group")
                                case .success:
                                    print("ACCEPT Successfully set room tag Group")
                                }
                            }
                            // Fetch some messages
                            //room.paginate(count: 10)
                    
                        case ROOM_TYPE_CHAT:
                            // Tag the room as Chat
                            matrixroom.addTag(tag: ROOM_TAG_CHAT) { _ in }
                            // Fetch some messages
                            //room.paginate(count: 10)

                        case ROOM_TYPE_PHOTOS:
                            // Tag the room as a photo room
                            matrixroom.addTag(tag: ROOM_TAG_PHOTOS) { _ in }
                            // Fetch some messages
                            //room.paginate(count: 10)

                        default:
                            // Don't know this type, nothing to do
                            print("Unknown room type")
                            break
                        }
                    }
                    //room.isPending = false
                    
                }
            case .failure(let err):
                print("ACCEPT: Failed to join room: \(err)")
            }
        }
    }
    
    func decline() {
        room.matrix.leaveRoom(roomId: room.id) { _ in
            // Not pending anymore, since we declined
            room.isPending = false
        }
    }
    
    var card: some View {
        let inviterUserId = room.whoInvitedMe()
        return ZStack {
            Image(uiImage: room.avatarImage ?? UIImage())
                .resizable()
                .scaledToFit()
                //.frame(width: proxy.size.width)
                .frame(minWidth: 200, maxWidth: 400, minHeight: 200, maxHeight: 300, alignment: .center)
                .clipped()
                
            VStack(alignment: .center) {
                
                HStack {
                    if let userId = inviterUserId,
                       let user = room.matrix.getUser(userId: userId) {
                        MessageAuthorHeader(user: user)
                    }
                    else {
                        DummyMessageAuthorHeader(userId: inviterUserId)
                    }
                    Spacer()
                }
                //.border(Color.white)
                .background(RoundedRectangle(cornerRadius: 3)
                                .fill(Color.black)
                                .opacity(0.8)
                )
                
                Spacer()
                

                Group {
                    Text(room.displayName ?? room.id)
                        .font(.title)
                        .fontWeight(.bold)
                    //Text("\(room.membersCount) member")
                    //    .font(.subheadline)
                }
                .shadow(color: .black, radius: 3)


                Spacer()
                
                HStack(alignment: .bottom) {
                    Spacer()
                    Button(action: {
                        decline()
                    }) {
                        Image(systemName: "xmark")
                        Text("Decline")
                    }
                    .padding(.all)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red)
                            //.opacity(0.8)
                    )
                    Spacer()
                    Button(action: {
                        accept()
                    }) {
                        Image(systemName: "checkmark")
                        Text("Accept")
                    }
                    .padding(.all)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green)
                            //.opacity(0.8)
                    )
                    Spacer()
                }
                .padding(.bottom, 5)

            }
            .foregroundColor(Color.white)
            //.padding(.leading)
        }
        //.border(Color.yellow)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.leading)
        .contextMenu /*@START_MENU_TOKEN@*/{
            Button(action: {
                accept()
            }) {
                Image(systemName: "checkmark")
                Text("Accept invitation")
            }
            Button(action: {
                decline()
            }) {
                Image(systemName: "xmark")
                Text("Decline invitation")
            }
            Button(action: {}) {
                Image(systemName: "person.fill.xmark")
                Text("Block future invites from this sender")
            }
            Button(action: {}) {
                Image(systemName: "exclamationmark.shield")
                Text("Report this invitation as abusive")
            }
            
        }/*@END_MENU_TOKEN@*/
    }

}

/*
struct InvitationCard_Previews: PreviewProvider {
    static var previews: some View {
        InvitationCard()
    }
}
 */
