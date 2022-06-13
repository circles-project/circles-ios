//
//  MatrixWellKnown.swift
//  Circles
//
//  Created by Charles Wright on 7/29/21.
//

import Foundation

struct MatrixWellKnown: Codable {
    struct ServerConfig: Codable {
        var baseUrl: String
    }
    var homeserver: ServerConfig
    var identityserver: ServerConfig

    enum CodingKeys: String, CodingKey {
        case homeserver = "m.homeserver"
        case identityserver = "m.identityServer"
    }
}

/*
    init(from decoder: Decoder) throws {
        print("WELLKNOWN\tTrying to initialize from a decoder")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            print("WELLKNOWN\tDecoding homeserver")
            homeserver = try container.decode(ServerConfig.self, forKey: .homeserver)
        } catch {
            print("WELLKNOWN\tFailed to decode homeserver")
            throw KSError(message: "Failed to decode homeserver")
        }
        do {
            print("WELLKNOWN\tDecoding identity server")
            identityserver = try container.decode(ServerConfig.self, forKey: .identityserver)
        } catch {
            print("WELLKNOWN\tFailed to decode identity server")
            throw KSError(message: "Failed to decode identity server")
        }
        print("WELLKNOWN\tIgnoring any E2EE info for now...")
    }
}
*/
