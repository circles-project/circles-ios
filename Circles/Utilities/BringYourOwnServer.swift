//
//  BringYourOwnServer.swift
//  Circles
//
//  Created by Charles Wright on 8/10/21.
//

import Foundation

enum BringYourOwnServer {

    static func loadProducts() -> [String]? {
        // We can store those in the app bundle as Apple explains here https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/loading_in-app_product_identifiers
        guard let url = Bundle.main.url(forResource: "ByosProducts", withExtension: "plist") else
        {
            fatalError("Unable to resolve url for in the bundle.")
        }

        guard
            let data = try? Data(contentsOf: url),
            let productIdentifiers = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String]
        else {
            print("BYOS\tFailed to get product identifiers")
            return nil
        }
        
        print("BYOS\tFound product identifiers:")
        for identifier in productIdentifiers {
            print("BYOS\t\tFound product [\(identifier)]")
        }
        return productIdentifiers
    }
}
