//
//  AppDelegate.swift
//  SaneSideButtons
//
//  Created by Jan Hülsmann on 16.10.22.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    private var currentFrontAppBundleID: String?
    private var window: NSWindow?

    private lazy var menuBarExtra: NSStatusItem = {
        return NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }()

    // MARK: - Menu Bar Items

    private let itemHide: NSMenuItem = {
        return NSMenuItem(title: "Hide Menu Bar Icon", action: #selector(hideMenuBarExtra), keyEquivalent: "h")
    }()

    private let itemHideInfo: NSMenuItem = {
        let item = NSMenuItem(title: "Relaunch App to Show Again", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }()

    private let itemIgnore: NSMenuItem? = {
        let item = NSMenuItem()
        item.tag = 1
        return item
    }()

    private let itemVersion: NSMenuItem? = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if let version {
            let item = NSMenuItem(title: "Version \(version)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            return item
        }
        return nil
    }()

    private let itemAbout: NSMenuItem = {
        return NSMenuItem(title: "About", action: #selector(about), keyEquivalent: "")
    }()

    private let itemQuit: NSMenuItem = {
        return NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
    }()

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.setupPermissions()
        self.setupMenuBarExtra()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        self.menuBarExtra.isVisible = true
        return false
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Functions

private extension AppDelegate {
    @MainActor private func setupMenuBarExtra() {
        if let button = self.menuBarExtra.button {
            button.image = NSImage(named: "MenuIcon")
        }

        let menu = NSMenu()
        menu.delegate = self

        [self.itemHide,
         self.itemHideInfo,
         NSMenuItem.separator(),
         self.itemIgnore,
         NSMenuItem.separator(),
         self.itemVersion,
         self.itemAbout,
         NSMenuItem.separator(),
         self.itemQuit]
            .compactMap { $0 }
            .forEach(menu.addItem)

        self.menuBarExtra.menu = menu
    }

    @objc private func hideMenuBarExtra() {
        self.menuBarExtra.isVisible = false
    }

    @MainActor @objc private func about() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel()
    }

    @MainActor @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func ignore() {
        guard let currentFrontAppBundleID else { return }
        SwipeSimulator.shared.addIgnoredApplication(bundleID: currentFrontAppBundleID)
    }

    @objc private func unignore() {
        guard let currentFrontAppBundleID else { return }
        SwipeSimulator.shared.removeIgnoredApplication(bundleID: currentFrontAppBundleID)
    }

    // MARK: - Permissions

    private func setupPermissions() {
        if self.hasPermissions() {
            SwipeSimulator.shared.setupEventTap()
        } else {
            Task {
                await self.promptPermissions()
            }
        }
    }

    private func hasPermissions() -> Bool {
        if getEventPermission() && getAccessibilityPermission() {
            return true
        }
        return false
    }

    private func getEventPermission() -> Bool {
        if !CGPreflightListenEventAccess() {
            CGRequestListenEventAccess()
            return false
        }
        return true
    }

    private func getAccessibilityPermission() -> Bool {
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [prompt: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    @MainActor @objc private func promptPermissions() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        self.window = NSWindow(
            contentRect: NSRect(),
            styleMask: [.closable, .titled],
            backing: .buffered, defer: false)
        self.window?.isReleasedWhenClosed = false
        self.window?.titlebarAppearsTransparent = true
        self.window?.titleVisibility = .hidden
        self.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.window?.standardWindowButton(.zoomButton)?.isHidden = true
        let permissionView = PermissionView(closeWindow: self.closePermissionsPrompt,
                                            hasPermissions: self.hasPermissions)
        self.window?.contentView = NSHostingView(rootView: permissionView)
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.delegate = self
    }

    func closePermissionsPrompt() {
        self.window?.close()
        self.window = nil
        self.setupPermissions()
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Permission Detection
        if !self.hasPermissions() {
            NSApplication.shared.activate(ignoringOtherApps: true)
            if self.window == nil {
                self.promptPermissions()
            }
        }

        // Front App Detection
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let frontAppName = frontApp.localizedName,
              let frontAppBundleID = frontApp.bundleIdentifier else {
            self.currentFrontAppBundleID = nil
            self.menuBarExtra.menu?.item(withTag: 1)?.isHidden = true
            return
        }

        self.currentFrontAppBundleID = frontAppBundleID
        if !SwipeSimulator.shared.ignoredApplications.contains(frontAppBundleID) {
            self.menuBarExtra.menu?.item(withTag: 1)?.state = .off
            self.menuBarExtra.menu?.item(withTag: 1)?.action = #selector(self.ignore)
        } else {
            self.menuBarExtra.menu?.item(withTag: 1)?.state = .on
            self.menuBarExtra.menu?.item(withTag: 1)?.action = #selector(self.unignore)
        }
        self.menuBarExtra.menu?.item(withTag: 1)?.isHidden = false
        self.menuBarExtra.menu?.item(withTag: 1)?.title = "Ignore " + frontAppName
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        self.window = nil
        return true
    }
}
