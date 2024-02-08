//
//  DeleteAndPurge.swift
//  Circles
//
//  Created by Charles Wright on 2/8/24.
//

import Foundation
import Matrix


func deleteAndPurge(message: Matrix.Message) async throws {
    let content = message.content
    let session = message.room.session
    try await message.room.redact(eventId: message.eventId,
                                  reason: "Deleted by \(message.room.session.whoAmI())")
    // Now attempt to delete media associated with this event, if possible
    // Since the Matrix spec has no DELETE for media, this will probably fail, so don't worry if these calls throw errors
    if let messageContent = content as? Matrix.MessageContent {
        switch messageContent.msgtype {
        case M_IMAGE:
            if let imageContent = messageContent as? Matrix.mImageContent {
                if let file = imageContent.file {
                    try? await session.deleteMedia(file.url)
                }
                if let url = imageContent.url {
                    try? await session.deleteMedia(url)
                }
                if let thumbnail_file = imageContent.thumbnail_file {
                    try? await session.deleteMedia(thumbnail_file.url)
                }
                if let thumbnail_url = imageContent.thumbnail_url {
                    try? await session.deleteMedia(thumbnail_url)
                }
            }
        case M_VIDEO:
            if let videoContent = messageContent as? Matrix.mVideoContent {
                if let file = videoContent.file {
                    try? await session.deleteMedia(file.url)
                }
                if let url = videoContent.url {
                    try? await session.deleteMedia(url)
                }
                if let thumbnail_file = videoContent.thumbnail_file {
                    try? await session.deleteMedia(thumbnail_file.url)
                }
                if let thumbnail_url = videoContent.thumbnail_url {
                    try? await session.deleteMedia(thumbnail_url)
                }
            }
        default:
            print("Not deleting any media for msgtype \(messageContent.msgtype)")
        }
    }
}
