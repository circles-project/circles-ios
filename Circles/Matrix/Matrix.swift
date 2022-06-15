//
//  Matrix.swift
//  Circles
//
//  Created by Charles Wright on 6/14/22.
//

import Foundation
import UIKit
import AnyCodable

enum Matrix {
    
    struct Error: Swift.Error {
        var msg: String
        
        init(_ msg: String) {
            self.msg = msg
        }
    }
    
    
    
    static func getDomainFromUserId(_ userId: String) -> String? {
        let toks = userId.split(separator: ":")
        if toks.count != 2 {
            return nil
        }

        let domain = String(toks[1])
        return domain
    }
    
    static func fetchWellKnown(for domain: String) async throws -> MatrixWellKnown {
        
        guard let url = URL(string: "https://\(domain)/.well-known/matrix/client") else {
            let msg = "Couldn't construct well-known URL"
            print("WELLKNOWN\t\(msg)")
            throw CirclesError(msg)
        }
        print("WELLKNOWN\tURL is \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        //request.cachePolicy = .reloadIgnoringLocalCacheData
        request.cachePolicy = .returnCacheDataElseLoad

        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            let msg = "Couldn't decode HTTP response"
            print("WELLKNOWN\t\(msg)")
            throw CirclesError(msg)
        }
        guard httpResponse.statusCode == 200 else {
            let msg = "HTTP request failed"
            print("WELLKNOWN\t\(msg)")
            throw CirclesError(msg)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let stuff = String(data: data, encoding: .utf8)!
        print("WELLKNOWN\tGot response data:\n\(stuff)")
        guard let wellKnown = try? decoder.decode(MatrixWellKnown.self, from: data) else {
            let msg = "Couldn't decode response data"
            print("WELLKNOWN\t\(msg)")
            throw CirclesError(msg)
        }
        print("WELLKNOWN\tSuccess!")
        return wellKnown
    }
    
    
    static func decodeEventContent(of type: MatrixEventType, from decoder: Decoder) throws -> Codable {
        
        let container = try decoder.container(keyedBy: MinimalEvent.CodingKeys.self)
            
        switch type {
        case .mRoomCanonicalAlias:
            let content = try container.decode(CanonicalAliasContent.self, forKey: .content)
            return content
        case .mRoomCreate:
            let content = try container.decode(CreateContent.self, forKey: .content)
            return content
        case .mRoomMember:
            let content = try container.decode(RoomMemberContent.self, forKey: .content)
            return content
        case .mRoomJoinRules:
            let content = try container.decode(JoinRuleContent.self, forKey: .content)
            return content
        case .mRoomPowerLevels:
            let content = try container.decode(RoomPowerLevelsContent.self, forKey: .content)
            return content
            
        case .mRoomName:
            let content = try container.decode(RoomNameContent.self, forKey: .content)
            return content
        case .mRoomAvatar:
            let content = try container.decode(RoomAvatarContent.self, forKey: .content)
            return content
        case .mRoomTopic:
            let content = try container.decode(RoomTopicContent.self, forKey: .content)
            return content
            
        case .mTag:
            let content = try container.decode(TagContent.self, forKey: .content)
            return content
            
        case .mRoomEncryption:
            let content = try container.decode(RoomEncryptionContent.self, forKey: .content)
            return content
        
        case .mEncrypted:
            let content = try container.decode(EncryptedEventContent.self, forKey: .content)
            return content
        
        case .mRoomMessage:
            // Peek into the content struct to examine the `msgtype`
            struct MinimalMessageContent: Codable {
                var msgtype: MatrixMessageType
            }
            let mmc = try container.decode(MinimalMessageContent.self, forKey: .content)
            // Now use the msgtype to determine how we decode the content
            switch mmc.msgtype {
            case .text:
                let content = try container.decode(mTextContent.self, forKey: .content)
                return content
            case .emote:
                let content = try container.decode(mEmoteContent.self, forKey: .content)
                return content
            case .notice:
                let content = try container.decode(mNoticeContent.self, forKey: .content)
                return content
            case .image:
                let content = try container.decode(mImageContent.self, forKey: .content)
                return content
            case .location:
                let content = try container.decode(mLocationContent.self, forKey: .content)
                return content
            case .audio:
                let content = try container.decode(mAudioContent.self, forKey: .content)
                return content
            case .video:
                let content = try container.decode(mVideoContent.self, forKey: .content)
                return content
            case .file:
                let content = try container.decode(mFileContent.self, forKey: .content)
                return content
            }

        }
    }
    
    static func encodeEventContent(content: Codable, of type: MatrixEventType, to encoder: Encoder) throws {
        enum CodingKeys: String, CodingKey {
            case content
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch type {
        case .mRoomAvatar:
            guard let avatarContent = content as? RoomAvatarContent else {
                throw Matrix.Error("Couldn't convert content")
            }
            try container.encode(avatarContent, forKey: .content)
            
        case .mRoomCanonicalAlias:
            guard let aliasContent = content as? CanonicalAliasContent else {
                throw Matrix.Error("Couldn't convert content")
            }
            try container.encode(aliasContent, forKey: .content)
            
        case .mRoomCreate:
            guard let createContent = content as? CreateContent else {
                throw Matrix.Error("Couldn't convert content")
            }
            try container.encode(createContent, forKey: .content)
            
        case .mRoomJoinRules:
            guard let joinruleContent = content as? JoinRuleContent else {
                throw Matrix.Error("Couldn't convert content")
            }
            try container.encode(joinruleContent, forKey: .content)
            
        case .mRoomMember:
            guard let roomMemberContent = content as? RoomMemberContent else {
                throw Matrix.Error("Couldn't convert content")
            }
            try container.encode(roomMemberContent, forKey: .content)
            
        case .mRoomPowerLevels:
            guard let powerlevelsContent = content as? RoomPowerLevelsContent else {
                throw Matrix.Error("Couldn't convert content")
            }
            try container.encode(powerlevelsContent, forKey: .content)
            
        case .mRoomMessage:
            guard let messageContent = content as? MatrixMessageContent else {
                throw Matrix.Error("Couldn't convert content")
            }
            switch messageContent.msgtype {
            case .audio:
                guard let audioContent = messageContent as? mAudioContent else {
                    throw Matrix.Error("Couldn't convert audio message content")
                }
                try container.encode(audioContent, forKey: .content)
                
            case .text:
                guard let textContent = messageContent as? mTextContent else {
                    throw Matrix.Error("Couldn't convert audio message content")
                }
                try container.encode(textContent, forKey: .content)
                
            case .emote:
                guard let emoteContent = messageContent as? mEmoteContent else {
                    throw Matrix.Error("Couldn't convert audio message content")
                }
                try container.encode(emoteContent, forKey: .content)
                
            case .notice:
                guard let noticeContent = messageContent as? mNoticeContent else {
                    throw Matrix.Error("Couldn't convert audio message content")
                }
                try container.encode(noticeContent, forKey: .content)
                
            case .image:
                guard let imageContent = messageContent as? mImageContent else {
                    throw Matrix.Error("Couldn't convert audio message content")
                }
                try container.encode(imageContent, forKey: .content)
                
            case .file:
                guard let fileContent = messageContent as? mFileContent else {
                    throw Matrix.Error("Couldn't convert audio message content")
                }
                try container.encode(fileContent, forKey: .content)
                
            case .video:
                guard let videoContent = messageContent as? mVideoContent else {
                    throw Matrix.Error("Couldn't convert audio message content")
                }
                try container.encode(videoContent, forKey: .content)
                
            case .location:
                guard let locationContent = messageContent as? mLocationContent else {
                    throw Matrix.Error("Couldn't convert audio message content")
                }
                try container.encode(locationContent, forKey: .content)
                
            }
            
        case .mRoomEncryption:
            guard let encryptionContent = content as? RoomEncryptionContent else {
                throw Matrix.Error("Couldn't convert content")
            }
            try container.encode(encryptionContent, forKey: .content)
            
        case .mEncrypted:
            guard let encryptedContent = content as? EncryptedEventContent else {
                throw Matrix.Error("Couldn't convert content")
            }
            try container.encode(encryptedContent, forKey: .content)
            
        case .mRoomName:
            guard let roomNameContent = content as? RoomNameContent else {
                throw Matrix.Error("Couldn't convert content")
            }
            try container.encode(roomNameContent, forKey: .content)
            
        case .mRoomTopic:
            guard let roomTopicContent = content as? RoomTopicContent else {
                throw Matrix.Error("Couldn't convert content")
            }
            try container.encode(roomTopicContent, forKey: .content)
            
        case .mTag:
            guard let roomTagContent = content as? RoomTagContent else {
                throw Matrix.Error("Couldn't convert content")
            }
            try container.encode(roomTagContent, forKey: .content)
            
        }
    }
    
}
