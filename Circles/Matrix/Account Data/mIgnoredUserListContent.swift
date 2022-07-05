//
//  mIgnoredUserList.swift
//  Circles
//
//  Created by Charles Wright on 7/5/22.
//

import Foundation

struct mIgnoredUserListContent: Codable {
    var ignoredUsers: [UserId: [String:String]]
}
