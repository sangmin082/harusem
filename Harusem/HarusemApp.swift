import SwiftUI

@main
struct HarusemApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.brand)
                // 전역 둥근 서체 — 아기자기한 인상의 기본기
                .fontDesign(.rounded)
        }
    }
}
