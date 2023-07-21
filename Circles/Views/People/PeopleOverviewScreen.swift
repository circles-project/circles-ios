//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PeopleOverviewScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/1/20.
//

import SwiftUI
import Matrix

struct PeopleOverviewScreen: View {
    @ObservedObject var container: ContainerRoom<Matrix.SpaceRoom>
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    
                    //Text("\(container.rooms.count) People")
                    
                    ForEach(container.rooms) { room in
                        
                        VStack(alignment: .leading) {
                            let user = room.session.getUser(userId: room.creator)
                            NavigationLink(destination: PersonDetailView(space: room)) {
                                //Text("\(user.displayName ?? user.id)")
                                PersonHeaderRow(user: user)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                        }
                        //.padding(.leading)
                        Divider()
                        //}
                    }
                    
                }
            }
            .navigationBarTitle("People", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())

    }
}

/*
struct PeopleOverviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        PeopleOverviewScreen()
    }
}
*/
