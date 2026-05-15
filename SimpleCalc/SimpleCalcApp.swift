import SwiftUI

@main
struct SimpleCalcApp: App {
    var body: some Scene {
        WindowGroup("SimpleCalc") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
