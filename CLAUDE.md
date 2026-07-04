# 하루셈 (harusem)

iOS 데일리 숫자 퍼즐 게임. NYT Digits 스타일: 주어진 숫자 6개와 사칙연산으로 목표 숫자를 만든다.

## 제품 원칙
- 서버 없음. 날짜 기반 시드로 전 세계 유저가 같은 날 같은 퍼즐을 받는다 (오프라인 동작 필수)
- 하루 5문제, 난이도 상승 구조. 플레이 타임 3~5분
- 수익화: 전면 광고(5문제 완료 후 1회) + 리워드 광고(힌트) + 광고제거/아카이브 IAP — 단, 마일스톤 4 전까지 구현하지 않는다
- 한국어/영어 동시 지원 (String Catalog 사용)

## 게임 규칙
- 숫자 타일 6개, 연산자 +, -, ×, ÷
- 두 타일과 연산자를 선택하면 결과가 새 타일로 합쳐진다 (타일 수가 하나씩 줄어듦)
- 중간 결과는 항상 양의 정수여야 한다 (음수/분수가 되는 연산은 UI에서 차단)
- 목표 숫자에 정확히 도달하면 별 3개. 오차 ±10 이내 별 2개, ±25 이내 별 1개
- undo 무제한, 처음부터 다시하기 가능

## 기술 스택
- Swift 5.10+, SwiftUI, iOS 17+, 외부 의존성 최소화
- 구조: HarusemKit (순수 Swift Package, 게임 엔진) + Harusem (앱 타깃)
- 엔진은 UI를 전혀 모른다. Foundation 외 import 금지
- Xcode 프로젝트는 XcodeGen(project.yml)으로 생성. .xcodeproj는 커밋하지 않는다
- 테스트: 엔진은 Swift Testing으로 커버리지 확보. 빌드 검증은 `xcodebuild -scheme Harusem -destination 'platform=iOS Simulator,name=iPhone 16' build test`

## 결정적(deterministic) 퍼즐 생성 — 가장 중요한 불변 조건
- 시드 = "YYYY-MM-DD" (KST 아닌 유저 로컬 날짜) → SplitMix64 등 직접 구현한 PRNG 사용
- Swift의 SystemRandomNumberGenerator나 Hasher는 실행마다 달라지므로 절대 사용 금지
- 같은 날짜 입력 → 항상 같은 5문제. 이 성질을 검증하는 테스트를 반드시 유지한다
- 생성 알고리즘이 바뀌면 과거 날짜의 퍼즐이 바뀌므로, 생성기는 버전 필드를 가진다

## 코드 컨벤션
- 커밋은 conventional commits (feat:, fix:, test:, chore:)
- 마일스톤 단위로 작업하고, 각 마일스톤 완료 시 테스트 전체 통과 확인 후 커밋
- 과도한 추상화 금지. 프로토콜은 실제 두 번째 구현이 생길 때만 도입
