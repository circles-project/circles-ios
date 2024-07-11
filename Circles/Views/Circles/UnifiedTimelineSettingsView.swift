//
//  UnifiedTimelineSettingsView.swift
//  Circles
//
//  Created by Charles Wright on 7/11/24.
//

import SwiftUI
import PhotosUI
import Matrix

struct UnifiedTimelineSettingsView: View {
    @ObservedObject var space: TimelineSpace
    
    @State var showConfirmUnfollow = false
    @State var roomToUnfollow: Matrix.Room?

    @State var showInviteSheet = false
    @State var showShareSheet = false
    
    @State var showConfirmResend = false
    @State var showConfirmCancelInvite = false
    
    @ViewBuilder
    var followingSection: some View {
        let timelines = space.following
        if timelines.count > 0 {
            Section("Timelines I'm Following (\(timelines.count))") {
                ForEach(timelines) { room in
                    let user = space.session.getUser(userId: room.creator)
                    CircleFollowingRow(container: space, room: room, user: user)
                }
            }
        }
    }
    
    @ViewBuilder
    var circlesSection: some View {
        let circles = space.circles
        if circles.count > 0 {
            Section("My Circles") {
                ForEach(circles) { circle in
                    /*
                    let name = circle.name ?? ""
                    let followerCount = Int.max(circle.joinedMembers.count - 1, 0)
                    Text("\(name) (\(followerCount) followers)")
                     */
                    Text("\(circle.name ?? "???")")
                }
            }
        }
    }

    var body: some View {
        VStack {
            Form {
                circlesSection
                followingSection
            }
        }
        .navigationTitle("Circles Settings")
    }
}

