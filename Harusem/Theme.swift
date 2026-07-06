import SwiftUI

/// 앱 공통 디자인 시스템: 팔레트, 그라디언트, 버튼 스타일, 카드/칩 스타일.
/// 라이트/다크 모두 대응 (UIColor dynamic provider).
enum Theme {
    // MARK: - 팔레트

    /// 브랜드 (인디고). 앱 아이콘의 네이비 타일과 같은 계열.
    static let brand = Color(light: UIColor(red: 0.345, green: 0.337, blue: 0.839, alpha: 1),
                             dark: UIColor(red: 0.545, green: 0.537, blue: 1.0, alpha: 1))
    static let brandDeep = Color(light: UIColor(red: 0.235, green: 0.227, blue: 0.690, alpha: 1),
                                 dark: UIColor(red: 0.404, green: 0.396, blue: 0.910, alpha: 1))

    /// 별 (골드).
    static let gold = Color(light: UIColor(red: 1.0, green: 0.773, blue: 0.161, alpha: 1),
                            dark: UIColor(red: 1.0, green: 0.812, blue: 0.250, alpha: 1))
    static let goldDeep = Color(light: UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1),
                                dark: UIColor(red: 1.0, green: 0.624, blue: 0.039, alpha: 1))

    /// 하트 (레드/핑크).
    static let heart = Color(light: UIColor(red: 1.0, green: 0.216, blue: 0.373, alpha: 1),
                             dark: UIColor(red: 1.0, green: 0.269, blue: 0.420, alpha: 1))
    static let heartDeep = Color(light: UIColor(red: 0.827, green: 0.078, blue: 0.220, alpha: 1),
                                 dark: UIColor(red: 0.878, green: 0.129, blue: 0.271, alpha: 1))

    /// 스트릭 (오렌지).
    static let flame = Color(light: UIColor(red: 1.0, green: 0.624, blue: 0.039, alpha: 1),
                             dark: UIColor(red: 1.0, green: 0.663, blue: 0.078, alpha: 1))
    static let flameDeep = Color(light: UIColor(red: 1.0, green: 0.271, blue: 0.188, alpha: 1),
                                 dark: UIColor(red: 1.0, green: 0.310, blue: 0.227, alpha: 1))

    static let success = Color(light: UIColor(red: 0.204, green: 0.780, blue: 0.349, alpha: 1),
                               dark: UIColor(red: 0.188, green: 0.820, blue: 0.345, alpha: 1))
    static let successDeep = Color(light: UIColor(red: 0.086, green: 0.596, blue: 0.239, alpha: 1),
                                   dark: UIColor(red: 0.098, green: 0.663, blue: 0.267, alpha: 1))

    /// 청록 (연산자/배지 순환용).
    static let teal = Color(light: UIColor(red: 0.110, green: 0.714, blue: 0.671, alpha: 1),
                            dark: UIColor(red: 0.251, green: 0.831, blue: 0.780, alpha: 1))
    static let tealDeep = Color(light: UIColor(red: 0.0, green: 0.541, blue: 0.549, alpha: 1),
                                dark: UIColor(red: 0.051, green: 0.651, blue: 0.620, alpha: 1))

    /// 보라 (연산자/배지 순환용).
    static let purple = Color(light: UIColor(red: 0.686, green: 0.322, blue: 0.871, alpha: 1),
                              dark: UIColor(red: 0.753, green: 0.439, blue: 0.929, alpha: 1))
    static let purpleDeep = Color(light: UIColor(red: 0.537, green: 0.173, blue: 0.749, alpha: 1),
                                  dark: UIColor(red: 0.600, green: 0.278, blue: 0.820, alpha: 1))

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

    /// 카드/타일의 기본 표면색.
    static let surface = Color(.secondarySystemBackground)
    /// 표면 위에 얹는 아주 옅은 외곽선 (입체감).
    static let hairline = Color.primary.opacity(0.06)
}

extension Color {
    /// 라이트/다크 각각 지정하는 동적 색.
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

/// 알록달록 앱 배경: 베이스 위에 크게 흐린 컬러 블롭 4개.
/// 모든 화면 뒤에 깔린다 (리스트는 scrollContentBackground(.hidden)으로 비춰 보이게).
struct AppBackground: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    Circle()
                        .fill(Theme.brand.opacity(0.20))
                        .frame(width: w * 0.95, height: w * 0.95)
                        .offset(x: -w * 0.32, y: -h * 0.30)
                    Circle()
                        .fill(Theme.heart.opacity(0.14))
                        .frame(width: w * 0.85, height: w * 0.85)
                        .offset(x: w * 0.42, y: -h * 0.16)
                    Circle()
                        .fill(Theme.gold.opacity(0.15))
                        .frame(width: w * 0.85, height: w * 0.85)
                        .offset(x: w * 0.38, y: h * 0.34)
                    Circle()
                        .fill(Theme.teal.opacity(0.16))
                        .frame(width: w * 0.95, height: w * 0.95)
                        .offset(x: -w * 0.38, y: h * 0.22)
                }
                .blur(radius: 72)
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
