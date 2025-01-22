//
//  AppDelegate.swift
//  SaneSideButtons
//
//  Created by Jan Hülsmann on 16.10.22.
//

import AppKit
import SwiftUI
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var frontmostAppBundleID: String?
    private var permissionWindow: NSWindow?
    private var isLaunchAtLoginEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            if newValue {
                if SMAppService.mainApp.status == .enabled {
                    try? SMAppService.mainApp.unregister()
                }
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }

    // MARK: - Menu Bar

    private let menuBarExtra: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    // MARK: - Menu Bar Items

    private lazy var menuItemHide: NSMenuItem = {
        let title = NSLocalizedString("hide", comment: "Hide menu item")
        return NSMenuItem(title: title, action: #selector(self.hideMenuBarExtra), keyEquivalent: "h")
    }()

    private let menuItemHideInfo: NSMenuItem = {
        let title = NSLocalizedString("hideInfo", comment: "Show again info in menu")
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }()

    private let menuItemIgnore: NSMenuItem = {
        let item = NSMenuItem()
        item.tag = 1
        return item
    }()

    private lazy var menuItemReverse: NSMenuItem = {
        let title = NSLocalizedString("reverse", comment: "Reverse buttons")
        let item = NSMenuItem(title: title, action: #selector(self.toggleReverse), keyEquivalent: "")
        item.tag = 2
        return item
    }()

    private lazy var menuItemLaunchAtLogin: NSMenuItem = {
        let title = NSLocalizedString("launchAtLogin", comment: "Launch at Login")
        let item = NSMenuItem(title: title, action: #selector(self.toggleLaunchAtLogin), keyEquivalent: "")
        item.tag = 3
        return item
    }()

    private let menuItemVersion: NSMenuItem? = {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return nil }
        let localizedString = NSLocalizedString("version", comment: "Version menu item")
        let versionString = String.localizedStringWithFormat(localizedString, version)
        let item = NSMenuItem(title: versionString, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }()

    private lazy var menuItemAbout: NSMenuItem = {
        let title = NSLocalizedString("about", comment: "About menu item")
        return NSMenuItem(title: title, action: #selector(self.about), keyEquivalent: "")
    }()

    private lazy var itemQuit: NSMenuItem = {
        let title = NSLocalizedString("quit", comment: "Quit menu item")
        return NSMenuItem(title: title, action: #selector(self.quit), keyEquivalent: "q")
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
        menu.items = [
            self.menuItemHide,
            self.menuItemHideInfo,
            .separator(),
            self.menuItemIgnore,
            self.menuItemReverse,
            self.menuItemLaunchAtLogin,
            .separator(),
            self.menuItemVersion,
            self.menuItemAbout,
            .separator(),
            self.itemQuit
        ].compactMap { $0 }

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

    @objc private func ignoreFrontmostApp() {
        guard let frontmostAppBundleID else { return }
        SwipeSimulator.shared.addIgnoredApplication(bundleID: frontmostAppBundleID)
    }

    @objc private func unignoreFrontmostApp() {
        guard let frontmostAppBundleID else { return }
        SwipeSimulator.shared.removeIgnoredApplication(bundleID: frontmostAppBundleID)
    }

    @objc private func toggleReverse() {
        SwipeSimulator.shared.toggleReverseButtons()
    }

    @objc private func toggleLaunchAtLogin() {
        self.isLaunchAtLoginEnabled.toggle()
    }

    // MARK: - Setup & Permissions

    @MainActor private func setupTapWithPermissions() {
        self.getEventPermission()
        do {
            try SwipeSimulator.shared.setupEventTap()
        } catch {
            if self.permissionWindow == nil {
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
        self.permissionWindow = NSWindow(
            contentRect: NSRect(),
            styleMask: [.closable, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.permissionWindow?.isReleasedWhenClosed = false
        self.permissionWindow?.titlebarAppearsTransparent = true
        self.permissionWindow?.titleVisibility = .hidden
        self.permissionWindow?.toolbar = NSToolbar()
        self.permissionWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.permissionWindow?.standardWindowButton(.zoomButton)?.isHidden = true
        self.permissionWindow?.contentView = NSHostingView(rootView: PermissionView())
        self.permissionWindow?.isOpaque = false
        self.permissionWindow?.backgroundColor = NSColor(white: 1, alpha: 0)
        self.permissionWindow?.center()
        self.permissionWindow?.makeKeyAndOrderFront(nil)
        self.permissionWindow?.delegate = self
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Permission Detection
        if !SwipeSimulator.shared.isEventTapRunning() {
            NSApplication.shared.activate(ignoringOtherApps: true)
            if self.permissionWindow == nil {
                self.promptPermissions()
            }
        }

        // Front App Detection
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let frontAppName = frontApp.localizedName,
              let frontAppBundleID = frontApp.bundleIdentifier else {
            self.frontmostAppBundleID = nil
            self.menuBarExtra.menu?.item(withTag: 1)?.isHidden = true
            return
        }

        self.frontmostAppBundleID = frontAppBundleID
        let localizedString = NSLocalizedString("ignore", comment: "Ignore app menu item")
        let ignoreString = String.localizedStringWithFormat(localizedString, frontAppName)
        if !SwipeSimulator.shared.ignoredApplicationsContain(frontAppBundleID) {
            self.menuBarExtra.menu?.item(withTag: 1)?.state = .off
            self.menuBarExtra.menu?.item(withTag: 1)?.action = #selector(self.ignoreFrontmostApp)
        } else {
            self.menuBarExtra.menu?.item(withTag: 1)?.state = .on
            self.menuBarExtra.menu?.item(withTag: 1)?.action = #selector(self.unignoreFrontmostApp)
        }
        self.menuBarExtra.menu?.item(withTag: 1)?.isHidden = false
        self.menuBarExtra.menu?.item(withTag: 1)?.title = ignoreString

        // Reverse Buttons State
        self.menuBarExtra.menu?.item(withTag: 2)?.state = SwipeSimulator.shared.areButtonsReversed() ? .on : .off

        // Launch at Login Button State
        self.menuBarExtra.menu?.item(withTag: 3)?.state = self.isLaunchAtLoginEnabled ? .on : .off
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        self.permissionWindow = nil
        return true
    }
}
