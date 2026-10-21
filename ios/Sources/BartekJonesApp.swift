import SwiftUI
import AVFoundation

@main
struct BartekJonesApp: App {

    init() {
        // Metronom i struny mają być słyszalne także przy włączonym
        // przełączniku ciszy — dla aplikacji do ćwiczenia to nie jest opcja.
        // WebKit sam podniesie sesję do .playAndRecord, gdy stroik włączy mikrofon.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            WebAppView()
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
                .persistentSystemOverlays(.hidden)
        }
    }
}
