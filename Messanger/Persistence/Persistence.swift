//
//  Persistence.swift
//  Messanger
//
//  Created by Patrick Maltagliati on 10/2/20.
//

import CoreData

struct PersistenceController {
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Messanger")
        
        let defaultDesctiption = container.persistentStoreDescriptions.first
        let url = defaultDesctiption?.url?.deletingLastPathComponent()
        
        let privateDescription = NSPersistentStoreDescription(url: url!.appendingPathComponent("private.sqlite"))
        let privateOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.Maltagliati.Messanger")
        privateOptions.databaseScope = .private
        privateDescription.cloudKitContainerOptions = privateOptions
        privateDescription.configuration = "Private"
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        let publicDescription = NSPersistentStoreDescription(url: url!.appendingPathComponent("public.sqlite"))
        let publicOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.Maltagliati.Messanger")
        publicOptions.databaseScope = .public
        publicDescription.cloudKitContainerOptions = publicOptions
        publicDescription.configuration = "Public"
        publicDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        publicDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [privateDescription, publicDescription]
        
        if inMemory {
            container.persistentStoreDescriptions.forEach { $0.url = URL(fileURLWithPath: "/dev/null") }
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
/// Uncomment to upload scheme to CloudKit
//        do {
//            try container.initializeCloudKitSchema(options: NSPersistentCloudKitContainerSchemaInitializationOptions())
//        } catch {
//            print(error)
//        }
    }
}
