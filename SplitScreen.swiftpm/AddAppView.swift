import SwiftUI

/// Eigene App (Website) zum Dock hinzufügen.
struct AddAppView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var address = ""
    @State private var symbol = "globe"
    @State private var hue = Palette.hues[5]

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    private var draft: WebApp {
        WebApp(name: trimmedName.isEmpty ? "Neue App" : trimmedName, address: address, symbol: symbol, hue: hue)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && !address.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        AppTile(item: .app(draft), size: 72)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                Section("Website") {
                    TextField("Name (z. B. Netflix)", text: $name)
                    TextField("Adresse (z. B. netflix.com)", text: $address)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Symbol") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
                        ForEach(Palette.symbols, id: \.self) { candidate in
                            Image(systemName: candidate)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(
                                    candidate == symbol ? Palette.color(hue).opacity(0.25) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture { symbol = candidate }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Farbe") {
                    HStack(spacing: 12) {
                        ForEach(Palette.hues, id: \.self) { candidate in
                            Circle()
                                .fill(Palette.color(candidate))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().strokeBorder(.primary, lineWidth: candidate == hue ? 3 : 0)
                                )
                                .onTapGesture { hue = candidate }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("App hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        store.addApp(draft)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
