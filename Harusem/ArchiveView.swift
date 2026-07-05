import SwiftUI
import HarusemKit

/// 캘린더 탭: 오늘 + 과거 날짜 퍼즐 목록/플레이. 최근 N일 무료, 그 이전은 아카이브 IAP.
/// 하트가 없으면 아직 만점이 아닌 날짜는 새로 시작할 수 없다 (하트 시트로 안내).
/// 날짜를 고르면 홈 탭으로 전환되어 플레이가 시작된다.
struct CalendarTab: View {
    var model: AppModel
    var goHome: () -> Void
    @State private var showPaywall = false
    @State private var showHearts = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if model.isArchivePlay { model.exitArchive() }
                        if model.isBonusPlay { model.exitBonus() }
                        goHome()
                    } label: {
                        HStack {
                            Text("Today")
                                .fontWeight(.semibold)
                            Spacer()
                            if let record = model.records.day(for: todayKey) {
                                Text(verbatim: "★ \(record.totalStars)/15")
                                    .font(.subheadline)
                                    .foregroundStyle(.yellow)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Section {
                    ForEach(model.archiveDateKeys, id: \.self) { dateKey in
                        let locked = model.isArchiveLocked(dateKey)
                        let record = model.records.day(for: dateKey)
                        Button {
                            if locked {
                                showPaywall = true
                            } else if model.hearts == 0 && (record?.totalStars ?? 0) < 15 {
                                // 만점이 아닌 날짜의 새 도전은 하트가 필요하다
                                showHearts = true
                            } else {
                                model.enterArchive(dateKey: dateKey)
                                goHome()
                            }
                        } label: {
                            ArchiveRow(dateKey: dateKey, record: record, locked: locked)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(Text("Calendar"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                PaywallView(store: model.store)
            }
            .sheet(isPresented: $showHearts) {
                HeartsView(model: model)
            }
        }
    }

    private var todayKey: String {
        PuzzleGenerator.dateKey(for: .now)
    }
}

private struct ArchiveRow: View {
    let dateKey: String
    let record: DayRecord?
    let locked: Bool

    var body: some View {
        HStack {
            Text(verbatim: dateKey)
                .monospacedDigit()
            Spacer()
            if let record {
                Text(verbatim: "★ \(record.totalStars)/15")
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
            }
            if locked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
        .opacity(locked ? 0.55 : 1)
    }
}
