//
//  ObservationStore.swift
//
//
//  Created by p-x9 on 2023/01/21.
//
//

import Foundation

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.9)
#error("SCFNotification doesn't support Swift versions below 5.9.")
#endif

/// A type that represents a notification name.
public typealias SCFNotificationName = String

/// A type that represents a notification user info dictionary.
public typealias SCFNotificationUserInfo = [String: Any]

/// A type that represents a notification observer.
public typealias SCFNotificationObserver = AnyObject & Sendable

/// A type that represents a notification object.
public typealias SCFNotificationObject = AnyObject

/// A type that represents a notification callback.
/// This is a closure that will be called when a notification is received.
/// The closure takes the following parameters:
/// - `center`: The notification center that posted the notification.
/// - `observer`: The observer that received the notification.
/// - `name`: The name of the notification.
/// - `object`: The object that posted the notification.
/// - `userInfo`: The user info dictionary that was included with the notification.
public typealias SCFNotificationCallback<Observer: SCFNotificationObserver, Object: SCFNotificationObject> = @Sendable (_ center: CFNotificationCenter?,
                                                                                                                        _ observer: Observer?,
                                                                                                                        _ name: SCFNotificationName?,
                                                                                                                        _ object: Object?,
                                                                                                                        _ userInfo: SCFNotificationUserInfo?) -> Void

/// This is a wrapper around `CFNotificationCenter` to provide a more Swift-friendly API.
public class SCFNotificationCenter: @unchecked Sendable {
    public static let local: SCFNotificationCenter = .init(center: .local)
    public static let darwinNotify: SCFNotificationCenter = .init(center: .darwinNotify)

#if os(macOS)
    public static let distributed: SCFNotificationCenter = .init(center: .distributed)
#endif

    private let center: CenterType

    init(center: CenterType) {
        self.center = center
    }

    /// Adds an observer for the specified notification name and object.
    /// - Parameters:
    ///   - observer: The observer to add.
    ///   - name: The name of the notification to observe. If `nil`, the observer will receive all notifications.
    ///   - object: The object to observe. If `nil`, the observer will receive notifications from all objects.
    ///   - suspensionBehavior: The suspension behavior for the observer.
    ///   - callback: The callback to be called when the notification is received.
    public func addObserver<Observer: SCFNotificationObserver>(observer: Observer, name: SCFNotificationName?, object: SCFNotificationObject? = nil, suspensionBehavior: SCFNotificationCenter.SuspensionBehavior, callback: @escaping SCFNotificationCallback<Observer, SCFNotificationObject>) {
        Self.addObserver(center: center, observer: observer, name: name, object: object, suspensionBehavior: suspensionBehavior, callback: callback)
    }

    /// Removes the observer for the specified notification name and object.
    /// - Parameters:
    ///   - observer: The observer to remove.
    ///   - name: The name of the notification to stop observing. If `nil`, the observer will stop receiving all notifications.
    ///   - object: The object to stop observing. If `nil`, the observer will stop receiving notifications from all objects.
    public func removeObserver<Observer: SCFNotificationObserver>(observer: Observer, name: SCFNotificationName?, object: SCFNotificationObject? = nil) {
        Self.removeObserver(center: center, observer: observer, name: name, object: object)
    }

    /// Removes all observers for the specified observer.
    /// - Parameter observer: The observer to remove.
    public func removeEveryObserver<Observer: SCFNotificationObserver>(observer: Observer) {
        Self.removeEveryObserver(center: center, observer: observer)
    }

    /// Posts a notification with the specified name, object, and user info.
    /// - Parameters:
    ///   - name: The name of the notification to post.
    ///   - object: The object to post the notification for. If `nil`, the notification will be posted for all objects.
    ///   - userInfo: The user info dictionary to include with the notification.
    ///   - deliverImmediately: Whether to deliver the notification immediately.
    public func postNotification(name: SCFNotificationName, object: SCFNotificationObject? = nil, userInfo: SCFNotificationUserInfo, deliverImmediately: Bool) {
        Self.postNotification(center: center, name: name, object: object, userInfo: userInfo, deliverImmediately: deliverImmediately)
    }

    /// Posts a notification with the specified name, object, and user info.
    /// - Parameters:
    ///   - name: The name of the notification to post.
    ///   - object: The object to post the notification for. If `nil`, the notification will be posted for all objects.
    ///   - userInfo: The user info dictionary to include with the notification.
    ///   - options: The options for the notification.
    public func postNotification(name: SCFNotificationName, object: SCFNotificationObject? = nil, userInfo: SCFNotificationUserInfo, options: Set<Option>) {
        Self.postNotification(center: center, name: name, object: object, userInfo: userInfo, options: options)
    }
}

public extension SCFNotificationCenter {
    /// Adds an observer for the specified notification name and object.
    /// - Parameters:
    ///   - center: The notification center to add the observer to.
    ///   - observer: The observer to add.
    ///   - name: The name of the notification to observe. If `nil`, the observer will receive all notifications.
    ///   - object: The object to observe. If `nil`, the observer will receive notifications from all objects.
    ///   - suspensionBehavior: The suspension behavior for the observer.
    ///   - callback: The callback to be called when the notification is received.
    static func addObserver<Observer: SCFNotificationObserver>(center: CenterType, observer: Observer, name: SCFNotificationName?, object: SCFNotificationObject? = nil, suspensionBehavior: SCFNotificationCenter.SuspensionBehavior, callback: @escaping SCFNotificationCallback<Observer, SCFNotificationObject>) {
        var observation = Observation(name: name as CFString?, observer: observer, object: object, notify: callback)

        if center == .darwinNotify {
            observation.object = nil
        }

        ObservationStore.shared.add(observation, center: center)

        CFNotificationCenterAddObserver(center.cfNotificationCenter, observation.observerPtr, { center, observer, name, object, userInfo in
            guard let center = center?.centerType else { return }
            ObservationStore.shared.notifyIfNeeded(center: center, observer: observer, name: name, object: object, userInfo: userInfo)
        }, observation.name, observation.objectPtr, suspensionBehavior.cfNotificationSuspensionBehavior)
    }

