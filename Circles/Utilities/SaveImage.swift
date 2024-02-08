//
//  SaveImage.swift
//  Circles
//
//  Created by Charles Wright on 2/8/24.
//

import Foundation
import Matrix

func saveEncryptedImage(file: Matrix.mEncryptedFile,
                        session: Matrix.Session
) async throws {

    guard let data = try? await session.downloadAndDecryptData(file),
          let image = UIImage(data: data)
    else {
        print("Failed to get image for encrypted URL \(file.url)")
        return
    }
    
    print("Saving image...")
    let imageSaver = ImageSaver()
    await imageSaver.writeToPhotoAlbum(image: image)
    print("Successfully saved image from \(file.url)")
}

func savePlaintextImage(url: MXC,
                        session: Matrix.Session
) async throws {
    print("Trying to save image from URL \(url)")
    guard let data = try? await session.downloadData(mxc: url),
          let image = UIImage(data: data)
    else {
        print("Failed to get image for url \(url)")
        return
    }
    
    print("Saving image...")
    let imageSaver = ImageSaver()
    await imageSaver.writeToPhotoAlbum(image: image)
    print("Successfully saved image from \(url)")
}

func saveImage(content: Matrix.mImageContent,
               session: Matrix.Session
) async throws {
    // Coming in, we have no idea what this m.image content may contain
    // It may have any mix of encrypted / unencrypted full-res image and thumbnail
    // So we try to be a little bit smart
    //   - We prefer the full-res image over the thumbnail
    //   - When trying to find an image (either full-res or thumbnail) we prefer the encrypted version over unencrypted
    // In other words, our preferences are:
    //   1. Full-res, encrypted
    //   2. Full-res, non encrypted
    //   3. Thumbnail, encrypted
    //   4. Thumbnail, non encrypted
    
    if let fullResFile = content.file {
        try await saveEncryptedImage(file: fullResFile, session: session)
    }
    else if let fullResUrl = content.url {
        try await savePlaintextImage(url: fullResUrl, session: session)
    }
    else if let thumbnailFile = content.thumbnail_file {
        try await saveEncryptedImage(file: thumbnailFile, session: session)
    }
    else if let thumbnailUrl = content.thumbnail_url {
        try await savePlaintextImage(url: thumbnailUrl, session: session)
    }
    else {
        print("Error: Can't save image -- No encrypted file or URL")
    }
}
