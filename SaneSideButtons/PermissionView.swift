//
//  PermissionView.swift
//  SaneSideButtons
//
//  Created by Jan Hülsmann on 16.10.22.
//

import SwiftUI

struct PermissionView: View {
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let closeWindow: () -> Void
    let hasPermissions: () -> Bool

    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .frame(width: 500, height: 100)
                    .foregroundColor(Color("SecondaryColor"))
                VStack {
                    Text("Authorize SaneSideButtons")
                        .font(.title)
                        .fontWeight(.medium)
                    Text("We'll have you up and running in just a minute!")
                        .font(.subheadline)
                }
            }.offset(y: -30)
            ZStack {
                Rectangle()
                    .frame(width: 500, height: 40)
                    .foregroundColor(Color("BackgroundColor"))
                    .offset(y: -120)
                VStack {
                    // swiftlint:disable line_length
                    Text("SaneSideButtons needs your permission to detect mouse events and trigger actions in applications. Follow these steps to authorize it:")
                    // swiftlint:enable line_length
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                    HStack(alignment: .top) {
                        VStack {
                            Image(systemName: "1.circle.fill")
                                .font(.title)
                                .foregroundColor(Color.gray)
                            Text("Go to System Settings")
                                .font(.callout)
                                .padding(7)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.blue, lineWidth: 1)
                                )
                                .padding(.top, 30)
                        }.padding(.horizontal, 5)

                        VStack {
                            Image(systemName: "2.circle.fill")
                                .font(.title)
                                .foregroundColor(Color.gray)
                            Text("Privacy & Security")
                                .font(.callout)
                                .padding(7)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.blue, lineWidth: 1)
                                )
                                .padding(.top, 30)
                        }.padding(.horizontal, 5)

                        VStack {
                            Image(systemName: "3.circle.fill")
                                .font(.title)
                                .foregroundColor(Color.gray)
                            Text("Add SaneSideButtons to Accessibility & Input Monitoring")
                                .font(.callout)
                                .multilineTextAlignment(.center)
                                .padding(7)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.blue, lineWidth: 1)
                                )
                                .padding(.top, 15)
                        }.padding(.horizontal, 5)
                    }
                }
                .offset(y: -40)
                .padding(.horizontal, 20)
            }
            .onReceive(timer) { _ in
                self.pollPermissions()
            }
            .frame(width: 500, height: 200)
            .background(Color("BackgroundColor"))
        }
    }

    private func pollPermissions() {
        if self.hasPermissions() {
            self.closeWindow()
        }
    }
}

struct PermissionView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionView(closeWindow: self.closeWindow,
                       hasPermissions: self.hasPermissions)
    }

    static func closeWindow() { }

    static func hasPermissions() -> Bool {
        return false
    }
}
