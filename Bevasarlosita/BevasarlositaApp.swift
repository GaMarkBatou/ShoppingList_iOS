//
//  BevasarlositaApp.swift
//  Bevasarlosita
//
//  Created by Márk Gavallér on 2025. 07. 14..
//

import SwiftUI

@main
struct BevasarlositaApp: App {
    @AppStorage("darkMode") private var darkMode = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(darkMode ? .dark : .light)
        }
    }
}
