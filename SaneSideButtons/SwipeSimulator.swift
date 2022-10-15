//
//  SwipeSimulator.swift
//  SaneSideButtons
//
//  Created by Jan Hülsmann on 16.10.22.
//

import Foundation

final class SwipeSimulator {
    static let shared = SwipeSimulator()
    
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

    private init() { }

    fileprivate func SBFFakeSwipe(direction: TLInfoSwipeDirection) {
        let eventBegin: CGEvent = tl_CGEventCreateFromGesture(swipeBegin as CFDictionary, [] as CFArray).takeRetainedValue()

        var eventSwipe: CGEvent? = nil
        if direction == TLInfoSwipeDirection(kTLInfoSwipeLeft) {
            eventSwipe = tl_CGEventCreateFromGesture(swipeLeft as CFDictionary, [] as CFArray).takeRetainedValue()
        } else if direction == TLInfoSwipeDirection(kTLInfoSwipeRight) {
            eventSwipe = tl_CGEventCreateFromGesture(swipeRight as CFDictionary, [] as CFArray).takeRetainedValue()
        }
        
        guard let eventSwipe else { return }
        eventBegin.post(tap: .cghidEventTap)
        eventSwipe.post(tap: .cghidEventTap)
    }

    func isProcessTrusted() -> Bool {
//        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
//        let opts = [promptKey: true] as CFDictionary
//        return AXIsProcessTrustedWithOptions(opts)
        if !CGPreflightListenEventAccess() {
            CGRequestListenEventAccess()
            return false
        } else {
            return true
        }
    }

    func setupEventTap() {
        let eventMask = CGEventMask(1 << CGEventType.otherMouseDown.rawValue | 1 << CGEventType.otherMouseUp.rawValue)
        guard let eventTap = CGEvent.tapCreate(tap: .cghidEventTap,
                                               place: .headInsertEventTap,
                                               options: .defaultTap,
                                               eventsOfInterest: eventMask,
                                               callback: mouseEventCallBack,
                                               userInfo: nil) else {
            print("Failed to create eventTap")
            return
        }
        let runLoopSource = CFMachPortCreateRunLoopSource(nil, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
}

fileprivate func mouseEventCallBack(proxy: CGEventTapProxy, type: CGEventType, cgEvent: CGEvent, userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    let number = CGEvent.getIntegerValueField(cgEvent)(.mouseEventButtonNumber)
    if number == 3 {
        SwipeSimulator.shared.SBFFakeSwipe(direction: TLInfoSwipeDirection(kTLInfoSwipeLeft))
    } else if number == 4 {
        SwipeSimulator.shared.SBFFakeSwipe(direction: TLInfoSwipeDirection(kTLInfoSwipeRight))
    }
    return Unmanaged.passRetained(cgEvent)
}
