import SwiftUI

/// Was gerade in einer Bildschirmhälfte angezeigt wird.
enum PaneKind: Codable, Equatable {
    case empty
    case web(URL)
    case notes
}

/// Eine "App" im Dock – technisch eine Web-App (Website), die in einer
/// Bildschirmhälfte geöffnet wird.
struct WebApp: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var address: String
    var symbol: String
    var hue: Double

    var url: URL? { URLInput.resolve(address) }

    static let defaults: [WebApp] = [
        WebApp(name: "YouTube", address: "https://m.youtube.com", symbol: "play.rectangle.fill", hue: 0.0),
        WebApp(name: "Google", address: "https://www.google.com", symbol: "magnifyingglass", hue: 0.58),
        WebApp(name: "Wikipedia", address: "https://de.m.wikipedia.org", symbol: "book.fill", hue: 0.68),
        WebApp(name: "Karten", address: "https://maps.google.com", symbol: "map.fill", hue: 0.33),
        WebApp(name: "Gmail", address: "https://mail.google.com", symbol: "envelope.fill", hue: 0.03),
        WebApp(name: "Übersetzer", address: "https://translate.google.com", symbol: "character.bubble.fill", hue: 0.5),
        WebApp(name: "Claude", address: "https://claude.ai", symbol: "bubble.left.and.bubble.right.fill", hue: 0.07)
    ]
}

/// Ein Eintrag im Dock: entweder die eingebauten Notizen oder eine Web-App.
enum DockItem: Identifiable, Hashable {
    case notes
    case app(WebApp)

    var id: String {
        switch self {
        case .notes: return "notes"
        case .app(let app): return app.id.uuidString
        }
    }

    var name: String {
        switch self {
        case .notes: return "Notizen"
        case .app(let app): return app.name
        }
    }

    var symbol: String {
        switch self {
        case .notes: return "note.text"
        case .app(let app): return app.symbol
        }
    }

    var color: Color {
        switch self {
        case .notes: return Palette.color(0.13)
        case .app(let app): return Palette.color(app.hue)
        }
    }

    var app: WebApp? {
        if case .app(let app) = self { return app }
        return nil
    }
}

enum Palette {
    static let hues: [Double] = [0.0, 0.07, 0.13, 0.33, 0.5, 0.58, 0.68, 0.78, 0.9]

    static let symbols: [String] = [
        "globe", "play.rectangle.fill", "magnifyingglass", "book.fill", "map.fill",
        "envelope.fill", "character.bubble.fill", "bubble.left.and.bubble.right.fill",
        "music.note", "cart.fill", "newspaper.fill", "calendar", "cloud.fill",
        "graduationcap.fill", "gamecontroller.fill", "chart.bar.fill", "tv.fill",
        "photo.fill", "doc.text.fill", "star.fill"
    ]

    static func color(_ hue: Double) -> Color {
        Color(hue: hue, saturation: 0.72, brightness: 0.88)
    }
}

/// Wandelt Eingaben wie "youtube.com", "https://…" oder "Wetter Berlin"
/// in eine ladbare Adresse um (Suchbegriffe werden zu einer Google-Suche).
enum URLInput {
    static func resolve(_ input: String) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        if let url = URL(string: text), let scheme = url.scheme?.lowercased() {
            if (scheme == "http" || scheme == "https"), url.host != nil { return url }
            if scheme == "file" { return nil }
        }

        if !text.contains(" "), text.contains("."),
           let url = URL(string: "https://" + text), url.host != nil {
            return url
        }

        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: text)]
        return components?.url
    }
}
