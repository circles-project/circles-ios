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


let ROOM_TAG_CIRCLES_SPACE_ROOT = "org.futo.space.root"
let ROOM_TAG_MY_CIRCLES = "org.futo.space.circles"
let ROOM_TAG_MY_GROUPS = "org.futo.space.groups"
let ROOM_TAG_MY_PEOPLE = "org.futo.space.people"
let ROOM_TAG_MY_PHOTOS = "org.futo.space.photos"
let ROOM_TAG_MY_PROFILE = "org.futo.space.circles.shared"


let ROOM_TYPE_CIRCLE = APP_PREFIX+".social.timeline"
let ROOM_TYPE_GROUP = APP_PREFIX+".social.group"
let ROOM_TYPE_PHOTOS = APP_PREFIX+".social.gallery"

//var CIRCLES_DEBUG = false

let PLAINTEXT_CACHE_FOLDER: String? = nil
let DECRYPTED_CACHE_FOLDER: String = "decrypted"

// For some reason the BlurHash code needs to be told
// the dimensions of the BH images.  I thought they
// somehow encoded this info into the hash, but oh well...
let BLURHASH_WIDTH: Int = 6

let RECOVERY_MIN_INTERVAL = 60.0

let DEFAULT_DOMAIN = "circu.li"

let MATRIX_SSSS_KEY_LABEL = "matrix_ssss"
let MATRIX_SSSS_KEYID_LABEL = "matrix_ssss_key_id"

#if DEBUG
    let usDomain = "us.circles-dev.net"
    let euDomain = "nl.circles-dev.net"
#else
    let usDomain = "circu.li"
    let euDomain = "eu.circu.li"
#endif

let ORG_FUTO_BCRYPT_SHA2 = "org.futo.bcrypt-sha2"
let ORG_FUTO_BSSPEKE_ECC = "org.futo.bsspeke-ecc"
