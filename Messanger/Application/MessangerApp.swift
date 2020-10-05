//
//  MessangerApp.swift
//  Messanger
//
//  Created by Patrick Maltagliati on 10/2/20.
//

import SwiftUI
import CloudKit
import CoreData

@main
struct MessangerApp: App {
    private let persistenceController = PersistenceController()
    private let context: NSManagedObjectContext
    private let keychainModel: KeychainModel
    
    init() {
        context = persistenceController.container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        keychainModel = KeychainModel(container: EnvironmentValues().cloudKitContainer,
                                      context: persistenceController.container.newBackgroundContext())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(keychainModel: keychainModel).environment(\.managedObjectContext, context)
        }
    }
}
