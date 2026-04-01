import SwiftUI
#if canImport(MapboxMaps)
import MapboxMaps
#endif

@main
struct walkingGameApp: App {
    init() {
#if canImport(MapboxMaps)
        // Set your Mapbox token in MAPBOX_TOKEN environment variable or replace the placeholder below
        // Get your token at account.mapbox.com
        MapboxOptions.accessToken = ProcessInfo.processInfo.environment["MAPBOX_TOKEN"] ?? "YOUR_MAPBOX_TOKEN_HERE"
#else
        // MapboxMaps package is not available. Add the dependency via SPM to enable Mapbox features.
        print("[walkingGameApp] MapboxMaps not available. Add the Mapbox SDK via Swift Package Manager to enable maps.")
#endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
