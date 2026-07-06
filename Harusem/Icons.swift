import SwiftUI

/// 직접 그린 벡터 아이콘들 — 이모지 대신 사용한다.
/// 모든 아이콘은 프레임 크기에 비례해 스케일된다.

// MARK: - 도형

/// 5각 별.
struct StarShape: Shape {
    var innerRatio: CGFloat = 0.42

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        let step = CGFloat.pi / 5
        var path = Path()
        for i in 0..<10 {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(i) * step - .pi / 2
            let point = CGPoint(x: center.x + radius * cos(angle),
                                y: center.y + radius * sin(angle))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// 하트.
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }
        var path = Path()
        path.move(to: pt(0.5, 0.92))
        path.addCurve(to: pt(0.03, 0.40), control1: pt(0.22, 0.75), control2: pt(0.03, 0.58))
        path.addCurve(to: pt(0.28, 0.08), control1: pt(0.03, 0.20), control2: pt(0.13, 0.08))
        path.addCurve(to: pt(0.50, 0.24), control1: pt(0.40, 0.08), control2: pt(0.47, 0.15))
        path.addCurve(to: pt(0.72, 0.08), control1: pt(0.53, 0.15), control2: pt(0.60, 0.08))
        path.addCurve(to: pt(0.97, 0.40), control1: pt(0.87, 0.08), control2: pt(0.97, 0.20))
        path.addCurve(to: pt(0.5, 0.92), control1: pt(0.97, 0.58), control2: pt(0.78, 0.75))
        path.closeSubpath()
        return path
    }
}

/// 불꽃 (스트릭).
struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }
        var path = Path()
        path.move(to: pt(0.50, 0.03))
        path.addCurve(to: pt(0.87, 0.60), control1: pt(0.66, 0.20), control2: pt(0.87, 0.36))
        path.addCurve(to: pt(0.50, 0.97), control1: pt(0.87, 0.82), control2: pt(0.71, 0.97))
        path.addCurve(to: pt(0.13, 0.60), control1: pt(0.29, 0.97), control2: pt(0.13, 0.82))
        path.addCurve(to: pt(0.34, 0.30), control1: pt(0.13, 0.44), control2: pt(0.24, 0.37))
        path.addCurve(to: pt(0.50, 0.03), control1: pt(0.42, 0.23), control2: pt(0.47, 0.13))
        path.closeSubpath()
        return path
    }
}

/// 하트 균열 (하트 소진 상태용).
struct CrackShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }
        var path = Path()
        path.move(to: pt(0.50, 0.16))
        path.addLine(to: pt(0.41, 0.36))
        path.addLine(to: pt(0.56, 0.52))
        path.addLine(to: pt(0.44, 0.70))
        path.addLine(to: pt(0.50, 0.90))
        return path
    }
}

/// 4꼭지 반짝이 (장식용).
struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let cy = rect.midY
        var path = Path()
        path.move(to: CGPoint(x: cx, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: cy),
                          control: CGPoint(x: cx + w * 0.10, y: cy - h * 0.10))
        path.addQuadCurve(to: CGPoint(x: cx, y: rect.maxY),
                          control: CGPoint(x: cx + w * 0.10, y: cy + h * 0.10))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: cy),
                          control: CGPoint(x: cx - w * 0.10, y: cy + h * 0.10))
        path.addQuadCurve(to: CGPoint(x: cx, y: rect.minY),
                          control: CGPoint(x: cx - w * 0.10, y: cy - h * 0.10))
        path.closeSubpath()
        return path
    }
}

/// 재생 삼각형 (모서리 둥글게).
struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// 왕관 (최고 레벨 표시).
struct CrownShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }
        var path = Path()
        path.move(to: pt(0.12, 0.88))
        path.addLine(to: pt(0.05, 0.32))
        path.addLine(to: pt(0.30, 0.54))
        path.addLine(to: pt(0.50, 0.14))
        path.addLine(to: pt(0.70, 0.54))
        path.addLine(to: pt(0.95, 0.32))
        path.addLine(to: pt(0.88, 0.88))
        path.closeSubpath()
        return path
    }
}

// MARK: - 아이콘 뷰

/// 골드 그라디언트 별. filled=false면 빈 별. (테두리 라운드 조인으로 꼭지를 둥글게)
struct StarIcon: View {
    var filled = true
    var size: CGFloat = 16

    var body: some View {
        StarShape()
            .fill(filled ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Color(.systemFill)))
            .overlay(
                StarShape().stroke(
                    filled ? AnyShapeStyle(Theme.goldDeep.opacity(0.6)) : AnyShapeStyle(Theme.hairline),
                    style: StrokeStyle(lineWidth: max(1, size / 14), lineJoin: .round)
                )
            )
            .frame(width: size, height: size)
    }
}

/// 반짝이 아이콘 (장식).
struct SparkleIcon: View {
    var color: Color = Theme.gold
    var size: CGFloat = 14

    var body: some View {
        SparkleShape()
            .fill(color)
            .frame(width: size, height: size)
    }
}

/// 흰 원 안의 재생 버튼 (현재 레벨 카드).
struct PlayIcon: View {
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
            TriangleShape()
                .fill(Theme.brandGradient)
                .overlay(
                    TriangleShape().stroke(
                        Theme.brand,
                        style: StrokeStyle(lineWidth: size * 0.07, lineJoin: .round)
                    )
                )
                .frame(width: size * 0.34, height: size * 0.38)
                .offset(x: size * 0.04)
        }
        .frame(width: size, height: size)
    }
}

