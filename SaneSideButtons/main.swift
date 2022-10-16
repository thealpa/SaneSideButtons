//
//  main.swift
//  SaneSideButtons
//
//  Created by Jan Hülsmann on 16.10.22.
//

import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
