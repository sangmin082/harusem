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
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.refreshForDateChange()
            } else {
                model.save()
            }
        }
    }
}

#Preview {
    RootView()
}
