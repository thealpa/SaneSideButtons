//
//  SaneSideButtonsApp.swift
//  SaneSideButtons
//
//  Created by Jan Hülsmann on 16.10.22.
//

import SwiftUI

@main
struct SaneSideButtons2App: App {

    init() {
        guard SwipeSimulator.shared.isProcessTrusted() else {
            print("Process isn't trusted")
            exit(1)
        }
        SwipeSimulator.shared.setupEventTap()
    }

    var body: some Scene {
        MenuBarExtra("SaneSideButtons",
                     systemImage: "magicmouse") {
            Button("Enable") {
                
            }
            Divider()
            Button("Licenses") {
                let resource = URLResource(name: "Licenses.txt")
                let url = URL(resource: resource)
                NSWorkspace.shared.open(url!)
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }.menuBarExtraStyle(.menu)
    }
}
