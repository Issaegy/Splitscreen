import SwiftUI
import UniformTypeIdentifiers

struct SavedLayout: Codable {
    var panes: [PaneKind]
    var fraction: Double
    var vertical: Bool

    static let standard = SavedLayout(panes: [.empty, .empty], fraction: 0.5, vertical: false)
}

/// Zentraler Zustand der App: Dock-Apps, die zwei Hälften und das Layout.
/// Alles wird automatisch gespeichert und beim nächsten Start wiederhergestellt.
@MainActor
final class Store: ObservableObject {
    static let dragPrefix = "splitscreen-item:"

    private enum Keys {
        static let apps = "apps.v1"
        static let layout = "layout.v1"
        static let notes = "notes.v1"
    }

    @Published var apps: [WebApp] { didSet { saveApps() } }
    @Published var panes: [Pane]
    @Published var fraction: Double { didSet { saveLayout() } }
    @Published var vertical: Bool { didSet { saveLayout() } }
    @Published var notes: String { didSet { UserDefaults.standard.set(notes, forKey: Keys.notes) } }
    @Published var maximizedPane: UUID?
    /// true, solange eine App aus dem Dock gezogen wird → Ablagefläche einblenden.
    @Published var dragActive = false

    private var dragToken = UUID()

    init() {
        let defaults = UserDefaults.standard
        let decoder = JSONDecoder()

        apps = defaults.data(forKey: Keys.apps)
            .flatMap { try? decoder.decode([WebApp].self, from: $0) } ?? WebApp.defaults

        let layout = defaults.data(forKey: Keys.layout)
            .flatMap { try? decoder.decode(SavedLayout.self, from: $0) } ?? .standard

        var kinds = Array(layout.panes.prefix(2))
        while kinds.count < 2 { kinds.append(.empty) }
        panes = kinds.map { Pane(kind: $0) }

        fraction = min(max(layout.fraction, 0.15), 0.85)
        vertical = layout.vertical
        notes = defaults.string(forKey: Keys.notes) ?? ""

        for pane in panes {
            pane.onChange = { [weak self] in self?.saveLayout() }
        }
    }

    // MARK: Dock

    var dockItems: [DockItem] {
        apps.map { DockItem.app($0) } + [.notes]
    }

    func item(withID id: String) -> DockItem? {
        dockItems.first { $0.id == id }
    }

    func addApp(_ app: WebApp) {
        apps.append(app)
    }

    func removeApp(_ app: WebApp) {
        apps.removeAll { $0.id == app.id }
    }

    // MARK: Hälften

    func firstEmptyPane() -> Pane? {
        panes.first { $0.kind == .empty }
    }

    func sideName(for pane: Pane) -> String {
        let index = panes.firstIndex { $0.id == pane.id } ?? 0
        if vertical {
            return index == 0 ? "Oben" : "Unten"
        }
        return index == 0 ? "Links" : "Rechts"
    }

    func sideSymbol(for pane: Pane) -> String {
        let index = panes.firstIndex { $0.id == pane.id } ?? 0
        if vertical {
            return index == 0 ? "rectangle.tophalf.filled" : "rectangle.bottomhalf.filled"
        }
        return index == 0 ? "rectangle.lefthalf.filled" : "rectangle.righthalf.filled"
    }

    func open(_ item: DockItem, in pane: Pane) {
        switch item {
        case .notes:
            pane.show(.notes)
        case .app(let app):
            if let url = app.url { pane.show(.web(url)) }
        }
        if let maximized = maximizedPane, maximized != pane.id {
            maximizedPane = nil
        }
    }

    /// Öffnet eine eingetippte/abgelegte Adresse, einen Suchbegriff oder eine Dock-App.
    func open(text: String, in pane: Pane) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.hasPrefix(Self.dragPrefix) {
            let id = String(trimmed.dropFirst(Self.dragPrefix.count))
            if let item = item(withID: id) { open(item, in: pane) }
            return
        }

        if let url = URLInput.resolve(trimmed) {
            pane.show(.web(url))
        }
    }

    func swapPanes() {
        guard panes.count == 2 else { return }
        panes.swapAt(0, 1)
        saveLayout()
    }

    func toggleMaximize(_ pane: Pane) {
        maximizedPane = (maximizedPane == pane.id) ? nil : pane.id
    }

    // MARK: Drag & Drop

    /// Liefert die Drag-Daten für eine Dock-App und blendet die Ablageflächen ein.
    func dragProvider(for item: DockItem) -> NSItemProvider {
        let token = UUID()
        dragToken = token
        dragActive = true

        // Falls der Drag abgebrochen wird, gibt es keine Rückmeldung –
        // die Ablageflächen verschwinden daher nach kurzer Zeit von selbst.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(12))
            guard let self, self.dragToken == token else { return }
            self.dragActive = false
        }

        return NSItemProvider(object: (Self.dragPrefix + item.id) as NSString)
    }

    /// Verarbeitet alles, was auf eine Hälfte gezogen wird:
    /// Dock-Apps, Links aus Safari/anderen Apps oder einfacher Text.
    func handleDrop(_ providers: [NSItemProvider], into pane: Pane) -> Bool {
        dragActive = false
        guard let provider = providers.first else { return false }

        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            _ = provider.loadObject(ofClass: URL.self) { [weak self] url, _ in
                guard let url else { return }
                Task { @MainActor in
                    self?.open(text: url.absoluteString, in: pane)
                }
            }
            return true
        }

        if provider.canLoadObject(ofClass: String.self) {
            _ = provider.loadObject(ofClass: String.self) { [weak self] text, _ in
                guard let text else { return }
                Task { @MainActor in
                    self?.open(text: text, in: pane)
                }
            }
            return true
        }

        return false
    }

    // MARK: Speichern

    func saveLayout() {
        let layout = SavedLayout(panes: panes.map { $0.kind }, fraction: fraction, vertical: vertical)
        if let data = try? JSONEncoder().encode(layout) {
            UserDefaults.standard.set(data, forKey: Keys.layout)
        }
    }

    private func saveApps() {
        if let data = try? JSONEncoder().encode(apps) {
            UserDefaults.standard.set(data, forKey: Keys.apps)
        }
    }
}