/// 자물쇠 (잠긴 레벨).
struct LockIcon: View {
    var size: CGFloat = 18
    var color = Color(.systemGray2)

    var body: some View {
        VStack(spacing: -size * 0.04) {
            // 고리
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.13, lineCap: .round))
                .rotationEffect(.degrees(180))
                .frame(width: size * 0.46, height: size * 0.46)
            // 몸통 + 열쇠 구멍
            RoundedRectangle(cornerRadius: size * 0.16)
                .fill(color)
                .frame(width: size * 0.74, height: size * 0.56)
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: size * 0.14, height: size * 0.14)
                )
        }
        .frame(width: size, height: size)
    }
}

/// 골드 왕관 (최고 레벨).
struct CrownIcon: View {
    var size: CGFloat = 14

    var body: some View {
        CrownShape()
            .fill(Theme.goldGradient)
            .overlay(
                CrownShape().stroke(
                    Theme.goldDeep.opacity(0.6),
                    style: StrokeStyle(lineWidth: max(1, size / 12), lineJoin: .round)
                )
            )
            .frame(width: size, height: size)
    }
}

/// 별 3개 평가 표시 (획득/미획득).
struct StarsRow: View {
    let earned: Int
    var size: CGFloat = 16
    var spacing: CGFloat = 3

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<3, id: \.self) { index in
                StarIcon(filled: index < earned, size: size)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(earned)/3 stars"))
    }
}

/// 레드 그라디언트 하트. filled=false면 빈 하트.
struct HeartIcon: View {
    var filled = true
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            HeartShape()
                .fill(filled ? AnyShapeStyle(Theme.heartGradient) : AnyShapeStyle(Color(.systemFill)))
            if filled {
                // 좌상단 하이라이트로 볼륨감
                Ellipse()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: size * 0.22, height: size * 0.14)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -size * 0.18, y: -size * 0.16)
            }
        }
        .frame(width: size, height: size)
    }
}

/// 금 간 하트 (하트 소진).
struct BrokenHeartIcon: View {
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            HeartShape()
                .fill(LinearGradient(colors: [Color(.systemGray3), Color(.systemGray)],
                                     startPoint: .top, endPoint: .bottom))
            CrackShape()
                .stroke(Color(.systemBackground),
                        style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

/// 오렌지 그라디언트 불꽃 (안쪽에 밝은 심지).
struct FlameIcon: View {
    var size: CGFloat = 16

    var body: some View {
        ZStack(alignment: .bottom) {
            FlameShape()
                .fill(Theme.flameGradient)
                .frame(width: size, height: size)
            FlameShape()
                .fill(Theme.goldGradient)
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(y: -size * 0.06)
        }
        .frame(width: size, height: size)
    }
}

/// 레벨 클리어 배지: 광선 + 컨페티 + 브랜드 원 + 흰 별.
struct ClearBadge: View {
    var size: CGFloat = 120

    private static let confetti: [(Color, CGFloat, CGFloat, CGFloat)] = [
        (Theme.heart, -0.42, -0.20, 0.07),
        (Theme.teal, 0.44, -0.26, 0.06),
        (Theme.gold, 0.36, 0.34, 0.055),
        (Theme.purple, -0.38, 0.30, 0.06),
        (Theme.flame, 0.05, -0.50, 0.05),
        (Theme.success, -0.15, 0.48, 0.05),
    ]

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(Theme.goldGradient)
                    .frame(width: size * 0.045, height: size * 0.14)
                    .offset(y: -size * 0.46)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            // 컨페티 점들
            ForEach(0..<Self.confetti.count, id: \.self) { index in
                let c = Self.confetti[index]
                Circle()
                    .fill(c.0)
                    .frame(width: size * c.3, height: size * c.3)
                    .offset(x: size * c.1, y: size * c.2)
            }
            Circle()
                .fill(Theme.brandGradient)
                .frame(width: size * 0.66, height: size * 0.66)
                .shadow(color: Theme.brand.opacity(0.35), radius: 12, y: 6)
            StarShape()
                .fill(Color.white)
                .frame(width: size * 0.36, height: size * 0.36)
            SparkleIcon(color: .white.opacity(0.9), size: size * 0.10)
                .offset(x: size * 0.16, y: -size * 0.16)
        }
        .frame(width: size, height: size)
    }
}

/// 아깝게 실패 배지: 과녁 + 빗나간 점.
struct MissBadge: View {
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color(.systemGray4), lineWidth: size * 0.045)
                .frame(width: size * 0.78, height: size * 0.78)
            Circle()
                .strokeBorder(Color(.systemGray3), lineWidth: size * 0.045)
                .frame(width: size * 0.5, height: size * 0.5)
            Circle()
                .fill(Theme.brandGradient)
                .frame(width: size * 0.16, height: size * 0.16)
            Circle()
                .fill(Theme.heartGradient)
                .frame(width: size * 0.13, height: size * 0.13)
                .offset(x: size * 0.34, y: -size * 0.30)
        }
        .frame(width: size, height: size)
    }
}

/// 설정 통계 행 아이콘 (iOS 설정 스타일: 그라디언트 사각 배지 + 흰 심볼).
struct StatBadge: View {
    let systemName: String
    let gradient: LinearGradient

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(RoundedRectangle(cornerRadius: 7).fill(gradient))
    }
}
