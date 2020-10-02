//
//  MessangerApp.swift
//  Messanger
//
//  Created by Patrick Maltagliati on 10/2/20.
//

import SwiftUI

@main
struct MessangerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
