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
  /// Where the user left off (it survives the app being killed), else the bundled sample guide.
  @State private var loaded = Result { () throws -> GuidePlayer in
    if let restored = GuidePlayer.restored(from: "player") { return restored }
    let player = GuidePlayer(guide: try GuidePlayer.loadBundled())
    player.persistenceName = "player"
    return player
  }

  var body: some View {
    switch loaded {
    case .success(let player):
      ContentView(player: player)
    case .failure(let error):
      Text("Couldn't load the guide: \(error.localizedDescription)")
        .padding()
    }
  }
}
