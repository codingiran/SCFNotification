@testable import SCFNotification
@preconcurrency import XCTest

class SCFDarwinNotificationTests: SCFNotificationTests, @unchecked Sendable {
    override var centerType: SCFNotificationCenter.CenterType {
        .darwinNotify
    }

    // Customized
    // object is ignored
    override func testObserveNamedWithObject() {
        let exp = expectation(description: #function)

        notificationCenter
            .addObserver(observer: self,
                         name: #function,
                         object: "hello" as CFString,
                         suspensionBehavior: .deliverImmediately)
        { center, observer, name, object, _ in
            XCTAssertEqual(observer, self)
            XCTAssertEqual(center?.centerType, self.centerType)
            XCTAssertEqual(name, #function)
            XCTAssertNil(object)
            exp.fulfill()
        }

        notificationCenter.postNotification(name: #function,
                                            object: "hello" as CFString,
                                            userInfo: [:],
                                            deliverImmediately: true)

        wait(for: [exp], timeout: timeout)
        removeEveryObserver()
    }

    override func testObserveNamedWithObjectShouldNotCalled() {
        let exp = expectation(description: #function)

        notificationCenter
            .addObserver(observer: self,
                         name: #function,
                         object: "hello-aaa" as CFString,
                         suspensionBehavior: .deliverImmediately)
        { _, _, _, _, _ in
            exp.fulfill()
        }

        notificationCenter.postNotification(name: #function,
                                            object: "hello" as CFString,
                                            userInfo: [:],
                                            deliverImmediately: true)

        wait(for: [exp], timeout: timeout)

        removeEveryObserver()
    }

    // Custimized
    // If center is a Darwin notification center, this value must not be NULL.
    override func testObserveNilNamed() {
        let exp = expectation(description: #function)
        exp.isInverted = true

        notificationCenter
            .addObserver(observer: self,
                         name: nil,
                         suspensionBehavior: .deliverImmediately)
        { _, _, _, _, _ in
            exp.fulfill()
        }

        notificationCenter.postNotification(name: #function,
                                            userInfo: [:],
                                            deliverImmediately: true)

        wait(for: [exp], timeout: timeout)

        removeEveryObserver()
    }

    // Custimized
    // If center is a Darwin notification center, this value must not be NULL.
    override func testObserveNilNamedWithObject() {
        let exp = expectation(description: #function)
        exp.isInverted = true

        notificationCenter
            .addObserver(observer: self,
                         name: nil,
                         object: "hello" as CFString,
                         suspensionBehavior: .deliverImmediately)
        { _, _, _, _, _ in
            exp.fulfill()
        }

        notificationCenter.postNotification(name: #function,
                                            object: "hello" as CFString,
                                            userInfo: [:],
                                            deliverImmediately: true)

        wait(for: [exp], timeout: timeout)

        removeEveryObserver()
    }
}
