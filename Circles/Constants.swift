//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  Constants.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/14/20.
//

// swiftlint:disable identifier_name

import Foundation

let APP_PREFIX = "org.futo"


let ROOM_TAG_CIRCLES_SPACE_ROOT = "org.futo.circles.space.root"



let ROOM_TYPE_CIRCLE = APP_PREFIX+".social.timeline"
let ROOM_TYPE_GROUP = APP_PREFIX+".social.group"
let ROOM_TYPE_PHOTOS = APP_PREFIX+".social.gallery"

let CIRCLES_DEBUG = false

let PLAINTEXT_CACHE_FOLDER: String? = nil
let DECRYPTED_CACHE_FOLDER: String = "decrypted"

// For some reason the BlurHash code needs to be told
// the dimensions of the BH images.  I thought they
// somehow encoded this info into the hash, but oh well...
let BLURHASH_WIDTH: Int = 6

let RECOVERY_MIN_INTERVAL = 60.0

let DEFAULT_DOMAIN = "circu.li"
