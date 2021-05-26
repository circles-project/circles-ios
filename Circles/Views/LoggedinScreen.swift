//
//  LoggedinScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI

struct LoggedinScreen: View {
    @ObservedObject var store: KSStore
    //@State private var selected = 0
    //@State private var selection = 0
    
    enum Tab: String {
        case home
        case circles
        case people
        case groups
        case photos
    }
    //@State private var selection: Tab = .home
    @SceneStorage("tab") private var selection: Tab = .home
    
    /* // cvw: This doesn't seem to be working anyway
    func onAppear() {
        store.amINewHere() { response in
            switch(response) {
            case .success(let iAmNew):
                self.showSetupSheet = iAmNew
            case .failure(let err):
                self.showSetupSheet = true
                print("WELCOME Failed to get user's 'new' status..  Showing the welcome dialog just in case")
            }
        }
    }
    */
    
    var body: some View {
        TabView(selection: $selection) {
            
            HomeTabMasterView(store: self.store,
                              user: self.store.me(),
                              tab: self.$selection
            )
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(Tab.home)
            
            CirclesOverviewScreen(store: self.store)
                .tabItem {
                    Image(systemName: "circles.hexagonpath")
                    Text("My Circles")
                }
                .tag(Tab.circles)
            
            PeopleOverviewScreen(container: self.store.getPeopleContainer())
                .tabItem {
                    Image(systemName: "rectangle.stack.person.crop")
                    Text("My People")
                }
                .tag(Tab.people)
            
            GroupsOverviewScreen(container: self.store.getGroups())
                .tabItem {
                    Image(systemName: "person.2.square.stack")
                    Text("My Groups")
                }
                .tag(Tab.groups)
            
            PhotosOverviewScreen(container: self.store.getPhotoGalleries())
                .tabItem {
                    Image(systemName: "photo.fill.on.rectangle.fill")
                    Text("Photos")
                }
                .tag(Tab.photos)
            
            /*
            Text("Chat Screen")
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    //Text("Direct Messages")}
                    Text("Chat")
                }
                .tag(5)
            */
            

        }
        //.accentColor(.green)


    }

}

struct LoggedinScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoggedinScreen(store: KSStore())
    }
}
