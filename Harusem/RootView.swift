import SwiftUI
import HarusemKit

struct RootView: View {
    @State private var model = AppModel()
    @State private var selectedTab: Tab = .home
    @State private var showHearts = false
    @Environment(\.scenePhase) private var scenePhase

    private let heartTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    enum Tab: Hashable {
        case home, calendar, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            CalendarTab(model: model) { selectedTab = .home }
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(Tab.calendar)

            StatsView(model: model)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            // 우상단 고정 하트 (모든 탭 공통)
            HStack {
                Spacer()
                HeartChip(model: model) { showHearts = true }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
        }
        .sheet(isPresented: $showHearts) { HeartsView(model: model) }
        .onReceive(heartTimer) { _ in
            model.refreshHearts()
        }
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

    private var homeTab: some View {
        Group {
            if model.session.isDayComplete {
                ResultsView(model: model)
            } else {
                PuzzleScreen(model: model)
            }
        }
        .animation(.default, value: model.session.isDayComplete)
    }
}

#Preview {
    RootView()
}
