//
//  AppDelegate.swift
//  SaneSideButtons
//
//  Created by Jan Hülsmann on 16.10.22.
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var currentFrontAppBundleID: String?
    private var window: NSWindow?

    private lazy var menuBarExtra: NSStatusItem = {
        return NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }()

    // MARK: - Menu Bar Items

    private let itemHide: NSMenuItem = {
        let hideString = NSLocalizedString("hide", comment: "Hide menu item")
        return NSMenuItem(title: hideString, action: #selector(hideMenuBarExtra), keyEquivalent: "h")
    }()

    private let itemHideInfo: NSMenuItem = {
        let hideInfoString = NSLocalizedString("hideInfo", comment: "Show again info in menu")
        let item = NSMenuItem(title: hideInfoString, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }()

    private let itemIgnore: NSMenuItem = {
        let item = NSMenuItem()
        item.tag = 1
        return item
    }()

    private let itemReverse: NSMenuItem = {
        let reverseString = NSLocalizedString("reverse", comment: "Reverse buttons")
        let item = NSMenuItem(title: reverseString, action: #selector(toggleReverse), keyEquivalent: "")
        item.tag = 2
        return item
    }()

    private let itemVersion: NSMenuItem? = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        guard let version else { return nil }
        let localizedString = NSLocalizedString("version", comment: "Version menu item")
        let versionString = String.localizedStringWithFormat(localizedString, version)
        let item = NSMenuItem(title: versionString, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }()

    private let itemAbout: NSMenuItem = {
        let aboutString = NSLocalizedString("about", comment: "About menu item")
        return NSMenuItem(title: aboutString, action: #selector(about), keyEquivalent: "")
    }()

    private let itemQuit: NSMenuItem = {
        let quitString = NSLocalizedString("quit", comment: "Quit menu item")
        return NSMenuItem(title: quitString, action: #selector(quit), keyEquivalent: "q")
    }()

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.setupTapWithPermissions()
        self.setupMenuBarExtra()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        self.menuBarExtra.isVisible = true
        return false
    }

    func applicationWillTerminate(_ aNotification: Notification) { }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Functions

private extension AppDelegate {
    @MainActor private func setupMenuBarExtra() {
        if let button = self.menuBarExtra.button {
            button.image = NSImage(resource: .menuIcon)
        }

        let menu = NSMenu()
        menu.delegate = self

        [self.itemHide,
         self.itemHideInfo,
         NSMenuItem.separator(),
         self.itemIgnore,
         self.itemReverse,
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

    @objc private func toggleReverse() {
        SwipeSimulator.shared.toggleReverseButtons()
    }

    // MARK: - Setup & Permissions

    @MainActor private func setupTapWithPermissions() {
        self.getEventPermission()
        do {
            try SwipeSimulator.shared.setupEventTap()
        } catch {
            if self.window == nil {
                self.promptPermissions()
            }
        }
    }

    @discardableResult private func getEventPermission() -> Bool {
        if !CGPreflightListenEventAccess() {
            CGRequestListenEventAccess()
            return false
        }
        return true
    }

    @MainActor @objc private func promptPermissions() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        self.window = NSWindow(
            contentRect: NSRect(),
            styleMask: [.closable, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.window?.isReleasedWhenClosed = false
        self.window?.titlebarAppearsTransparent = true
        self.window?.titleVisibility = .hidden
        self.window?.toolbar = NSToolbar()
        self.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.window?.standardWindowButton(.zoomButton)?.isHidden = true
        let permissionView = PermissionView(closeWindow: self.closePermissionsPrompt)
        self.window?.contentView = NSHostingView(rootView: permissionView)
        self.window?.isOpaque = false
        self.window?.backgroundColor = NSColor(white: 1, alpha: 0)
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.delegate = self
    }

    @MainActor func closePermissionsPrompt() {
        self.window?.close()
        self.window = nil
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Permission Detection
        if !SwipeSimulator.shared.isEventTapRunning() {
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
        let localizedString = NSLocalizedString("ignore", comment: "Ignore app menu item")
        let ignoreString = String.localizedStringWithFormat(localizedString, frontAppName)
        if !SwipeSimulator.shared.ignoredApplicationsContain(frontAppBundleID) {
            self.menuBarExtra.menu?.item(withTag: 1)?.state = .off
            self.menuBarExtra.menu?.item(withTag: 1)?.action = #selector(self.ignore)
        } else {
            self.menuBarExtra.menu?.item(withTag: 1)?.state = .on
            self.menuBarExtra.menu?.item(withTag: 1)?.action = #selector(self.unignore)
        }
        self.menuBarExtra.menu?.item(withTag: 1)?.isHidden = false
        self.menuBarExtra.menu?.item(withTag: 1)?.title = ignoreString

        // Reverse Buttons State
        self.menuBarExtra.menu?.item(withTag: 2)?.state = SwipeSimulator.shared.areButtonsReversed() ? .on : .off
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        self.window = nil
        return true
    }
}
