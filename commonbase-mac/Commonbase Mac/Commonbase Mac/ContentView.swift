import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LedgerView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Ledger")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(1)

            GraphView()
                .tabItem {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                    Text("Graph")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .frame(width: 900, height: 700)
        .background(Color(NSColor.windowBackgroundColor))
        .tabViewStyle(.automatic)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToLedgerTab"))) { _ in
            selectedTab = 0
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}