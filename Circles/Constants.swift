//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  Constants.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/14/20.
//

// swiftlint:disable identifier_name

import Foundation

let APP_PREFIX = "social.kombucha"

let ROOM_TAG_FOLLOWING = APP_PREFIX + ".following"
let ROOM_TAG_OUTBOUND = APP_PREFIX + ".outbound"
let ROOM_TAG_GROUP = APP_PREFIX + ".group"
let ROOM_TAG_CHAT = APP_PREFIX + ".chat"
let ROOM_TAG_PHOTOS = APP_PREFIX + ".photos"
let ROOM_TAG_NOTICES = APP_PREFIX + ".notices"

let EVENT_TYPE_CIRCLES = "social.kombucha.circles"
let EVENT_TYPE_CONFIGURED = "social.kombucha.configured"
let EVENT_TYPE_ROOMTYPE = "social.kombucha.room_type"

// FIXME: Use new m.social room types
let ROOM_TYPE_CIRCLE = APP_PREFIX + ".circle"
let ROOM_TYPE_GROUP = APP_PREFIX + ".group"
let ROOM_TYPE_CHAT = APP_PREFIX + ".chat"
let ROOM_TYPE_PHOTOS = APP_PREFIX + ".photos"

// Use this for the pseudo-circle containing all of the rooms
// that we're following.
let CIRCLE_TAG_FOLLOWING = APP_PREFIX + ".following"

let KOMBUCHA_DEBUG = false

let PLAINTEXT_CACHE_FOLDER: String? = nil
let DECRYPTED_CACHE_FOLDER: String = "decrypted"

// For some reason the BlurHash code needs to be told
// the dimensions of the BH images.  I thought they
// somehow encoded this info into the hash, but oh well...
let BLURHASH_WIDTH: Int = 6

let BYOS_ENABLED = true
let BYOS_REQUIRE_SUBSCRIPTION = false

let LOGIN_STAGE_TOKEN_KOMBUCHA = "social.kombucha.login.signup_token"
let LOGIN_STAGE_TOKEN_MATRIX = "m.login.registration_token"
let LOGIN_STAGE_TOKEN_MSC3231 = "org.matrix.msc3231.login.registration_token"
let LOGIN_STAGE_APPLE_SUBSCRIPTION = "social.kombucha.login.subscription.apple"
let LOGIN_STAGE_TERMS_OF_SERVICE = "m.login.terms"
let LOGIN_STAGE_VERIFY_EMAIL = "m.login.email.identity"
let LOGIN_STAGE_DUMMY = "m.login.dummy"

let RECOVERY_MIN_INTERVAL = 60.0

let DEFAULT_DOMAIN = "circu.li"
let SIGNUP_HOMESERVER_URL = URL(string: "https://matrix.\(DEFAULT_DOMAIN)/")!

let AUTH_TYPE_BSSPEKE_ENROLL_OPRF = "m.enroll.bsspeke-ecc.oprf"
let AUTH_TYPE_BSSPEKE_ENROLL_SAVE = "m.enroll.bsspeke-ecc.save"
let AUTH_TYPE_BSSPEKE_LOGIN_OPRF = "m.login.bsspeke-ecc.oprf"
let AUTH_TYPE_BSSPEKE_LOGIN_VERIFY = "m.login.bsspeke-ecc.verify"
