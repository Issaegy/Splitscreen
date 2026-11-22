import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: Store
    @State private var showAddApp = false

    var body: some View {
        VStack(spacing: 0) {
            workspace
                .padding(10)
            DockView(showAddApp: $showAddApp)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.15), value: store.dragActive)
        .sheet(isPresented: $showAddApp) {
            AddAppView()
                .environmentObject(store)
        }
    }

    @ViewBuilder
    private var workspace: some View {
        if let id = store.maximizedPane,
           let pane = store.panes.first(where: { $0.id == id }) {
            PaneView(pane: pane)
                .id(pane.id)
        } else {
            SplitLayout(fraction: $store.fraction, vertical: store.vertical) {
                PaneView(pane: store.panes[0])
                    .id(store.panes[0].id)
            } second: {
                PaneView(pane: store.panes[1])
                    .id(store.panes[1].id)
            }
        }
    }
}
