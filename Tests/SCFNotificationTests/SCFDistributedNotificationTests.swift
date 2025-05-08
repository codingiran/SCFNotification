@testable import SCFNotification
import XCTest

class SCFDistributedNotificationTests: SCFNotificationTests, @unchecked Sendable {
    override var centerType: SCFNotificationCenter.CenterType {
        .distributed
    }

    // Custimized
    // For distributed notifications, object must be a CFString object ?
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

    func testObserveNamedWithUserInfo() {
        let exp = expectation(description: #function)
        let key = "key"
        let value = "hello"

        notificationCenter
            .addObserver(observer: self,
                         name: #function,
                         suspensionBehavior: .deliverImmediately)
        { center, observer, name, _, userInfo in
            XCTAssertEqual(observer, self)
            XCTAssertEqual(center?.centerType, self.centerType)
            XCTAssertEqual(name, #function)
            XCTAssertEqual(value, userInfo?[key] as? String)
            exp.fulfill()
        }

        notificationCenter.postNotification(name: #function,
                                            userInfo: [key: value],
                                            deliverImmediately: true)

        wait(for: [exp], timeout: timeout)
        removeEveryObserver()
    }
}
