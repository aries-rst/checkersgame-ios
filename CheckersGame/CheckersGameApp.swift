import SwiftUI

@main
struct CheckersGameApp: App {
    init() {
        AdManager.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
