import SwiftUI

/// 앱 공통 디자인 시스템: 팔레트, 그라디언트, 버튼 스타일, 카드/칩 스타일.
/// 라이트 = 밝은 캔디 톤, 다크 = 같은 색상의 네온 파스텔 톤 (다크 모드 지원).
enum Theme {
    // MARK: - 팔레트 (캔디 톤)

    /// 브랜드 (캔디 퍼플블루).
    static let brand = Color(light: UIColor(red: 0.416, green: 0.353, blue: 0.878, alpha: 1),
                             dark: UIColor(red: 0.545, green: 0.490, blue: 1.0, alpha: 1))
    static let brandDeep = Color(light: UIColor(red: 0.306, green: 0.247, blue: 0.820, alpha: 1),
                                 dark: UIColor(red: 0.420, green: 0.360, blue: 0.950, alpha: 1))

    /// 별 (해바라기 골드).
    static let gold = Color(light: UIColor(red: 1.0, green: 0.788, blue: 0.235, alpha: 1),
                            dark: UIColor(red: 1.0, green: 0.820, blue: 0.320, alpha: 1))
    static let goldDeep = Color(light: UIColor(red: 1.0, green: 0.651, blue: 0.169, alpha: 1),
                                dark: UIColor(red: 1.0, green: 0.700, blue: 0.250, alpha: 1))

    /// 하트 (버블검 핑크).
    static let heart = Color(light: UIColor(red: 1.0, green: 0.420, blue: 0.616, alpha: 1),
                             dark: UIColor(red: 1.0, green: 0.480, blue: 0.660, alpha: 1))
    static let heartDeep = Color(light: UIColor(red: 0.941, green: 0.243, blue: 0.431, alpha: 1),
                                 dark: UIColor(red: 1.0, green: 0.320, blue: 0.500, alpha: 1))

    /// 스트릭 (귤 오렌지).
    static let flame = Color(light: UIColor(red: 1.0, green: 0.624, blue: 0.271, alpha: 1),
                             dark: UIColor(red: 1.0, green: 0.670, blue: 0.330, alpha: 1))
    static let flameDeep = Color(light: UIColor(red: 1.0, green: 0.420, blue: 0.208, alpha: 1),
                                 dark: UIColor(red: 1.0, green: 0.480, blue: 0.280, alpha: 1))

    static let success = Color(light: UIColor(red: 0.298, green: 0.851, blue: 0.482, alpha: 1),
                               dark: UIColor(red: 0.360, green: 0.900, blue: 0.550, alpha: 1))
    static let successDeep = Color(light: UIColor(red: 0.169, green: 0.706, blue: 0.361, alpha: 1),
                                   dark: UIColor(red: 0.220, green: 0.780, blue: 0.430, alpha: 1))

    /// 청록 (민트).
    static let teal = Color(light: UIColor(red: 0.208, green: 0.816, blue: 0.729, alpha: 1),
                            dark: UIColor(red: 0.280, green: 0.870, blue: 0.790, alpha: 1))
    static let tealDeep = Color(light: UIColor(red: 0.059, green: 0.663, blue: 0.557, alpha: 1),
                                dark: UIColor(red: 0.120, green: 0.730, blue: 0.630, alpha: 1))

    /// 보라 (라일락).
    static let purple = Color(light: UIColor(red: 0.694, green: 0.365, blue: 1.0, alpha: 1),
                              dark: UIColor(red: 0.750, green: 0.460, blue: 1.0, alpha: 1))
    static let purpleDeep = Color(light: UIColor(red: 0.557, green: 0.239, blue: 0.878, alpha: 1),
                                  dark: UIColor(red: 0.630, green: 0.340, blue: 0.940, alpha: 1))

    // MARK: - 그라디언트

