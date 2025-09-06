//
//  Item.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
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
