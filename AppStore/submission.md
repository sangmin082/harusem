# 하루셈 App Store 심사 제출 가이드

버전 1.0.0 기준. 아래 내용을 App Store Connect(https://appstoreconnect.apple.com)에 그대로 붙여 넣으면 된다.

---

## 1. 앱 정보 (App Information)

| 항목 | 값 |
|---|---|
| 이름 (ko) | 하루셈 — 숫자 퍼즐 |
| 이름 (en) | Harusem — Number Puzzle |
| 부제 (ko) | 사칙연산으로 목표 숫자 만들기 |
| 부제 (en) | Hit the target with + − × ÷ |
| 번들 ID | com.harusem.app |
| 기본 언어 | 한국어 |
| 카테고리 | 게임 > 퍼즐 (보조: 게임 > 보드) |
| 콘텐츠 권리 | 제3자 콘텐츠 없음 |
| 연령 등급 | 모든 설문 "없음" → 4+ (⚠️ "키즈 카테고리"는 선택하지 말 것 — 광고 제약이 크다) |

## 2. 개인정보 (App Privacy)

- 개인정보처리방침 URL: `https://sangmin082.github.io/harusem/privacy.html`
- 데이터 수집 설문 (AdMob 때문에 아래와 같이 답한다):
  - **식별자 > 기기 ID**: 수집함 → 제3자 광고 목적 → 사용자에게 연결됨: 아니요 → 추적 목적 사용: **예**
  - **사용 데이터 > 광고 데이터**: 수집함 → 제3자 광고 목적 → 추적 목적 사용: **예**
  - **위치 > 대략적 위치**: 수집함 (IP 기반, AdMob) → 광고 목적 → 추적: 아니요
  - 그 외 항목: 수집 안 함
- 추적 여부 질문: **예, 추적함** (ATT 팝업 사용 중이므로 일치해야 함)

## 3. 가격 및 배포

- 가격: 무료
- 배포 지역: 전체 (또는 한국+미국부터 시작해도 됨)
- 인앱 구매: 아래 1종을 ASC > 수익화 > 인앱 구매에서 생성 후 **앱 버전과 함께 심사 제출**
  | 항목 | 값 |
  |---|---|
  | 유형 | 비소모성 (Non-Consumable) |
  | 제품 ID | `com.harusem.iap.removeads` |
  | 참조 이름 | Remove Ads |
  | 표시 이름 (ko) | 광고 제거 |
  | 설명 (ko) | 전면 광고를 영구히 제거합니다. |
  | 표시 이름 (en) | Remove Ads |
  | 설명 (en) | Permanently removes interstitial ads. |
  | 가격 | 티어 자유 (권장: ₩4,400 / $2.99) |
  - `com.harusem.iap.archive`는 현재 UI에 노출하지 않으므로 **생성하지 않는다**.

## 4. 설명 (Description)

### 한국어

```
하루 10분, 머리가 맑아지는 숫자 퍼즐 — 하루셈

숫자 타일 6개와 사칙연산(+, −, ×, ÷)만으로 목표 숫자를 만들어 보세요.
간단해 보이지만, 딱 맞는 조합을 찾는 순간의 쾌감이 대단합니다.

이렇게 플레이해요
• 두 타일과 연산자를 고르면 새 숫자 타일로 합쳐집니다
• 목표 숫자에 정확히 도달하면 별 3개! (±10 이내 별 2개, ±25 이내 별 1개)
• 별 1개 이상이면 클리어 — 다음 레벨이 열립니다

특징
• 레벨 방식: 레벨 1부터 차근차근, 갈수록 어려워지는 퍼즐
• 모두 같은 문제: 같은 레벨이면 전 세계 누구나 같은 퍼즐 — 친구와 별점을 겨뤄보세요
• 하트 시스템: 만점(별 3개)으로 깨면 하트를 잃지 않아요
• 되돌리기 무제한 + 힌트로 부담 없이 도전
• 오프라인에서도 언제나 플레이 가능
• 알록달록한 캔디 디자인과 다크 모드 지원

수학 문제가 아니라 퍼즐입니다. 암산이 약해도 괜찮아요 — 조합을 발견하는 재미가 전부니까요.
```

### English

```
A bite-size number puzzle that clears your head — Harusem

Combine six number tiles using +, −, × and ÷ to hit the target number.
Simple rules, deeply satisfying "aha!" moments.

How to play
• Pick two tiles and an operator to merge them into a new tile
• Hit the target exactly for 3 stars (within ±10: 2 stars, ±25: 1 star)
• Clear with at least one star to unlock the next level

Features
• Level-based: start from level 1, puzzles get gradually trickier
• Same puzzle for everyone: compare stars with friends on the same level
• Heart system: finish with a perfect 3 stars and you keep your hearts
• Unlimited undo and hints — challenge without stress
• Fully playable offline
• Colorful candy design with dark mode support

It's a puzzle, not a math test. No mental-math skills required — the joy is in discovering the combination.
```

## 5. 키워드 (100자 이내)

- ko: `숫자퍼즐,두뇌게임,수학게임,사칙연산,암산,퍼즐,계산게임,digits,브레인,숫자게임`
- en: `number,puzzle,math,digits,brain,logic,mental,arithmetic,daily,casual`

## 6. 지원 URL / 마케팅 URL

- 지원 URL: `https://sangmin082.github.io/harusem/`
- 마케팅 URL(선택): 동일

## 7. 스크린샷 (직접 촬영 필요)

- **필수: 6.9형 (1320×2868)** — 지금 쓰는 기기가 정확히 이 해상도라 기기 스크린샷 그대로 업로드 가능
- 권장 장면 5장: ① 홈 레벨 맵 ② 퍼즐 플레이(타일 선택 상태) ③ 클리어 화면(별 3개) ④ 레벨 목록 ⑤ 다크 모드 아무 화면
- 6.5형(1284×2778)은 6.9형에서 자동 스케일되므로 생략 가능

## 8. 심사 정보 (App Review Information)

- 연락처: 이름/전화/이메일 입력
- 메모(영문 권장):
```
This is a level-based number puzzle game. No account or login is required — all progress is stored locally.

Notes for review:
1. Ads: The app integrates Google AdMob. The ad units are newly created and may serve no ads (no-fill) until AdMob completes its review after the app is published. All ad entry points fail gracefully when no ad is available.
2. App Tracking Transparency: The ATT prompt appears on first launch after the app becomes active. If tracking is denied, non-personalized ads are requested.
3. In-app purchase: "Remove Ads" (com.harusem.iap.removeads) permanently removes interstitial ads. Restore is available in the Settings tab.
4. Hearts: players lose one heart when finishing a puzzle with fewer than 3 stars; hearts refill automatically every 10 minutes. Rewarded ads can refill hearts/hints — these are optional and user-initiated.
```

## 9. 버전 심사 제출 순서 (체크리스트)

1. [ ] GitHub Pages 배포 확인 → https://sangmin082.github.io/harusem/privacy.html 열리는지 (pages.yml 워크플로가 자동 배포; 안 열리면 저장소 Settings > Pages에서 Source를 "GitHub Actions"로 지정)
2. [ ] App Store Connect > 앱 > **버전 1.0.0** 생성 (iOS)
3. [ ] 위 4~6번 텍스트 입력 (한국어/영어 현지화 각각)
4. [ ] 스크린샷 업로드 (6.9형 최소 3장)
5. [ ] 빌드 선택: **빌드 27 이상** (이번 커밋의 빌드 — 실광고 유닛 + 버전 1.0.0. 이전 빌드는 0.1.0이라 선택 불가)
6. [ ] 인앱 구매 "광고 제거" 생성 후 버전에 첨부
7. [ ] App Privacy 설문 입력 (2번 참고) + 개인정보 URL 입력
8. [ ] 연령 등급 설문 (모두 "없음")
9. [ ] 수출 규정: "암호화 사용 안 함" (Info.plist에 ITSAppUsesNonExemptEncryption=false 이미 포함 — 질문 안 뜰 수 있음)
10. [ ] 심사 제출 🚀

## 10. 출시 후 할 일

- AdMob 콘솔 > 앱 > **App Store에 연결** (검색해서 연결) → 승인 "검토 필요" 해소
- 광고 게재 확인 (승인까지 보통 몇 시간~며칠, 그동안 노필 정상)
- 앱스토어 링크로 지원 페이지(docs/index.html)에 다운로드 버튼 추가
