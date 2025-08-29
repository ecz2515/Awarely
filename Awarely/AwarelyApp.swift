//
//  AwarelyApp.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

@main
struct AwarelyApp: App {
    @StateObject private var coreDataManager = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreDataManager)
                .dismissKeyboardOnTap()
        }
    }
}
