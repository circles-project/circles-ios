//
//  CanonicalAliasContent.swift
//  
//
//  Created by Charles Wright on 5/18/22.
//

import Foundation

extension Matrix {

    struct CanonicalAliasContent: Codable {
        let alias: String
        let altAliases: [String]
    }

}
