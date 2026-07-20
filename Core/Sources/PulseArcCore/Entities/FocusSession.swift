import Foundation

/// Aggregate root: an immutable record of a single (completed or abandoned) session.
/// Invariant: `endTime` must be strictly after `startTime`, so `duration` is always positive.
public struct FocusSession: Identifiable, Equatable, Sendable {
    public enum Status: String, Codable, Sendable {
        case completed
        case abandoned
    }

    public let id: UUID
    public let type: SessionType
    public let startTime: Date
    public let endTime: Date
    public let status: Status
    public var label: String?

    /// Failable: returns `nil` if the invariant (`endTime > startTime`) is violated.
    public init?(
        id: UUID = UUID(),
        type: SessionType,
        startTime: Date,
        endTime: Date,
        status: Status = .completed,
        label: String? = nil
    ) {
        guard endTime > startTime else { return nil }
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.label = label?.trimmedNonEmpty
    }

    /// Positive by construction.
    public var duration: TimeInterval { endTime.timeIntervalSince(startTime) }

    /// Display label, falling back to "Session at <start>" when none was given.
    public func displayLabel(formatter: DateFormatter) -> String {
        label ?? "Session at \(formatter.string(from: startTime))"
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
