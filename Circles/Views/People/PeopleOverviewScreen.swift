//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PeopleOverviewScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/1/20.
//

import SwiftUI

struct PeopleOverviewScreen: View {
    @ObservedObject var container: PeopleContainer
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    
                    //Text("\(container.people.count) People")
                    
                    ForEach(container.people) { user in
                        
                        VStack(alignment: .leading) {
                            
                            NavigationLink(destination: PersonDetailView(user: user)) {
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
            .navigationBarTitle("My People", displayMode: .inline)
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
