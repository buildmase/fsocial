//
//  fsocialApp.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import SwiftUI

@main
struct fsocialApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, idealWidth: 1400, minHeight: 700, idealHeight: 900)
                .background(Color.appBackground)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
