import SwiftUI
import WebKit

/// Eine Bildschirmhälfte mit Kopfleiste (Zurück, Adresse, Menü) und Inhalt.
struct PaneView: View {
    @EnvironmentObject private var store: Store
    @ObservedObject var pane: Pane
    @Environment(\.openURL) private var openURL

    @State private var isTargeted = false
    @State private var address = ""
    @FocusState private var addressFocused: Bool

    private var isMaximized: Bool { store.maximizedPane == pane.id }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ZStack {
                content
                if store.dragActive {
                    dropOverlay
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.primary.opacity(0.08),
                    lineWidth: isTargeted ? 3 : 1
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        .onDrop(of: [.url, .text], isTargeted: $isTargeted) { providers in
            store.handleDrop(providers, into: pane)
        }
        .animation(.easeInOut(duration: 0.15), value: isTargeted)
    }

    // MARK: Kopfleiste

    private var header: some View {
        HStack(spacing: 10) {
            switch pane.kind {
            case .web:
                Button { pane.webView.goBack() } label: {
                    Image(systemName: "chevron.backward")
                }
                .disabled(!pane.canGoBack)

                Button { pane.webView.goForward() } label: {
                    Image(systemName: "chevron.forward")
                }
                .disabled(!pane.canGoForward)

                addressField

                Button { pane.reloadOrStop() } label: {
                    Image(systemName: pane.isLoading ? "xmark" : "arrow.clockwise")
                }
            case .notes:
                Label("Notizen", systemImage: "note.text")
                    .font(.headline)
                Spacer()
            case .empty:
                Text(store.sideName(for: pane))
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            paneMenu
        }
        .font(.system(size: 17, weight: .medium))
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(.bar)
        .overlay(alignment: .bottom) {
            if pane.isWeb && pane.isLoading {
                ProgressView(value: pane.progress)
                    .progressViewStyle(.linear)
            }
        }
    }

    private var addressField: some View {
        TextField("Suchen oder Adresse eingeben", text: $address)
            .focused($addressFocused)
            .keyboardType(.webSearch)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.go)
            .multilineTextAlignment(addressFocused ? .leading : .center)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(Color(.tertiarySystemFill), in: Capsule())
            .onSubmit {
                store.open(text: address, in: pane)
                addressFocused = false
            }
            .onAppear(perform: syncAddress)
            .onChange(of: pane.kind) { _, _ in
                if !addressFocused { syncAddress() }
            }
            .onChange(of: addressFocused) { _, _ in
                syncAddress()
            }
    }

    private func syncAddress() {
        guard let url = pane.webURL else {
            address = ""
            return
        }
        if addressFocused {
            address = url.absoluteString
        } else {
            let host = url.host ?? url.absoluteString
            address = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        }
    }

    private var paneMenu: some View {
        Menu {
            if let url = pane.webURL {
                Button { pane.toggleDesktopMode() } label: {
                    Label(
                        pane.desktopMode ? "Mobile Website" : "Desktop-Website",
                        systemImage: pane.desktopMode ? "iphone" : "desktopcomputer"
                    )
                }
                Button { openURL(url) } label: {
                    Label("In Safari öffnen", systemImage: "safari")
                }
                ShareLink(item: url) {
                    Label("Teilen", systemImage: "square.and.arrow.up")
                }
                Divider()
            }

            Button {
                withAnimation(.spring(duration: 0.3)) { store.toggleMaximize(pane) }
            } label: {
                Label(
                    isMaximized ? "Splitscreen anzeigen" : "Vollbild",
                    systemImage: isMaximized ? "rectangle.split.2x1" : "arrow.up.left.and.arrow.down.right"
                )
            }

            Button {
                withAnimation(.spring(duration: 0.35)) { store.swapPanes() }
            } label: {
                Label("Seiten tauschen", systemImage: "arrow.left.arrow.right")
            }

            if pane.kind != .empty {
                Divider()
                Button(role: .destructive) { pane.show(.empty) } label: {
                    Label("Schließen", systemImage: "xmark.circle")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
    }

    // MARK: Inhalt

    @ViewBuilder
    private var content: some View {
        switch pane.kind {
        case .empty:
            EmptyPaneView(pane: pane)
        case .web:
            WebContainer(webView: pane.webView)
        case .notes:
            NotesView()
        }
    }

    /// Wird über die Hälfte gelegt, während eine App aus dem Dock gezogen wird.
    /// (Sonst würde die Webseite selbst den Drop abfangen.)
    private var dropOverlay: some View {
        ZStack {
            Rectangle()
                .fill(Color.accentColor.opacity(isTargeted ? 0.22 : 0.08))
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.system(size: 40, weight: .semibold))
                Text(isTargeted ? "Loslassen zum Öffnen" : "Hier ablegen")
                    .font(.headline)
            }
            .foregroundStyle(Color.accentColor)
        }
        .contentShape(Rectangle())
        .onTapGesture { store.dragActive = false }
        .transition(.opacity)
    }
}

/// Leere Hälfte: Hinweis + Schnellauswahl aller Apps.
struct EmptyPaneView: View {
    @EnvironmentObject private var store: Store
    let pane: Pane

    private let columns = [GridItem(.adaptive(minimum: 76), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Image(systemName: "plus.rectangle.on.rectangle")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("App hierher ziehen")
                        .font(.title3.weight(.semibold))
                    Text("Zieh eine App aus dem Dock in diese Hälfte – oder tippe hier auf eine.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(store.dockItems) { item in
                        Button { store.open(item, in: pane) } label: {
                            AppTile(item: item, size: 52)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 480)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }
}

struct NotesView: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        TextEditor(text: $store.notes)
            .font(.system(.body, design: .rounded))
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .overlay(alignment: .topLeading) {
                if store.notes.isEmpty {
                    Text("Notizen schreiben …")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
    }
}

/// Bettet den (dauerhaft existierenden) WKWebView einer Hälfte in SwiftUI ein.
struct WebContainer: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground
        attach(to: container)
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        if webView.superview !== container {
            attach(to: container)
        }
    }

    private func attach(to container: UIView) {
        webView.removeFromSuperview()
        webView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
}