    /// Removes the observer for the specified notification name and object.
    /// - Parameters:
    ///   - center: The notification center to remove the observer from.
    ///   - observer: The observer to remove.
    ///   - name: The name of the notification to stop observing. If `nil`, the observer will stop receiving all notifications.
    ///   - object: The object to stop observing. If `nil`, the observer will stop receiving notifications from all objects.
    static func removeObserver<Observer: SCFNotificationObserver>(center: CenterType, observer: Observer, name: SCFNotificationName?, object: SCFNotificationObject? = nil) {
        let observer = unsafeBitCast(observer, to: UnsafeMutableRawPointer.self)

        var objectPtr: UnsafeRawPointer?
        if let object {
            objectPtr = unsafeBitCast(object, to: UnsafeRawPointer.self)
        }

        if center == .darwinNotify {
            objectPtr = nil
        }

        ObservationStore.shared.remove(center: center, observer: observer, name: name?.cfNotificationName, object: objectPtr)

        CFNotificationCenterRemoveObserver(center.cfNotificationCenter, observer, name?.cfNotificationName, objectPtr)
    }

    /// Removes all observers for the specified observer.
    /// - Parameters:
    ///  - center: The notification center to remove the observer from.
    ///  - observer: The observer to remove.
    static func removeEveryObserver<Observer: SCFNotificationObserver>(center: CenterType, observer: Observer) {
        let observer = unsafeBitCast(observer, to: UnsafeMutableRawPointer.self)

        ObservationStore.shared.removeEvery(center: center, observer: observer)
        CFNotificationCenterRemoveEveryObserver(center.cfNotificationCenter, observer)
    }

    /// Posts a notification with the specified name, object, and user info.
    /// - Parameters:
    ///   - center: The notification center to post the notification to.
    ///   - name: The name of the notification to post.
    ///   - object: The object to post the notification for. If `nil`, the notification will be posted for all objects.
    ///   - userInfo: The user info dictionary to include with the notification.
    ///   - deliverImmediately: Whether to deliver the notification immediately.
    static func postNotification(center: CenterType, name: SCFNotificationName, object: SCFNotificationObject? = nil, userInfo: SCFNotificationUserInfo, deliverImmediately: Bool) {
        var objectPtr: UnsafeRawPointer?
        if let object {
            objectPtr = unsafeBitCast(object, to: UnsafeRawPointer.self)
        }

        CFNotificationCenterPostNotification(center.cfNotificationCenter, name.cfNotificationName, objectPtr, userInfo.cfDictionary, deliverImmediately)
    }

    /// Posts a notification with the specified name, object, and user info.
    /// - Parameters:
    ///   - center: The notification center to post the notification to.
    ///   - name: The name of the notification to post.
    ///   - object: The object to post the notification for. If `nil`, the notification will be posted for all objects.
    ///   - userInfo: The user info dictionary to include with the notification.
    ///   - options: The options for the notification.
    static func postNotification(center: CenterType, name: SCFNotificationName, object: SCFNotificationObject? = nil, userInfo: SCFNotificationUserInfo, options: Set<Option>) {
        var objectPtr: UnsafeRawPointer?
        if let object {
            objectPtr = unsafeBitCast(object, to: UnsafeRawPointer.self)
        }

        let options: CFOptionFlags = options.reduce(into: 0) { partialResult, option in
            partialResult = partialResult | option.flag
        }

        CFNotificationCenterPostNotificationWithOptions(center.cfNotificationCenter, name.cfNotificationName, objectPtr, userInfo.cfDictionary, options)
    }
}

public extension SCFNotificationCenter {
    /// The type of notification center to use.
    /// - local: The local notification center.
    /// - darwinNotify: The Darwin notification center.
    /// - distributed: The distributed notification center (macOS only).
    enum CenterType: Sendable {
        case local
        case darwinNotify

#if os(macOS)
        case distributed
#endif

        public var cfNotificationCenter: CFNotificationCenter {
            switch self {
            case .local:
                return CFNotificationCenterGetLocalCenter()
            case .darwinNotify:
                return CFNotificationCenterGetDarwinNotifyCenter()
#if os(macOS)
            case .distributed:
                return CFNotificationCenterGetDistributedCenter()
#endif
            }
        }
    }
}

public extension SCFNotificationCenter {
    enum Option: Sendable, CaseIterable {
        case deliverImmediately
        case postToAllSessions

        var flag: CFOptionFlags {
            switch self {
            case .deliverImmediately: return kCFNotificationDeliverImmediately
            case .postToAllSessions: return kCFNotificationPostToAllSessions
            }
        }
    }
}

public extension SCFNotificationCenter {
    enum SuspensionBehavior: Sendable {
        case drop
        case coalesce
        case hold
        case deliverImmediately

        var cfNotificationSuspensionBehavior: CFNotificationSuspensionBehavior {
            switch self {
            case .drop:
                return .drop
            case .coalesce:
                return .coalesce
            case .hold:
                return .hold
            case .deliverImmediately:
                return .deliverImmediately
            }
        }
    }
}
