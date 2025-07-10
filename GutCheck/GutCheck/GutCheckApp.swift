//
//  GutCheckApp.swift
//  GutCheck
//
//  Created by Mark Conley on 7/9/25.
//

import SwiftUI
import FirebaseCore

@main
struct GutCheckApp: App {
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
