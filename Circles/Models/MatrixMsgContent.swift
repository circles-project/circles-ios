//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  MatrixMsgContent.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/28/20.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation
import MatrixSDK

// swiftlint:disable identifier_name type_name

enum MatrixMsgType: String, Codable {
    case text = "m.text"
    case emote = "m.emote"
    case notice = "m.notice"
    case image = "m.image"
    case file = "m.file"
    case audio = "m.audio"
    case location = "m.location"
    case video = "m.video"
    case unknown = "unknown"
}

struct mInReplyTo: Codable {
    var event_id: String
}
struct mRelatesTo: Codable {
    var in_reply_to: mInReplyTo?

    enum CodingKeys: String, CodingKey {
        case in_reply_to = "m.in_reply_to"
    }
}

// https://matrix.org/docs/spec/client_server/r0.6.0#m-text
struct mTextContent: Codable {
    let msgtype: MatrixMsgType = .text
    var body: String
    var format: String?
    var formatted_body: String?

    // https://matrix.org/docs/spec/client_server/r0.6.0#rich-replies
    // Maybe should have made the "Rich replies" functionality a protocol...
    var relates_to: mRelatesTo?

    enum CodingKeys : String, CodingKey {
        // case msgtype
        case body
        case format
        case formatted_body
        case relates_to = "m.relates_to"
    }
}

// https://matrix.org/docs/spec/client_server/r0.6.0#m-emote
// cvw: Same as text.  This is stupid.  Keeping this type around anyway in case there are change in the future.
struct mEmoteContent: Codable {
    let msgtype: MatrixMsgType = .emote
    var body: String
    var format: String?
    var formatted_body: String?
}

// https://matrix.org/docs/spec/client_server/r0.6.0#m-notice
// cvw: Same as text.
typealias mNoticeContent = mTextContent

// https://matrix.org/docs/spec/client_server/r0.6.0#m-image
struct mImageContent: Codable {
    var msgtype: MatrixMsgType = .image
    var body: String
    var url: URL?
    var info: mImageInfo
    // TODO: Add BlurHash here
}

struct mImageInfo: Codable {
    var h: Int
    var w: Int
    var mimetype: String
    var size: Int
    var file: mEncryptedFile?
    var thumbnail_url: URL? // Skipping this.  E2EE or bust.
    var thumbnail_file: mEncryptedFile?
    var thumbnail_info: mThumbnailInfo?
    var blurhash: String?
}

struct mThumbnailInfo: Codable {
    var h: Int
    var w: Int
    var mimetype: String
    var size: Int
}

// https://matrix.org/docs/spec/client_server/r0.6.0#m-file
struct mFileContent: Codable {
    let msgtype: MatrixMsgType = .file
    var body: String
    var filename: String
    var info: mFileInfo
    var file: mEncryptedFile
}

struct mFileInfo: Codable {
    var mimetype: String
    var size: UInt
    var thumbnail_file: mEncryptedFile
    var thumbnail_info: mThumbnailInfo
}

// https://matrix.org/docs/spec/client_server/r0.6.0#extensions-to-m-message-msgtypes
struct mEncryptedFile: Codable {
    var url: URL
    var key: JWK
    var iv: String
    var hashes: [String: String]
    var v: String
}

// https://matrix.org/docs/spec/client_server/r0.6.0#extensions-to-m-message-msgtypes
struct JWK: Codable {
    var kty: String
    var key_ops: [String]
    var alg: String
    var k: String
    var ext: Bool
}

// https://matrix.org/docs/spec/client_server/r0.6.0#m-audio
struct mAudioContent: Codable {
    let msgtype: MatrixMsgType = .audio
    var body: String
    var info: mAudioInfo
    var file: mEncryptedFile
}

struct mAudioInfo: Codable {
    var duration: UInt
    var mimetype: String
    var size: UInt
}

// https://matrix.org/docs/spec/client_server/r0.6.0#m-location
struct mLocationContent: Codable {
    let msgtype: MatrixMsgType = .location
    var body: String
    var geo_uri: String
    var info: mLocationInfo
}

struct mLocationInfo: Codable {
    var thumbnail_url: URL?
    var thumbnail_file: mEncryptedFile?
    var thumbnail_info: mThumbnailInfo
}

// https://matrix.org/docs/spec/client_server/r0.6.0#m-video
struct mVideoContent: Codable {
    let msgtype: MatrixMsgType = .video
    var body: String
    var info: mVideoInfo
    var file: mEncryptedFile
}

struct mVideoInfo: Codable {
    var duration: UInt
    var h: UInt
    var w: UInt
    var mimetype: String
    var size: UInt
    var thumbnail_url: URL?
    var thumbnail_file: mEncryptedFile?
    var thumbnail_info: mThumbnailInfo
}

enum MatrixMsgContent: Decodable { // FIXME add Encodable for full Codable support
    case text(mTextContent)
    case emote(mEmoteContent)
    case notice(mNoticeContent)
    case image(mImageContent)
    case file(mFileContent)
    case audio(mAudioContent)
    case location(mLocationContent)
    case video(mVideoContent)
    case unknown

    enum CodingKeys: String, CodingKey {
        case msgtype
    }

    // From https://medium.com/better-programming/parse-items-with-different-key-value-pairs-in-a-json-array-with-the-help-of-enums-and-associated-301ffa81179e
    // And https://gist.github.com/emrepun/0f2d76ffdedce26fc2dec95dfe037347
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let msgtype = try? container.decode(MatrixMsgType.self, forKey: .msgtype) else {
            self = .unknown
            // return nil
            // fatalError("Unknown message type")
            return
        }

        let structcontainer = try decoder.singleValueContainer()

        switch msgtype {
        case .text:
            let text = try structcontainer.decode(mTextContent.self)
            self = .text(text)
        case .emote:
            let emote = try structcontainer.decode(mEmoteContent.self)
            self = .emote(emote)
        case .notice:
            let notice = try structcontainer.decode(mNoticeContent.self)
            self = .notice(notice)
        case .image:
            let image = try structcontainer.decode(mImageContent.self)
            self = .image(image)
        case .file:
            let file = try structcontainer.decode(mFileContent.self)
            self = .file(file)
        case .audio:
            let audio = try structcontainer.decode(mAudioContent.self)
            self = .audio(audio)
        case .location:
            let location = try structcontainer.decode(mLocationContent.self)
            self = .location(location)
        case .video:
            let video = try structcontainer.decode(mVideoContent.self)
            self = .video(video)
        case .unknown:
            self = .unknown
        }

    }
}

extension JWK {
    func toMXECK() -> MXEncryptedContentKey {
        let eck = MXEncryptedContentKey()
        eck.kty = self.kty
        eck.keyOps = self.key_ops
        eck.alg = self.alg
        eck.k = self.k
        eck.ext = self.ext

        return eck
    }
}

// For working with the MXMediaManager
extension mEncryptedFile {
    func toMXECF() -> MXEncryptedContentFile {
        let ecf = MXEncryptedContentFile()
        ecf.url = self.url.absoluteString
        ecf.key = self.key.toMXECK()
        ecf.iv = self.iv
        ecf.hashes = self.hashes
        ecf.v = self.v

        return ecf
    }
}
