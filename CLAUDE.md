# 하루셈 (harusem)

iOS 숫자 퍼즐 게임. NYT Digits 스타일: 주어진 숫자 6개와 사칙연산으로 목표 숫자를 만든다.
레벨(단계) 진행 방식: 레벨 1부터 한 문제씩 클리어하며 올라간다.

## 제품 원칙
- 서버 없음. 레벨 번호 기반 시드로 모든 유저가 같은 레벨에서 같은 퍼즐을 받는다 (오프라인 동작 필수)
- 레벨당 1문제. 별 1개 이상이면 클리어 → 다음 레벨 해금. 난이도는 3레벨마다 상승, 13레벨부터 최고 프로필
- 하트 경제: 최대 10개, 10분마다 1개 자동 충전. 문제를 별 3개 만점 없이 끝내면 1개 차감. 리워드 광고로 1개 충전
- 수익화: 전면 광고(3레벨 클리어마다 1회) + 리워드 광고(힌트/하트 충전) + 광고제거 IAP — 구현 완료. AdMob 유닛 ID는 AdsService.swift (릴리스 임시 테스트 광고: useTestAds 플래그)
- 한국어/영어 동시 지원 (String Catalog 사용)

## 게임 규칙
- 숫자 타일 6개, 연산자 +, -, ×, ÷
- 두 타일과 연산자를 선택하면 결과가 새 타일로 합쳐진다 (타일 수가 하나씩 줄어듦)
- 중간 결과는 항상 양의 정수여야 한다 (음수/분수가 되는 연산은 UI에서 차단)
- 목표 숫자에 정확히 도달하면 별 3개. 오차 ±10 이내 별 2개, ±25 이내 별 1개. 별 0개면 클리어 실패(재도전)
- undo 무제한, 처음부터 다시하기 가능. 힌트는 하루 3개 + 광고 충전
- 레벨당 하루 3회 플레이 (이어하기는 미소모). 소진 시 리워드 광고로 1회 추가

## 기술 스택
- Swift 5.10+, SwiftUI, iOS 17+, 외부 의존성 최소화
- 구조: HarusemKit (순수 Swift Package, 게임 엔진) + Harusem (앱 타깃)
- 엔진은 UI를 전혀 모른다. Foundation 외 import 금지
- Xcode 프로젝트는 XcodeGen(project.yml)으로 생성. .xcodeproj는 커밋하지 않는다
- 테스트: 엔진은 Swift Testing으로 커버리지 확보. 빌드 검증은 `xcodebuild -scheme Harusem -destination 'platform=iOS Simulator,name=iPhone 16' build test`

## 결정적(deterministic) 퍼즐 생성 — 가장 중요한 불변 조건
- 시드 = "harusem/v{version}/level/{레벨}/{round}"의 FNV-1a 해시 → SplitMix64 등 직접 구현한 PRNG 사용
- Swift의 SystemRandomNumberGenerator나 Hasher는 실행마다 달라지므로 절대 사용 금지
- 같은 레벨 번호 → 항상 같은 문제. 이 성질을 검증하는 테스트를 반드시 유지한다
- 생성 알고리즘이 바뀌면 기존 레벨의 퍼즐이 바뀌므로, 생성기는 버전 필드를 가진다
- 날짜 기반 데일리/보너스 생성기(puzzles(for:), bonusPuzzle)는 엔진에 유지 (테스트 포함) — 앱은 현재 레벨 모드만 사용

## 코드 컨벤션
- 커밋은 conventional commits (feat:, fix:, test:, chore:)
- 마일스톤 단위로 작업하고, 각 마일스톤 완료 시 테스트 전체 통과 확인 후 커밋
- 과도한 추상화 금지. 프로토콜은 실제 두 번째 구현이 생길 때만 도입