    static var brandGradient: LinearGradient {
        LinearGradient(colors: [brand, brandDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var goldGradient: LinearGradient {
        LinearGradient(colors: [gold, goldDeep], startPoint: .top, endPoint: .bottom)
    }
    static var heartGradient: LinearGradient {
        LinearGradient(colors: [heart, heartDeep], startPoint: .top, endPoint: .bottom)
    }
    static var flameGradient: LinearGradient {
        LinearGradient(colors: [flame, flameDeep], startPoint: .top, endPoint: .bottom)
    }
    static var tealGradient: LinearGradient {
        LinearGradient(colors: [teal, tealDeep], startPoint: .top, endPoint: .bottom)
    }
    static var purpleGradient: LinearGradient {
        LinearGradient(colors: [purple, purpleDeep], startPoint: .top, endPoint: .bottom)
    }
    static var greenGradient: LinearGradient {
        LinearGradient(colors: [success, successDeep], startPoint: .top, endPoint: .bottom)
    }
    /// 무지개 포인트 (타겟 카드 테두리 등).
    static var rainbowGradient: LinearGradient {
        LinearGradient(colors: [brand, purple, heart, gold, teal],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// 레벨 배지용 컬러 순환 (알록달록한 레벨 맵).
    static func levelGradient(_ level: Int) -> LinearGradient {
        switch (level - 1) % 5 {
        case 0: goldGradient
        case 1: tealGradient
        case 2: heartGradient
        case 3: purpleGradient
        default: flameGradient
        }
    }

    // MARK: - 서피스

    /// 카드/타일의 기본 표면색 — 라이트는 순백, 다크는 밝은 남색 카드.
    static let surface = Color(light: UIColor.white,
                               dark: UIColor(red: 0.125, green: 0.125, blue: 0.200, alpha: 1))
    /// 표면 위에 얹는 아주 옅은 외곽선 (입체감).
    static let hairline = Color(light: UIColor(white: 0, alpha: 0.05),
                                dark: UIColor(white: 1, alpha: 0.09))
}

extension Color {
    /// 라이트/다크 각각 지정하는 동적 색.
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

/// 알록달록 앱 배경: 밝은 크림(라이트)/짙은 남색(다크) 베이스 위에 선명한 캔디 블롭.
/// 모든 화면 뒤에 깔린다 (리스트는 scrollContentBackground(.hidden)으로 비춰 보이게).
struct AppBackground: View {
    private static let base = Color(
        light: UIColor(red: 1.0, green: 0.985, blue: 0.955, alpha: 1),
        dark: UIColor(red: 0.070, green: 0.065, blue: 0.120, alpha: 1)
    )

    var body: some View {
        ZStack {
            Self.base
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    Circle()
                        .fill(Theme.brand.opacity(0.28))
                        .frame(width: w * 0.95, height: w * 0.95)
                        .offset(x: -w * 0.32, y: -h * 0.30)
                    Circle()
                        .fill(Theme.heart.opacity(0.26))
                        .frame(width: w * 0.85, height: w * 0.85)
                        .offset(x: w * 0.42, y: -h * 0.16)
                    Circle()
                        .fill(Theme.gold.opacity(0.28))
                        .frame(width: w * 0.85, height: w * 0.85)
                        .offset(x: w * 0.38, y: h * 0.34)
                    Circle()
                        .fill(Theme.teal.opacity(0.26))
                        .frame(width: w * 0.95, height: w * 0.95)
                        .offset(x: -w * 0.38, y: h * 0.22)
                    Circle()
                        .fill(Theme.purple.opacity(0.17))
                        .frame(width: w * 0.7, height: w * 0.7)
                        .offset(x: 0, y: h * 0.02)
                }
                .blur(radius: 64)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 버튼 스타일

/// 주요 액션: 브랜드 그라디언트 필 버튼.
struct ProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.brandGradient)
                    .shadow(color: Theme.brand.opacity(configuration.isPressed ? 0.1 : 0.3),
                            radius: 10, y: 5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// 보조 액션: 표면색 + 헤어라인 버튼.
struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.primary)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.hairline))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - 카드/칩

extension View {
    /// 표준 카드 컨테이너 (둥근 모서리 + 헤어라인 + 은은한 그림자).
    func harusemCard(cornerRadius: CGFloat = 20) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(Theme.hairline))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }

    /// 상태 바 등에 쓰는 캡슐 칩 배경.
    func chipBackground() -> some View {
        padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Theme.surface)
                    .overlay(Capsule().strokeBorder(Theme.hairline))
            )
    }
}
