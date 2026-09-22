import SwiftUI

@main
struct FasTradeV7App: App {
    @StateObject private var store = TradeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
