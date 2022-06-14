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
    
    class API {
        var creds: MatrixCredentials
        var baseUrl: URL
        let version: String
        private var apiUrlSession: URLSession   // For making API calls
        private var mediaUrlSession: URLSession // For downloading media
        
        init(creds: MatrixCredentials) throws {
            self.version = "r0"
            
            self.creds = creds
            
            let apiConfig = URLSessionConfiguration.default
            apiConfig.httpAdditionalHeaders = [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(creds.accessToken)",
            ]
            apiConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.apiUrlSession = URLSession(configuration: apiConfig)
            
            let mediaConfig = URLSessionConfiguration.default
            mediaConfig.httpAdditionalHeaders = [
                "Authorization": "Bearer \(creds.accessToken)",
            ]
            mediaConfig.requestCachePolicy = .returnCacheDataElseLoad
            self.mediaUrlSession = URLSession(configuration: mediaConfig)
            
            guard let wk = creds.wellKnown
            else {
                let msg = "Homeserver info is required to instantiate a Matrix API"
                print(msg)
                throw Matrix.Error(msg)
            }
            
            self.baseUrl = URL(string: wk.homeserver.baseUrl)!
        }
        
        func call(method: String, path: String, body: AnyCodable? = nil, expectedStatuses: [Int] = [200]) async throws -> (Data, HTTPURLResponse) {
            let url = URL(string: path, relativeTo: baseUrl)!
            var request = URLRequest(url: url)
            request.httpMethod = method
            
            if let codableBody = body {
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                request.httpBody = try encoder.encode(codableBody)
            }
            
            let (data, response) = try await apiUrlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  expectedStatuses.contains(httpResponse.statusCode)
            else {
                throw Matrix.Error("Matrix API call rejected")
            }
            
            return (data, httpResponse)
        }
        
        // https://spec.matrix.org/v1.2/client-server-api/#put_matrixclientv3profileuseriddisplayname
        func setDisplayName(_ name: String) async throws {
            let (_, _) = try await call(method: "PUT",
                                                  path: "/_matrix/client/\(version)/profile/\(creds.userId)/displayname",
                                                  body: [
                                                    "displayname": name,
                                                  ])
        }
        
        func setAvatarImage(_ image: UIImage) async throws {
            // First upload the image
            let url = try await uploadImage(image, maxSize: CGSize(width: 256, height: 256))
            // Then set that as our avatar
            try await setAvatarUrl(url)
        }
        
        func setAvatarUrl(_ url: String) async throws {
            let (_,_) = try await call(method: "PUT",
                                       path: "_matrix/client/\(version)/profile/\(creds.userId)/avatar_url",
                                       body: [
                                         "avatar_url": url,
                                       ])
        }
        
        func uploadImage(_ original: UIImage, maxSize: CGSize, quality: CGFloat = 0.90) async throws -> String {
            guard let scaled = downscale_image(from: original, to: maxSize)
            else {
                let msg = "Failed to downscale image"
                print(msg)
                throw Matrix.Error(msg)
            }
            
            let uri = try await uploadImage(scaled, quality: quality)
            return uri
        }
        
        func uploadImage(_ original: UIImage, quality: CGFloat = 0.90) async throws -> String {
            let url = URL(string: "/_matrix/media/\(version)/upload", relativeTo: baseUrl)!
            var request = URLRequest(url: url)
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            
            guard let jpeg = original.jpegData(compressionQuality: quality)
            else {
                let msg = "Failed to encode image as JPEG"
                print(msg)
                throw Matrix.Error(msg)
            }
            
            let (data, response) = try await mediaUrlSession.upload(for: request, from: jpeg)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  [200].contains(httpResponse.statusCode)
            else {
                let msg = "Upload request failed"
                print(msg)
                throw Matrix.Error(msg)
            }
            
            struct UploadResponse: Codable {
                var contentUri: String
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            guard let responseBody = try? decoder.decode(UploadResponse.self, from: data)
            else {
                let msg = "Failed to decode upload response"
                print(msg)
                throw Matrix.Error(msg)
            }
            
            return responseBody.contentUri
        }
    }
    
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
}
