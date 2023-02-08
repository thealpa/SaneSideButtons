//
//  SwipeSimulator.swift
//  SaneSideButtons
//
//  Created by Jan Hülsmann on 16.10.22.
//

import AppKit

final class SwipeSimulator {
    static let shared = SwipeSimulator()
    private(set) var eventTapIsRunning: Bool = false

    private let swipeBegin = [
        kTLInfoKeyGestureSubtype: kTLInfoSubtypeSwipe,
        kTLInfoKeyGesturePhase: 1
    ]

    private let swipeLeft = [
        kTLInfoKeyGestureSubtype: kTLInfoSubtypeSwipe,
        kTLInfoKeySwipeDirection: kTLInfoSwipeLeft,
        kTLInfoKeyGesturePhase: 4
    ]

    private let swipeRight = [
        kTLInfoKeyGestureSubtype: kTLInfoSubtypeSwipe,
        kTLInfoKeySwipeDirection: kTLInfoSwipeRight,
        kTLInfoKeyGesturePhase: 4
    ]

    var ignoredApplications: [String] = UserDefaults.standard.stringArray(forKey: "ignoredApplications") ?? []

    enum EventTap: Error {
        case failedSetup
    }

    private init() { }

    fileprivate func SBFFakeSwipe(direction: TLInfoSwipeDirection) {
        let eventBegin: CGEvent = tl_CGEventCreateFromGesture(self.swipeBegin as CFDictionary,
                                                              [] as CFArray).takeRetainedValue()

        var eventSwipe: CGEvent?
        if direction == TLInfoSwipeDirection(kTLInfoSwipeLeft) {
            eventSwipe = tl_CGEventCreateFromGesture(self.swipeLeft as CFDictionary,
                                                     [] as CFArray).takeRetainedValue()
        } else if direction == TLInfoSwipeDirection(kTLInfoSwipeRight) {
            eventSwipe = tl_CGEventCreateFromGesture(self.swipeRight as CFDictionary,
                                                     [] as CFArray).takeRetainedValue()
        }

        guard let eventSwipe else { return }
        eventBegin.post(tap: .cghidEventTap)
        eventSwipe.post(tap: .cghidEventTap)
    }

    fileprivate func isValidApplication() -> Bool {
        let frontAppBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard let frontAppBundleID else { return true }
        if self.ignoredApplications.contains(frontAppBundleID) {
            return false
        }
        return true
    }

    func addIgnoredApplication(bundleID: String) {
        self.ignoredApplications.append(bundleID)
        UserDefaults.standard.set(self.ignoredApplications, forKey: "ignoredApplications")
    }

    func removeIgnoredApplication(bundleID: String) {
        self.ignoredApplications.removeAll { $0 == bundleID }
        UserDefaults.standard.set(self.ignoredApplications, forKey: "ignoredApplications")
    }

    func setupEventTap() throws {
        guard !self.eventTapIsRunning else { return }
        let eventMask = CGEventMask(1 << CGEventType.otherMouseDown.rawValue | 1 << CGEventType.otherMouseUp.rawValue)
        guard let eventTap = CGEvent.tapCreate(tap: .cghidEventTap,
                                               place: .headInsertEventTap,
                                               options: .defaultTap,
                                               eventsOfInterest: eventMask,
                                               callback: mouseEventCallBack,
                                               userInfo: nil) else {
            self.eventTapIsRunning = false
            throw EventTap.failedSetup
        }
        let runLoopSource = CFMachPortCreateRunLoopSource(nil, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        self.eventTapIsRunning = true
    }
}

// swiftlint:disable private_over_fileprivate
fileprivate func mouseEventCallBack(proxy: CGEventTapProxy,
                                    type: CGEventType,
                                    cgEvent: CGEvent,
                                    userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    let mouseDown = type == .otherMouseDown
    let validApplication = SwipeSimulator.shared.isValidApplication()
    guard mouseDown && validApplication else {
        return Unmanaged.passRetained(cgEvent)
    }
    let number = CGEvent.getIntegerValueField(cgEvent)(.mouseEventButtonNumber)
    if number == 3 {
        SwipeSimulator.shared.SBFFakeSwipe(direction: TLInfoSwipeDirection(kTLInfoSwipeLeft))
        return nil
    } else if number == 4 {
        SwipeSimulator.shared.SBFFakeSwipe(direction: TLInfoSwipeDirection(kTLInfoSwipeRight))
        return nil
    }
    return Unmanaged.passRetained(cgEvent)
}
// swiftlint:enable private_over_fileprivate
