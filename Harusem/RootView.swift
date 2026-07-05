import SwiftUI

struct RootView: View {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if model.session.isDayComplete {
                ResultsView(model: model)
            } else {
                PuzzleScreen(model: model)
            }
        }
        .animation(.default, value: model.session.isDayComplete)
        .task { model.store.start() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // ATT 팝업은 앱이 활성화된 뒤 요청해야 뜬다 (start는 1회 실행 가드 있음)
                model.ads.start()
                model.refreshForDateChange()
                model.refreshHearts()
            } else {
                model.save()
            }
        }
    }
}

#Preview {
    RootView()
}
