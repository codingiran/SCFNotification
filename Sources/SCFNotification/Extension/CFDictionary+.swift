//
//  CFDictionary+.swift
//  SCFNotification
//
//  Created by CodingIran on 2025/5/8.
//

import Foundation

public extension CFDictionary {
    static func from(_ dict: SCFNotificationUserInfo) -> CFDictionary {
        dict as CFDictionary
    }

    var scfNotificationUserInfo: SCFNotificationUserInfo {
        let nsDict = unsafeBitCast(self, to: NSDictionary.self)
        var result = SCFNotificationUserInfo()

        for (key, value) in nsDict {
            if let keyStr = key as? String {
                result[keyStr] = value
            }
        }

        return result
    }
}

public extension SCFNotificationUserInfo {
    var cfDictionary: CFDictionary {
        CFDictionary.from(self)
    }
}
