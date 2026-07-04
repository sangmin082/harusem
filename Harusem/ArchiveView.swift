import SwiftUI
import HarusemKit

/// 과거 날짜 퍼즐 목록. 최근 N일 무료, 그 이전은 아카이브 IAP 필요.
struct ArchiveView: View {
    var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.archiveDateKeys, id: \.self) { dateKey in
                    let locked = model.isArchiveLocked(dateKey)
                    Button {
                        if locked {
                            showPaywall = true
                        } else {
                            model.enterArchive(dateKey: dateKey)
                            dismiss()
                        }
                    } label: {
                        ArchiveRow(
                            dateKey: dateKey,
                            record: model.records.day(for: dateKey),
                            locked: locked
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(Text("Archive"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(store: model.store)
            }
        }
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
