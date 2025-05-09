//
//  CFNotificationCenter+.swift
//
//
//  Created by p-x9 on 2023/01/21.
//
//

import Foundation

public extension CFNotificationCenter {
    static var local: CFNotificationCenter {
        CFNotificationCenterGetLocalCenter()
    }

    static var darwinNotify: CFNotificationCenter {
        CFNotificationCenterGetDarwinNotifyCenter()
    }

#if os(macOS)
    static var distributed: CFNotificationCenter {
        CFNotificationCenterGetDistributedCenter()
    }
#endif
}

extension CFNotificationCenter {
    var centerType: SCFNotificationCenter.CenterType? {
        switch self {
        case CFNotificationCenterGetLocalCenter(): return .local
        case CFNotificationCenterGetDarwinNotifyCenter(): return .darwinNotify
#if os(macOS)
        case CFNotificationCenterGetDistributedCenter(): return .distributed
#endif
        default: return .none
        }
    }
}
