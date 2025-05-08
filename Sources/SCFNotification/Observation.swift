//
//  Observation.swift
//
//
//  Created by p-x9 on 2023/01/21.
//
//

import Foundation

struct Observation: @unchecked Sendable {
    typealias SCFNotificationCallbackObjC = @Sendable (CFNotificationCenter?, UnsafeMutableRawPointer?, CFNotificationName?, UnsafeRawPointer?, CFDictionary?) -> Void

    let name: CFString?
    var notificationName: CFNotificationName? {
        guard let name else {
            return nil
        }
        return .init(name)
    }

    weak var observer: SCFNotificationObserver?
    weak var object: SCFNotificationObject?

    var observerPtr: UnsafeMutableRawPointer? {
        guard let observer = observer else {
            return nil
        }
        return unsafeBitCast(observer, to: UnsafeMutableRawPointer?.self)
    }

    var objectPtr: UnsafeRawPointer? {
        guard let object = object else {
            return nil
        }
        return unsafeBitCast(object, to: UnsafeRawPointer?.self)
    }

    let notify: SCFNotificationCallbackObjC

    init<Observer: SCFNotificationObserver, Object: SCFNotificationObject>(name: CFString?, observer: Observer, object: Object?, notify: SCFNotificationCallback<Observer, Object>?) {
        self.name = name
        self.observer = observer
        self.object = object

        self.notify = { center, observerPtr, name, objectPtr, userInfo in
            var observer: Observer?
            if let observerPtr {
                observer = unsafeBitCast(observerPtr, to: Observer?.self)
            }
            var object: Object?
            if let objectPtr, center?.centerType != .darwinNotify {
                object = unsafeBitCast(objectPtr, to: Object?.self)
            }
            notify?(center, observer, name?.scfNotificationName, object, userInfo?.scfNotificationUserInfo)
        }
    }
}
