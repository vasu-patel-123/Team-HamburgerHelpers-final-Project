//
//  Item.swift
//  Taskii
//
//  Created by Jaron Durkee on 3/25/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
