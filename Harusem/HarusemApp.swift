import SwiftUI

@main
struct HarusemApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.brand)
                // 어린이 취향의 밝은 캔디 톤을 유지하기 위해 라이트 모드 고정
                .preferredColorScheme(.light)
        }
    }
}
