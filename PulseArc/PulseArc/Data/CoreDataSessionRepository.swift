import CoreData
import PulseArcCore

/// CoreData-backed implementation of the domain's `SessionRepository` port. Maps between the
/// pure-Swift `FocusSession` aggregate and `FocusSessionEntity` managed objects via KVC.
final class CoreDataSessionRepository: SessionRepository, @unchecked Sendable {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }

    func save(_ session: FocusSession) async throws {
        try await context.perform {
            let object = NSEntityDescription.insertNewObject(
                forEntityName: PersistenceController.sessionEntityName, into: self.context)
            self.apply(session, to: object)
            try self.context.save()
        }
    }

    func allSessions() async throws -> [FocusSession] {
        try await context.perform {
            let request = self.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
            return try self.context.fetch(request).compactMap(self.map)
        }
    }

    func sessions(on day: Date, calendar: Calendar) async throws -> [FocusSession] {
        try await context.perform {
            let start = calendar.startOfDay(for: day)
            guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
            let request = self.fetchRequest()
            request.predicate = NSPredicate(
                format: "startTime >= %@ AND startTime < %@", start as NSDate, end as NSDate)
            request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
            return try self.context.fetch(request).compactMap(self.map)
        }
    }

    func update(_ session: FocusSession) async throws {
        try await context.perform {
            guard let object = try self.object(withID: session.id) else { return }
            self.apply(session, to: object)
            try self.context.save()
        }
    }

    func delete(id: UUID) async throws {
        try await context.perform {
            guard let object = try self.object(withID: id) else { return }
            self.context.delete(object)
            try self.context.save()
        }
    }

    // MARK: - Helpers

    private func fetchRequest() -> NSFetchRequest<NSManagedObject> {
        NSFetchRequest<NSManagedObject>(entityName: PersistenceController.sessionEntityName)
    }

    private func object(withID id: UUID) throws -> NSManagedObject? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func apply(_ session: FocusSession, to object: NSManagedObject) {
        object.setValue(session.id, forKey: "id")
        object.setValue(session.type.rawValue, forKey: "typeRaw")
        object.setValue(session.startTime, forKey: "startTime")
        object.setValue(session.endTime, forKey: "endTime")
        object.setValue(session.status.rawValue, forKey: "statusRaw")
        object.setValue(session.label, forKey: "label")
    }

    private func map(_ object: NSManagedObject) -> FocusSession? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let typeRaw = object.value(forKey: "typeRaw") as? String,
            let type = PulseArcCore.SessionType(rawValue: typeRaw),
            let startTime = object.value(forKey: "startTime") as? Date,
            let endTime = object.value(forKey: "endTime") as? Date,
            let statusRaw = object.value(forKey: "statusRaw") as? String,
            let status = FocusSession.Status(rawValue: statusRaw)
        else { return nil }
        return FocusSession(
            id: id, type: type, startTime: startTime, endTime: endTime,
            status: status, label: object.value(forKey: "label") as? String)
    }
}
