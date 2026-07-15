import CoreData

/// Owns the CoreData stack. The model is defined programmatically (no `.xcdatamodeld` bundle)
/// so the schema lives in code alongside the mapping. Local-first; a CloudKit-backed container
/// (`NSPersistentCloudKitContainer`) for the Pro iCloud-sync feature is a follow-up (Epic 6).
final class PersistenceController {
    static let shared = PersistenceController()

    /// In-memory stack for previews and tests.
    static let preview = PersistenceController(inMemory: true)

    static let sessionEntityName = "FocusSessionEntity"

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(
            name: "FocusPulse",
            managedObjectModel: PersistenceController.makeModel()
        )
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                // Non-fatal: the timer keeps working in memory even if the store fails to load
                // (NASA Power-of-10 "no silent failure" — surface, don't crash).
                assertionFailure("CoreData store failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Programmatic model

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = sessionEntityName
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = type
            a.isOptional = optional
            return a
        }

        entity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("typeRaw", .stringAttributeType),
            attribute("startTime", .dateAttributeType),
            attribute("endTime", .dateAttributeType),
            attribute("statusRaw", .stringAttributeType),
            attribute("label", .stringAttributeType, optional: true)
        ]

        model.entities = [entity]
        return model
    }
}
