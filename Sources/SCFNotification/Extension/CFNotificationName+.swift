//
//  CFNotificationName+.swift
//  SCFNotification
//
//  Created by CodingIran on 2025/5/8.
//

import Foundation

public extension CFNotificationName {
    init(name: SCFNotificationName) {
        self = CFNotificationName(rawValue: name as CFString)
    }

    var scfNotificationName: SCFNotificationName {
        rawValue as SCFNotificationName
    }
}

public extension SCFNotificationName {
    var cfNotificationName: CFNotificationName {
        .init(name: self)
    }
}
