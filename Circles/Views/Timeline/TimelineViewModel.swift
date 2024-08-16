//
//  TimelineViewModel.swift
//  Circles
//
//  Created by Charles Wright on 7/30/24.
//

import Foundation
import Matrix

public class TimelineViewModel: ObservableObject {
    @Published var scrollPosition: EventId?
}
