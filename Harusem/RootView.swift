import SwiftUI
import HarusemKit

struct RootView: View {
    @State private var model = AppModel()
    @State private var selectedTab: Tab = .home
    @State private var showHearts = false
    @Environment(\.scenePhase) private var scenePhase

    private let heartTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    enum Tab: Hashable {
        case home, levels, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            LevelsTab(model: model) { selectedTab = .home }
                .tabItem { Label("Levels", systemImage: "square.grid.3x3.fill") }
                .tag(Tab.levels)

            StatsView(model: model)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            // 상단 고정 상태 바: 별/스트릭 + 하트 잔량/충전 카운트다운 (모든 탭 공통).
            // 배경(.bar)이 노치 영역까지 채워 아래 콘텐츠와 겹치지 않는다.
            StatusBar(model: model) { showHearts = true }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(.bar)
                .overlay(alignment: .bottom) { Divider() }
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
                model.refreshHearts()
            } else {
                model.save()
            }
        }
    }

    private var homeTab: some View {
        Group {
            if !model.isPlaying {
                // 홈 = 레벨 맵. 박스를 눌러야 플레이 화면으로 들어간다.
                LevelHomeView(model: model)
            } else if model.session.isDayComplete {
                LevelResultView(model: model)
            } else {
                PuzzleScreen(model: model)
            }
        }
        .animation(.default, value: model.session.isDayComplete)
        .animation(.default, value: model.isPlaying)
    }
}

#Preview {
    RootView()
}
