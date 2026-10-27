import SwiftData
import SwiftUI

@main
struct LingoLamaApp: App {
    @State private var progress = PlayerProgress()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(progress)
                .fontDesign(.rounded)
        }
        .modelContainer(for: [Lesson.self, Word.self])
    }
}
