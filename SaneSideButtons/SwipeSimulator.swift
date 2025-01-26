//
//  SwipeSimulator.swift
//  SaneSideButtons
//
//  Created by Jan Hülsmann on 16.10.22.
//

import AppKit
import Synchronization

final class SwipeSimulator: Sendable {

    enum EventTap: Error {
        case failedSetup
    }

    private enum Keys {
        static let ignored: String = "ignoredApplications"
        static let reverse: String = "reverseButtons"
    }

    private let swipeBegin: [String: Int] = [
        kTLInfoKeyGestureSubtype as String: kTLInfoSubtypeSwipe,
        kTLInfoKeyGesturePhase as String: 1
    ]

    private let swipeLeft: [String: Int] = [
        kTLInfoKeyGestureSubtype as String: kTLInfoSubtypeSwipe,
        kTLInfoKeySwipeDirection as String: kTLInfoSwipeLeft,
        kTLInfoKeyGesturePhase as String: 4
    ]

    private let swipeRight: [String: Int] = [
        kTLInfoKeyGestureSubtype as String: kTLInfoSubtypeSwipe,
        kTLInfoKeySwipeDirection as String: kTLInfoSwipeRight,
        kTLInfoKeyGesturePhase as String: 4
    ]

    static let shared = SwipeSimulator()

    // MARK: - Internal State

    /// Whether the CGEvent tap is currently active.
    private let eventTapIsRunning: Mutex<Bool> = Mutex(false)

    /// A list of bundle identifiers that are ignored.
    private let ignoredApplications: Mutex<[String]> = Mutex(
        UserDefaults.standard.stringArray(forKey: Keys.ignored) ?? []
    )

    /// Whether the swipe direction is reversed (e.g. right <-> left).
    private let reverseButtons: Mutex<Bool> = Mutex(UserDefaults.standard.bool(forKey: Keys.reverse))

    private init() { }

    // MARK: - Public

    func areButtonsReversed() -> Bool {
        self.reverseButtons.withLock { $0 }
    }

    func toggleReverseButtons() {
        self.reverseButtons.withLock { reversed in
            reversed.toggle()
            UserDefaults.standard.set(reversed, forKey: Keys.reverse)
        }
    }

    func isEventTapRunning() -> Bool {
        self.eventTapIsRunning.withLock { $0 }
    }

    func addIgnoredApplication(bundleID: String) {
        self.ignoredApplications.withLock { applications in
            applications.append(bundleID)
            UserDefaults.standard.set(applications, forKey: Keys.ignored)
        }
    }

    func removeIgnoredApplication(bundleID: String) {
        self.ignoredApplications.withLock { applications in
            applications.removeAll { $0 == bundleID }
            UserDefaults.standard.set(applications, forKey: Keys.ignored)
        }
    }

    func ignoredApplicationsContain(_ bundleID: String) -> Bool {
        self.ignoredApplications.withLock { $0.contains(bundleID) }
    }

    func setupEventTap() throws {
        try self.eventTapIsRunning.withLock { isRunning in
            guard !isRunning else { return }
            let eventMask = CGEventMask(
                1 << CGEventType.otherMouseDown.rawValue | 1 << CGEventType.otherMouseUp.rawValue
            )

            guard let eventTap = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: mouseEventCallBack,
                userInfo: nil)
            else {
                isRunning = false
                throw EventTap.failedSetup
            }

            let runLoopSource = CFMachPortCreateRunLoopSource(nil, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            isRunning = true
        }
    }

    private func fakeSwipe(direction: TLInfoSwipeDirection) {
        let eventBegin: CGEvent = tl_CGEventCreateFromGesture(self.swipeBegin as CFDictionary,
                                                              [] as CFArray).takeRetainedValue()

        let swipeDirection = self.reverseButtons.withLock { $0 ? direction.reversed : direction }
        let eventSwipe: CGEvent? = switch swipeDirection {
        case TLInfoSwipeDirection(kTLInfoSwipeLeft):
            tl_CGEventCreateFromGesture(self.swipeLeft as CFDictionary, [] as CFArray).takeRetainedValue()
        case TLInfoSwipeDirection(kTLInfoSwipeRight):
            tl_CGEventCreateFromGesture(self.swipeRight as CFDictionary, [] as CFArray).takeRetainedValue()
        default:
            nil
        }

        guard let eventSwipe else { return }
        eventBegin.post(tap: .cghidEventTap)
        eventSwipe.post(tap: .cghidEventTap)
    }

    fileprivate func handleMouseEvent(type: CGEventType, cgEvent: CGEvent) -> CGEvent? {
        guard type == .otherMouseDown && self.isValidApplication() else {
            return cgEvent
        }

        let number = CGEvent.getIntegerValueField(cgEvent)(.mouseEventButtonNumber)
        if number == 3 {
            self.fakeSwipe(direction: TLInfoSwipeDirection(kTLInfoSwipeLeft))
            return nil
        } else if number == 4 {
            self.fakeSwipe(direction: TLInfoSwipeDirection(kTLInfoSwipeRight))
            return nil
        }
        return cgEvent
    }

    private func isValidApplication() -> Bool {
        guard let frontAppBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return true }
        return self.ignoredApplications.withLock { !$0.contains(frontAppBundleID) }
    }
}

// swiftlint:disable private_over_fileprivate
fileprivate func mouseEventCallBack(proxy: CGEventTapProxy,
                                    type: CGEventType,
                                    cgEvent: CGEvent,
                                    userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let cgEvent = SwipeSimulator.shared.handleMouseEvent(type: type, cgEvent: cgEvent) else { return nil }
    return Unmanaged.passRetained(cgEvent)
}

fileprivate extension TLInfoSwipeDirection {
    var reversed: TLInfoSwipeDirection {
        switch self {
        case TLInfoSwipeDirection(kTLInfoSwipeLeft):
            return TLInfoSwipeDirection(kTLInfoSwipeRight)
        case TLInfoSwipeDirection(kTLInfoSwipeRight):
            return TLInfoSwipeDirection(kTLInfoSwipeLeft)
        default:
            return self
        }
    }
}
// swiftlint:enable private_over_fileprivate
