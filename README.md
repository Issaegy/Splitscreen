# SplitScreen für iPad

Eine iPad-App, die den Bildschirm in **zwei Hälften** teilt. Du ziehst „Apps“ aus dem
Dock unten in die linke oder rechte Hälfte, verschiebst den Trenner in der Mitte und
kannst beide Seiten gleichzeitig benutzen.

Geschrieben in **Swift / SwiftUI**, der nativen Sprache für iPad-Apps.

## Wichtig vorab: was technisch geht und was nicht

Apple erlaubt es **keiner** App aus dem App Store, andere installierte Apps (z. B. die
echte YouTube-, WhatsApp- oder Notizen-App) in sich einzubetten oder deren Fenster zu
steuern. Jede App läuft in ihrer eigenen „Sandbox“. Den System-Splitscreen kann deshalb
nur Apple selbst zurückbringen.

Diese App macht deshalb das, was erlaubt ist: Jede Hälfte enthält einen eigenen Browser.
Damit funktionieren alle Dienste, die es auch als Website gibt (YouTube, Google, Gmail,
Wikipedia, Karten, Übersetzer, Claude, Netflix, Office 365, Schul-Plattformen …), plus
eingebaute **Notizen**.

> Tipp: Mit iPadOS 26 ist Multitasking nicht ganz verschwunden, es wurde durch frei
> verschiebbare Fenster ersetzt. Unter *Einstellungen → Multitasking & Gesten* auf
> **Fenster-Apps** umstellen. Danach kann man ein Fenster an den linken oder rechten
> Rand ziehen oder über die Fenstertasten oben links „links/rechts anordnen“ wählen.
> So lassen sich auch echte Apps wieder nebeneinander anzeigen.

## Funktionen

- **Zwei Hälften** nebeneinander oder übereinander (Button im Dock)
- **Trenner verschieben**: ziehen zum Ändern der Größe, doppelt tippen für 50/50, rastet in der Mitte ein
- **Drag & Drop**: App-Symbol aus dem Dock in eine Hälfte ziehen
  - Auch **Links aus Safari** oder anderen Apps lassen sich direkt in eine Hälfte ziehen
  - Gezogener Text wird automatisch gesucht
- **Antippen** öffnet eine App in der freien Hälfte (sonst wird gefragt: links oder rechts?)
- **Lange drücken** auf ein Symbol: „Links öffnen“, „Rechts öffnen“, „Aus Dock entfernen“
- **Eigene Apps hinzufügen** (Name, Adresse, Symbol, Farbe)
- Pro Hälfte: Zurück/Vor, Adressleiste/Suche, Neu laden, Desktop- oder Mobil-Website,
  in Safari öffnen, Teilen, **Vollbild**, Seiten tauschen, Schließen
- Alles wird **gespeichert**: Beim nächsten Start sind die gleichen Seiten wieder offen.
  Logins bleiben erhalten.

## Auf das iPad bringen

### Variante A: direkt auf dem iPad, ohne Mac
1. Die kostenlose App **Swift Playgrounds** aus dem App Store laden.
2. Den Ordner `SplitScreen.swiftpm` aufs iPad kopieren (z. B. über iCloud Drive oder die
   Dateien-App; das Repo als ZIP herunterladen und entpacken).
3. In der Dateien-App auf `SplitScreen.swiftpm` tippen. Das Projekt öffnet sich in Swift Playgrounds.
4. Oben auf **▶︎ Ausführen** tippen. Über das Fenster-Symbol kann man die App im Vollbild starten.

### Variante B: mit einem Mac und Xcode
1. `SplitScreen.swiftpm` in Xcode öffnen (Doppelklick).
2. iPad anschließen, als Ziel auswählen und unter *Signing* das eigene Apple-Konto wählen.
3. **Run** drücken. Die App landet dann als richtige App auf dem Homescreen.
   Mit einem kostenlosen Apple-Konto muss man das alle 7 Tage wiederholen.

## Projektaufbau

```
SplitScreen.swiftpm/
├── Package.swift        App-Konfiguration (Swift Playgrounds / Xcode)
├── SplitScreenApp.swift Einstiegspunkt
├── ContentView.swift    Hauptansicht: Splitscreen + Dock
├── SplitLayout.swift    Zwei Bereiche mit verschiebbarem Trenner
├── PaneView.swift       Eine Hälfte: Kopfleiste, Browser, Notizen, Ablagefläche
├── Pane.swift           Zustand und Browser einer Hälfte
├── DockView.swift       Dock mit ziehbaren App-Symbolen
├── AddAppView.swift     Eigene App hinzufügen
├── Store.swift          Zentraler Zustand, Drag & Drop, Speichern
└── Models.swift         Datenmodelle, Standard-Apps, Adress-Erkennung
```

## Bekannte Grenzen

- Echte installierte Apps lassen sich nicht einbetten (siehe oben).
- Manche Seiten mit Kopierschutz (z. B. einige Streaming-Dienste) oder strengen
  Login-Regeln funktionieren im eingebetteten Browser eventuell nicht.
- Es gibt zwei Hälften. Drei oder mehr Bereiche wären eine mögliche Erweiterung.
