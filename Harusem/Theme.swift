import SwiftUI

/// 앱 공통 디자인 시스템: 팔레트, 그라디언트, 버튼 스타일, 카드/칩 스타일.
/// 라이트/다크 모두 대응 (UIColor dynamic provider).
enum Theme {
    // MARK: - 팔레트

    // 밝고 쨍한 캔디 톤 팔레트 (앱은 라이트 모드 고정 — 어린이 취향의 화사한 톤 유지).

    /// 브랜드 (캔디 퍼플블루).
    static let brand = UIColor(red: 0.416, green: 0.353, blue: 0.878, alpha: 1).asColor
    static let brandDeep = UIColor(red: 0.306, green: 0.247, blue: 0.820, alpha: 1).asColor

    /// 별 (해바라기 골드).
    static let gold = UIColor(red: 1.0, green: 0.788, blue: 0.235, alpha: 1).asColor
    static let goldDeep = UIColor(red: 1.0, green: 0.651, blue: 0.169, alpha: 1).asColor

    /// 하트 (버블검 핑크).
    static let heart = UIColor(red: 1.0, green: 0.420, blue: 0.616, alpha: 1).asColor
    static let heartDeep = UIColor(red: 0.941, green: 0.243, blue: 0.431, alpha: 1).asColor

    /// 스트릭 (귤 오렌지).
    static let flame = UIColor(red: 1.0, green: 0.624, blue: 0.271, alpha: 1).asColor
    static let flameDeep = UIColor(red: 1.0, green: 0.420, blue: 0.208, alpha: 1).asColor

    static let success = UIColor(red: 0.298, green: 0.851, blue: 0.482, alpha: 1).asColor
    static let successDeep = UIColor(red: 0.169, green: 0.706, blue: 0.361, alpha: 1).asColor

    /// 청록 (민트).
    static let teal = UIColor(red: 0.208, green: 0.816, blue: 0.729, alpha: 1).asColor
    static let tealDeep = UIColor(red: 0.059, green: 0.663, blue: 0.557, alpha: 1).asColor

    /// 보라 (라일락).
    static let purple = UIColor(red: 0.694, green: 0.365, blue: 1.0, alpha: 1).asColor
    static let purpleDeep = UIColor(red: 0.557, green: 0.239, blue: 0.878, alpha: 1).asColor

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

    /// 카드/타일의 기본 표면색 — 컬러 배경 위에 뜨는 순백 카드.
    static let surface = Color.white
    /// 본문 잉크 (짙은 네이비 — 순검정보다 부드럽다).
    static let ink = UIColor(red: 0.20, green: 0.20, blue: 0.35, alpha: 1).asColor
    /// 표면 위에 얹는 아주 옅은 외곽선 (입체감).
    static let hairline = Color.black.opacity(0.05)
}

extension UIColor {
    var asColor: Color { Color(uiColor: self) }
}

/// 알록달록 앱 배경: 밝은 크림 베이스 위에 선명한 캔디 블롭.
/// 모든 화면 뒤에 깔린다 (리스트는 scrollContentBackground(.hidden)으로 비춰 보이게).
struct AppBackground: View {
    var body: some View {
        ZStack {
            // 밝은 크림빛 베이스 (순백보다 따뜻하게)
            Color(uiColor: UIColor(red: 1.0, green: 0.985, blue: 0.955, alpha: 1))
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    Circle()
                        .fill(Theme.brand.opacity(0.30))
                        .frame(width: w * 0.95, height: w * 0.95)
                        .offset(x: -w * 0.32, y: -h * 0.30)
                    Circle()
                        .fill(Theme.heart.opacity(0.28))
                        .frame(width: w * 0.85, height: w * 0.85)
                        .offset(x: w * 0.42, y: -h * 0.16)
                    Circle()
                        .fill(Theme.gold.opacity(0.30))
                        .frame(width: w * 0.85, height: w * 0.85)
                        .offset(x: w * 0.38, y: h * 0.34)
                    Circle()
                        .fill(Theme.teal.opacity(0.28))
                        .frame(width: w * 0.95, height: w * 0.95)
                        .offset(x: -w * 0.38, y: h * 0.22)
                    Circle()
                        .fill(Theme.purple.opacity(0.18))
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
