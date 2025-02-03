//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  Constants.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/14/20.
//

// swiftlint:disable identifier_name

import Foundation
import SwiftUI

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
let ROOM_TYPE_PROFILE = "m.space"
let ROOM_TYPE_SPACE = "m.space"

//var CIRCLES_DEBUG = false

let PLAINTEXT_CACHE_FOLDER: String? = nil
let DECRYPTED_CACHE_FOLDER: String = "decrypted"

// For some reason the BlurHash code needs to be told
// the dimensions of the BH images.  I thought they
// somehow encoded this info into the hash, but oh well...
let BLURHASH_WIDTH: Int = 6

let RECOVERY_MIN_INTERVAL = 60.0
let TIMELINE_FRAME_MAXWIDTH = 800.0
let TIMELINE_BOTTOM_PADDING = 70.0

let MATRIX_SSSS_KEY_LABEL = "matrix_ssss"
let MATRIX_SSSS_KEYID_LABEL = "matrix_ssss_key_id"

let CIRCLES_PRIMARY_DOMAIN = "circles.futo.org"
let CIRCLES_DOMAINS = [
    "circles.futo.org",
    "eu.circles.futo.org",
    "circu.li",
    "eu.circu.li",
    "us.circles-dev.net",
    "nl.circles-dev.net",
]

#if DEBUG
    let usDomain = "us.circles-dev.net"
    let euDomain = "fi.circles-dev.net"
#else
    let usDomain = "circles.futo.org"
    let euDomain = "eu.circles.futo.org"
#endif

let PUSH_GATEWAY_HOSTNAME = "sygnal.\(usDomain)"

let ORG_FUTO_BCRYPT_SHA2 = "org.futo.bcrypt-sha2"
let ORG_FUTO_BSSPEKE_ECC = "org.futo.bsspeke-ecc"

let PRIVACY_POLICY_URL = "https://circles.futo.org/privacy/ios"

let CIRCLES_APP_GROUP_NAME = "group.2W7AC6T8T5.org.futo.circles"

// Push rules -- The leading "." character is intentional
let M_RULE_MASTER = ".m.rule.master"
let M_RULE_INVITE_FOR_ME = ".m.rule.invite_for_me"
let M_RULE_SUPPRESS_NOTICES = ".m.rule.suppress_notices"
let M_RULE_MEMBER_EVENT = ".m.rule.member_event"
let M_RULE_IS_USER_MENTION = ".m.rule.is_user_mention"
let M_RULE_CONTAINS_DISPLAY_NAME = ".m.rule.contains_display_name"
let M_RULE_IS_ROOM_MENTION = ".m.rule.is_room_mention"
let M_RULE_ROOMNOTIF = ".m.rule.roomnotif"
let M_RULE_TOMBSTONE = ".m.rule.tombstone"
let M_RULE_REACTION = ".m.rule.reaction"
let M_RULE_SERVER_ACL = ".m.rule.server_acl"
let M_RULE_SUPPRESS_EDITS = ".m.rule.suppress_edits"
let M_RULE_CONTAINS_USER_NAME = ".m.rule.contains_user_name"
let M_RULE_CALL = ".m.rule.call"
let M_RULE_ENCRYPTED_ROOM_ONE_TO_ONE = ".m.rule.encrypted_room_one_to_one"
let M_RULE_ROOM_ONE_TO_ONE = ".m.rule.room_one_to_one"
let M_RULE_MESSAGE = ".m.rule.message"
let M_RULE_ENCRYPTED = ".m.rule.encrypted"

// Power levels
let CIRCLES_POWER_LEVELS: [PowerLevel] = [-10, 0, 50, 100].map { PowerLevel(power: $0) }

// Colors for the UI
let CIRCLES_COLORS = [
    // From circles-logo-dark.svg
    Color(rgba: 0xffff00ff), // Yellow
    Color(rgba: 0xda70d6ff), // Purple / Fuchsia
    Color(rgba: 0x7afb7aff), // Green (made darker to look better in the app)
    Color(rgba: 0xfa8072ff), // Red / Salmon
    Color(rgba: 0x87ceebff), // Blue
    // Additional colors to provide more variety
    Color(rgba: 0xfaaf72ff), // Orange
    Color(rgba: 0xfa72a4ff), // Pink
]

let DEFAULTS_KEY_ENABLE_GALLERIES = "enable_photo_galleries"
