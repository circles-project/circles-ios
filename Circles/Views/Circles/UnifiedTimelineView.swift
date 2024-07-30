//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CircleTimelineScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/17/20.
//

import SwiftUI
import PhotosUI
import Matrix

enum CircleSheetType: String {
    //case settings
    //case followers
    //case following
    case invite
    //case photo
    case share
}
extension CircleSheetType: Identifiable {
    var id: String { rawValue }
}

struct UnifiedTimelineView: View {
    @ObservedObject var space: TimelineSpace
    @Environment(\.presentationMode) var presentation
    
    //@State var showComposer = false
    @State var sheetType: CircleSheetType? = nil
    @State var showPhotosPicker: Bool = false
    @State var selectedItem: PhotosPickerItem?
    @State var showNewPostInSheetStyle = false
    //@State var image: UIImage?
    
    @State var viewModel = TimelineViewModel()
    
    var toolbarMenu: some View {
        Menu {
            NavigationLink(destination: UnifiedTimelineSettingsView(space: space)){
                Label("Settings", systemImage: SystemImages.gearshapeFill.rawValue)
            }
            
            Button(action: {self.sheetType = .invite}) {
                Label("Invite Followers", systemImage: SystemImages.personCropCircleBadgePlus.rawValue)
            }
        }
        label: {
            Label("Settings", systemImage: SystemImages.gearshapeFill.rawValue)
        }
    }

    var stupidSwiftUiTrick: Int {
        print("DEBUGUI\tStreamTimeline rendering for Circle \(space.roomId)")
        return 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                let _ = self.stupidSwiftUiTrick // foo
                
                UnifiedTimeline(space: space)
                    .navigationBarTitle("All Posts", displayMode: .inline)
                    .toolbar {
                        ToolbarItemGroup(placement: .automatic) {
                            toolbarMenu
                        }
                    }
                    .onAppear {
                        print("DEBUGUI\tStreamTimeline appeared for Circle \(space.roomId)")
                    }
                    .onDisappear {
                        print("DEBUGUI\tStreamTimeline disappeared for Circle \(space.roomId)")
                    }
                    .sheet(isPresented: $showNewPostInSheetStyle) {
                        UnifiedTimelineComposerSheet(timelines: space)
                    }
                
                let circles = space.circles
                if circles.count > 0 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showNewPostInSheetStyle = true
                            }) {
                                Label("New post", systemImage: SystemImages.plusCircleFill.rawValue)
                            }
                            .buttonStyle(PillButtonStyle())
                            .padding(10)
                        }
                    }
                }
            }
        }
        .environmentObject(viewModel)
    }
}

