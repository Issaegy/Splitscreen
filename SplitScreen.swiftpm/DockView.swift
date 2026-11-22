import SwiftUI

/// Das Dock unten: Apps zum Hineinziehen + Steuerung für das Layout.
struct DockView: View {
    @EnvironmentObject private var store: Store
    @Binding var showAddApp: Bool
    @State private var pendingItem: DockItem?

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(store.dockItems) { item in
                        AppTile(item: item, size: 50)
                            .contentShape(Rectangle())
                            .onTapGesture { tap(item) }
                            .onDrag { store.dragProvider(for: item) }
                            .contextMenu { contextMenu(for: item) }
                    }
                    addButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            Divider()
                .frame(height: 44)

            controls
                .padding(.horizontal, 10)
        }
        .background(.regularMaterial)
        .confirmationDialog(
            "Wo öffnen?",
            isPresented: Binding(
                get: { pendingItem != nil },
                set: { if !$0 { pendingItem = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingItem
        ) { item in
            ForEach(store.panes) { pane in
                Button(store.sideName(for: pane)) { store.open(item, in: pane) }
            }
        }
    }

    /// Antippen: in eine freie Hälfte öffnen, sonst nachfragen.
    private func tap(_ item: DockItem) {
        if let id = store.maximizedPane, let pane = store.panes.first(where: { $0.id == id }) {
            store.open(item, in: pane)
        } else if let empty = store.firstEmptyPane() {
            store.open(item, in: empty)
        } else {
            pendingItem = item
        }
    }

    @ViewBuilder
    private func contextMenu(for item: DockItem) -> some View {
        ForEach(store.panes) { pane in
            Button { store.open(item, in: pane) } label: {
                Label("\(store.sideName(for: pane)) öffnen", systemImage: store.sideSymbol(for: pane))
            }
        }
        if let app = item.app {
            Divider()
            Button(role: .destructive) { store.removeApp(app) } label: {
                Label("Aus Dock entfernen", systemImage: "trash")
            }
        }
    }

    private var addButton: some View {
        Button { showAddApp = true } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.secondary)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    )
                Text("Hinzufügen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var controls: some View {
        HStack(spacing: 2) {
            dockButton(
                store.vertical ? "rectangle.split.2x1" : "rectangle.split.1x2",
                label: store.vertical ? "Nebeneinander" : "Übereinander"
            ) {
                withAnimation(.spring(duration: 0.35)) { store.vertical.toggle() }
            }
            dockButton(
                store.vertical ? "arrow.up.arrow.down" : "arrow.left.arrow.right",
                label: "Seiten tauschen"
            ) {
                withAnimation(.spring(duration: 0.35)) { store.swapPanes() }
            }
            dockButton("equal.square", label: "Gleich groß") {
                withAnimation(.spring(duration: 0.3)) {
                    store.maximizedPane = nil
                    store.fraction = 0.5
                }
            }
        }
    }

    private func dockButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .medium))
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .hoverEffect()
        .accessibilityLabel(label)
    }
}

/// App-Symbol im Stil des iPad-Homescreens.
struct AppTile: View {
    let item: DockItem
    var size: CGFloat = 56

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(item.color.gradient)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: item.symbol)
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
            Text(item.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: size + 22)
        }
    }
}
