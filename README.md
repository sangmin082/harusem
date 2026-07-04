# 하루셈 (harusem)

iOS 데일리 숫자 퍼즐 게임. 주어진 숫자 6개와 사칙연산으로 목표 숫자를 만든다.

## 구조

- `HarusemKit/` — 순수 Swift Package 게임 엔진 (PRNG, Solver, Generator, GameState). UI 의존성 없음
- `Harusem/` — SwiftUI 앱 타깃 소스
- `project.yml` — XcodeGen 프로젝트 정의 (`.xcodeproj`는 커밋하지 않음)

## 개발

```bash
# Xcode 프로젝트 생성
xcodegen generate

# 엔진 테스트
cd HarusemKit && swift test

# 특정 날짜의 퍼즐 5문제 + 해답 미리보기
cd HarusemKit && swift run harusem-gen 2026-07-04
```

자세한 규칙과 컨벤션은 [CLAUDE.md](CLAUDE.md) 참고.
