import Foundation

/// Domain-owned persistence boundary. The Data layer provides a CoreData-backed implementation;
/// tests and previews provide in-memory mocks. Keeps the Domain free of any storage dependency.
public protocol SessionRepository: Sendable {
    func save(_ session: FocusSession) async throws
    func allSessions() async throws -> [FocusSession]
    func sessions(on day: Date, calendar: Calendar) async throws -> [FocusSession]
    func update(_ session: FocusSession) async throws
    func delete(id: UUID) async throws
}
