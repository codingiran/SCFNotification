import Foundation

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.9)
#error("SCFNotification doesn't support Swift versions below 5.9.")
#endif

public typealias AnySendableObject = AnyObject & Sendable

public typealias SCFNotificationCallback<Observer: AnySendableObject, Object: AnySendableObject>
    = @Sendable (_ center: CFNotificationCenter?, _ observer: Observer?, _ name: CFNotificationName?, _ object: Object?, _ userInfo: CFDictionary?) -> Void

public class SCFNotificationCenter: @unchecked Sendable
{
    public static let local: SCFNotificationCenter = .init(center: .local)
    public static let darwinNotify: SCFNotificationCenter = .init(center: .darwinNotify)

#if os(macOS)
    public static let distributed: SCFNotificationCenter = .init(center: .distributed)
#endif

    private let center: CenterType

    init(center: CenterType)
    {
        self.center = center
    }

    public func addObserver<Observer: AnySendableObject>(observer: Observer,
                                                         name: CFNotificationName?,
                                                         object: AnySendableObject? = nil,
                                                         suspensionBehavior: CFNotificationSuspensionBehavior,
                                                         callback: @escaping SCFNotificationCallback<Observer, AnySendableObject>)
    {
        Self.addObserver(center: center, observer: observer, name: name, object: object, suspensionBehavior: suspensionBehavior, callback: callback)
    }

    public func removeObserver<Observer: AnySendableObject>(observer: Observer,
                                                            name: CFNotificationName?,
                                                            object: AnySendableObject? = nil)
    {
        Self.removeObserver(center: center,
                            observer: observer,
                            name: name,
                            object: object)
    }

    public func removeEveryObserver<Observer: AnySendableObject>(observer: Observer)
    {
        Self.removeEveryObserver(center: center, observer: observer)
    }

    public func postNotification(name: CFNotificationName,
                                 object: AnySendableObject? = nil,
                                 userInfo: CFDictionary,
                                 deliverImmediately: Bool)
    {
        Self.postNotification(center: center, name: name, object: object, userInfo: userInfo, deliverImmediately: deliverImmediately)
    }

    public func postNotification(name: CFNotificationName,
                                 object: AnySendableObject? = nil,
                                 userInfo: CFDictionary,
                                 options: Set<Option>)
    {
        Self.postNotification(center: center, name: name, object: object, userInfo: userInfo, options: options)
    }
}

public extension SCFNotificationCenter
{
    static func addObserver<Observer: AnySendableObject>(center: CenterType,
                                                         observer: Observer,
                                                         name: CFNotificationName?,
                                                         object: AnySendableObject? = nil,
                                                         suspensionBehavior: CFNotificationSuspensionBehavior,
                                                         callback: @escaping SCFNotificationCallback<Observer, AnySendableObject>)
    {
        var observation = Observation(name: name?.rawValue, observer: observer, object: object, notify: callback)

        if center == .darwinNotify
        {
            observation.object = nil
        }

        ObservationStore.shared.add(observation, center: center)

        CFNotificationCenterAddObserver(center.cfNotificationCenter, observation.observerPtr, { center, observer, name, object, userInfo in
            guard let center = center?.centerType else { return }
            ObservationStore.shared.notifyIfNeeded(center: center, observer: observer, name: name, object: object, userInfo: userInfo)
        }, observation.name, observation.objectPtr, suspensionBehavior)
    }

    static func removeObserver<Observer: AnySendableObject>(center: CenterType,
                                                            observer: Observer,
                                                            name: CFNotificationName?,
                                                            object: AnySendableObject? = nil)
    {
        let observer = unsafeBitCast(observer, to: UnsafeMutableRawPointer.self)

        var objectPtr: UnsafeRawPointer?
        if let object
        {
            objectPtr = unsafeBitCast(object, to: UnsafeRawPointer.self)
        }

        if center == .darwinNotify
        {
            objectPtr = nil
        }

        ObservationStore.shared.remove(center: center, observer: observer, name: name, object: objectPtr)

        CFNotificationCenterRemoveObserver(center.cfNotificationCenter, observer, name, objectPtr)
    }

    static func removeEveryObserver<Observer: AnySendableObject>(center: CenterType,
                                                                 observer: Observer)
    {
        let observer = unsafeBitCast(observer, to: UnsafeMutableRawPointer.self)

        ObservationStore.shared.removeEvery(center: center, observer: observer)
        CFNotificationCenterRemoveEveryObserver(center.cfNotificationCenter, observer)
    }

    static func postNotification(center: CenterType,
                                 name: CFNotificationName,
                                 object: AnySendableObject? = nil,
                                 userInfo: CFDictionary,
                                 deliverImmediately: Bool)
    {
        var objectPtr: UnsafeRawPointer?
        if let object
        {
            objectPtr = unsafeBitCast(object, to: UnsafeRawPointer.self)
        }

        CFNotificationCenterPostNotification(center.cfNotificationCenter, name, objectPtr, userInfo, deliverImmediately)
    }

    static func postNotification(center: CenterType,
                                 name: CFNotificationName,
                                 object: AnySendableObject? = nil,
                                 userInfo: CFDictionary,
                                 options: Set<Option>)
    {
        var objectPtr: UnsafeRawPointer?
        if let object
        {
            objectPtr = unsafeBitCast(object, to: UnsafeRawPointer.self)
        }

        let options: CFOptionFlags = options.reduce(into: 0)
        { partialResult, option in
            partialResult = partialResult | option.flag
        }

        CFNotificationCenterPostNotificationWithOptions(center.cfNotificationCenter, name, objectPtr, userInfo, options)
    }
}

public extension SCFNotificationCenter
{
    enum CenterType: Sendable
    {
        case local
        case darwinNotify

#if os(macOS)
        case distributed
#endif

        public var cfNotificationCenter: CFNotificationCenter
        {
            switch self
            {
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

public extension SCFNotificationCenter
{
    enum Option: Sendable, CaseIterable
    {
        case deliverImmediately
        case postToAllSessions

        var flag: CFOptionFlags
        {
            switch self
            {
            case .deliverImmediately: return kCFNotificationDeliverImmediately
            case .postToAllSessions: return kCFNotificationPostToAllSessions
            }
        }
    }
}
