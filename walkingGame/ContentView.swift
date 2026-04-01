import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var locationService = LocationService()

    var body: some View {
        Group {
            if UserDefaults.standard.double(forKey: "playerLat") == 0 {
                SetupView(locationService: locationService, appState: appState)
            } else {
                MainTabView()
                    .environmentObject(appState)
            }
        }
        .onChange(of: locationService.location) {
            guard let loc = locationService.location,
                  UserDefaults.standard.double(forKey: "playerLat") == 0 else { return }
            appState.setStartCoordinate(loc.coordinate)
        }
        .preferredColorScheme(.dark)
    }
}

struct SetupView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var appState: AppState

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.10, blue: 0.12).ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Text("🌍").font(.system(size: 100))
                Text("WalkTheWorld")
                    .font(.custom("Georgia", size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Faites le tour du monde à pied.\nChaque pas compte ×10 sur le globe.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                Button {
                    locationService.requestPermission()
                } label: {
                    Label("Localiser mon point de départ", systemImage: "location.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .cornerRadius(16)
                }
                if locationService.location != nil {
                    Text("✓ Position détectée — chargement…")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                Spacer()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            PedometerView()
                .tabItem { Label("Marche", systemImage: "figure.walk") }
            GlobeMapView()
                .tabItem { Label("Globe", systemImage: "globe") }
        }
        .accentColor(.orange)
    }
}

#Preview {
    ContentView()
}
