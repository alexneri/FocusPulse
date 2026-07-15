import SwiftUI
import FocusPulseCore

/// Full session history grouped by day, with swipe-to-delete and tap-to-edit (Stories 2.3 / 2.4).
struct HistoryView: View {
    @State private var sessions: [FocusSession] = []
    @State private var editing: FocusSession?
    private let repository: SessionRepository

    init(repository: SessionRepository = CoreDataSessionRepository()) {
        self.repository = repository
    }

    var body: some View {
        List {
            ForEach(groups) { group in
                Section {
                    ForEach(group.sessions) { session in
                        Button { editing = session } label: {
                            HistoryRow(session: session)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await delete(id: session.id) }
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                } header: {
                    Text(group.day, format: .dateTime.weekday(.wide).month().day())
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No history yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Completed sessions will appear here.")
                )
            }
        }
        .sheet(item: $editing) { session in
            EditSessionSheet(
                session: session,
                onSave: { updated in await update(updated) },
                onDelete: { await delete(id: session.id) }
            )
        }
        .task { await load() }
    }

    private var groups: [DayGroup] {
        let calendar = Calendar.current
        let byDay = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.startTime) }
        return byDay.keys.sorted(by: >).map { day in
            DayGroup(day: day, sessions: byDay[day]!.sorted { $0.startTime > $1.startTime })
        }
    }

    private func load() async {
        sessions = (try? await repository.allSessions()) ?? []
    }

    private func delete(id: UUID) async {
        try? await repository.delete(id: id)
        await load()
    }

    private func update(_ session: FocusSession) async {
        try? await repository.update(session)
        await load()
    }
}

struct DayGroup: Identifiable {
    let day: Date
    let sessions: [FocusSession]
    var id: Date { day }
}

// MARK: - Row

struct HistoryRow: View {
    let session: FocusSession

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.label ?? name).font(.subheadline).fontWeight(.medium)
                Text("\(session.startTime.formatted(date: .omitted, time: .shortened)) – \(session.endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text("\(Int(session.duration) / 60)m")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var color: Color {
        switch session.type {
        case .work: return .orange
        case .shortBreak: return .mint
        case .longBreak: return .teal
        }
    }

    private var name: String {
        switch session.type {
        case .work: return "Work Session"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}

// MARK: - Edit sheet (Story 2.4)

struct EditSessionSheet: View {
    let session: FocusSession
    let onSave: (FocusSession) async -> Void
    let onDelete: () async -> Void

    @State private var label: String
    @Environment(\.dismiss) private var dismiss

    init(session: FocusSession,
         onSave: @escaping (FocusSession) async -> Void,
         onDelete: @escaping () async -> Void) {
        self.session = session
        self.onSave = onSave
        self.onDelete = onDelete
        _label = State(initialValue: session.label ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Label") {
                    TextField("Session label", text: $label)
                }
                Section("Details") {
                    LabeledContent("Type", value: typeName)
                    LabeledContent("Started", value: session.startTime.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Duration", value: "\(Int(session.duration) / 60) min")
                }
                Section {
                    Button("Delete Session", role: .destructive) {
                        Task { await onDelete(); dismiss() }
                    }
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if let updated = FocusSession(
                                id: session.id, type: session.type,
                                startTime: session.startTime, endTime: session.endTime,
                                status: session.status,
                                label: label.trimmingCharacters(in: .whitespaces).isEmpty ? nil : label
                            ) {
                                await onSave(updated)
                            }
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var typeName: String {
        switch session.type {
        case .work: return "Work Session"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}
