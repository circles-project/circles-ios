//
//  ProfileSpace.swift
//  Circles
//
//  Created by Charles Wright on 7/31/23.
//

import Foundation
import Matrix

/*
  This is the type to use for *our* profile space room,
  where we know that we are a joined member of every child room.
  To represent other users' profile spaces, use PersonRoom instead.
 */

typealias ProfileSpace = ContainerRoom<Matrix.Room>
