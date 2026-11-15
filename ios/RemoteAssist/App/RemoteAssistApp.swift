import SwiftUI

@main
struct RemoteAssistApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
        .preferredColorScheme(.dark)
        // Team Sonic teal, as in the explainer video.
        .tint(Color(red: 0.18, green: 0.83, blue: 0.75))
    }
  }
}

private struct RootView: View {
  @State private var loaded = Result { try GuidePlayer.loadBundled() }

  var body: some View {
    switch loaded {
    case .success(let guide):
      ContentView(player: GuidePlayer(guide: guide))
    case .failure(let error):
      Text("Couldn't load the guide: \(error.localizedDescription)")
        .padding()
    }
  }
}
