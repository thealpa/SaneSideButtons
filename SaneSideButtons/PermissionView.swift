//
//  PermissionView.swift
//  SaneSideButtons
//
//  Created by Jan Hülsmann on 16.10.22.
//

import SwiftUI

struct PermissionView: View {
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let closeWindow: @MainActor () -> Void

    init(closeWindow: @escaping () -> Void) {
        self.closeWindow = closeWindow
    }

    var body: some View {
        VStack {
            VStack {
                Text("authorize_title")
                    .font(.title)
                    .fontWeight(.medium)
                Text("authorize_subtitle")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 10)
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Color.background)
                    .frame(width: 600, height: 240)
                PermissionContentView()
                    .padding(.vertical, 20)
            }

        }
        .background(.thinMaterial)
        .onReceive(self.timer) { _ in
            self.pollPermissions()
        }
    }

    @MainActor private func pollPermissions() {
        do {
            try SwipeSimulator.shared.setupEventTap()
            self.closeWindow()
        } catch {
            return
        }
    }
}

struct PermissionContentView: View {
    @Environment(\.openURL) private var openURL

    private let settingsString: String = "x-apple.systempreferences:com.apple.preference"
    private let privacyString: String = ".security?Privacy"

    var body: some View {
        VStack {
            Text("authorize_description")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            Grid {
                GridRow {
                    Image(systemName: "1.circle.fill")
                        .font(.title)
                        .foregroundColor(Color.gray)
                    Image(systemName: "2.circle.fill")
                        .font(.title)
                        .foregroundColor(Color.gray)
                    Image(systemName: "3.circle.fill")
                        .font(.title)
                        .foregroundColor(Color.gray)
                }
                GridRow {
                    Button {
                        if let url = URL(string: self.settingsString) {
                            self.openURL(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                            Text("settings")
                                .font(.body)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.thinMaterial)
                                .shadow(radius: 2)
                        )
                    }.buttonStyle(.plain)

                    Button {
                        if let url = URL(string: self.settingsString + self.privacyString) {
                            self.openURL(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            Text("privacy")
                                .font(.body)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.thinMaterial)
                                .shadow(radius: 2)
                        )
                    }.buttonStyle(.plain)

                    Button {
                        if let url = URL(string: self.settingsString + self.privacyString) {
                            self.openURL(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "keyboard.badge.eye.fill")
                            Text("add_to \(Text("a11y").underline()) \(Text("input_monitoring").underline())")
                                .font(.body)
                                .multilineTextAlignment(.center)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.thinMaterial)
                                .shadow(radius: 2)
                        )
                    }.buttonStyle(.plain)
                }.frame(width: 180, height: 90)
            }
        }
    }
}

#Preview {
    PermissionView(closeWindow: { })
}
