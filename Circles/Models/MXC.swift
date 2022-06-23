//
//  MXC.swift
//  Circles
//
//  Created by Charles Wright on 6/20/22.
//

import Foundation

struct MXC: Codable, LosslessStringConvertible {
    
    var serverName: String
    var mediaId: String
    
    var description: String {
        "mxc://\(serverName)/\(mediaId)"
    }
    
    init?(_ description: String) {
        guard description.starts(with: "mxc://")
        else { return nil }
        
        let toks = description.split(separator: "/", omittingEmptySubsequences: true)
        
        guard toks.count == 3
        else { return nil }
        
        self.serverName = String(toks[1])
        self.mediaId = String(toks[2])
    }

    init(from decoder: Decoder) throws {
        let mxc = try String(from: decoder)
        guard let me: MXC = .init(mxc) else {
            throw Matrix.Error("Invalid MXC URI")
        }
        self = me
    }
}
