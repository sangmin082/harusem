import SwiftUI
import HarusemKit
import StoreKit

/// 통계 + 스토어 + 데일리 리마인더 허브.
struct StatsView: View {
    var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("harusem.reminder.enabled") private var reminderEnabled = false
    @State private var reminderDenied = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statRow("🔥", "Current streak", model.currentStreak)
                    statRow("🏆", "Longest streak", model.records.longestStreak)
                    statRow("⭐️", "Total stars", model.records.totalStars)
                    statRow("💯", "Perfect days", model.records.perfectDayCount)
                    statRow("📅", "Days played", model.records.daysPlayed)
                }

                Section {
                    recentStrip
                        .listRowBackground(Color.clear)
                } header: {
                    Text("Last 14 days")
                }

                Section {
                    Toggle(isOn: $reminderEnabled) {
                        Text("Daily reminder")
                    }
                    .onChange(of: reminderEnabled) { _, enabled in
                        Task {
                            let ok = await ReminderService.setEnabled(enabled)
                            if enabled && !ok {
                                reminderEnabled = false
                                reminderDenied = true
                            }
                        }
                    }
                } footer: {
                    if reminderDenied {
                        Text("Allow notifications in Settings to enable reminders.")
                    } else {
                        Text("Get a nudge when new puzzles arrive.")
                    }
                }

                Section {
                    if model.store.products.isEmpty {
                        Text("Store is unavailable right now.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(model.store.products, id: \.id) { product in
                            productRow(product)
                        }
                    }
                    Button("Restore purchases") {
                        Task { await model.store.restore() }
                    }
                    .font(.footnote)
                } header: {
                    Text("Store")
                }
            }
            .navigationTitle(Text("Stats"))
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
            .task {
                if model.store.products.isEmpty {
                    await model.store.loadProducts()
                }
            }
        }
    }

    private func statRow(_ emoji: String, _ title: LocalizedStringKey, _ value: Int) -> some View {
        HStack {
            Text(verbatim: emoji)
            Text(title)
            Spacer()
            Text(verbatim: "\(value)")
                .monospacedDigit()
                .fontWeight(.semibold)
        }
    }

    /// 최근 14일 별점 히트맵 (하루 최대 15개 기준 농도).
    private var recentStrip: some View {
        HStack(spacing: 5) {
            ForEach(model.recentDays(14)) { day in
                RoundedRectangle(cornerRadius: 4)
                    .fill(cellColor(stars: day.stars))
                    .frame(height: 22)
                    .accessibilityLabel(Text(verbatim: "\(day.dateKey): \(day.stars ?? 0)"))
            }
        }
        .padding(.vertical, 4)
    }

    private func cellColor(stars: Int?) -> Color {
        guard let stars else { return Color(.systemFill) }
        let ratio = Double(stars) / 15.0
        return Color.yellow.opacity(0.2 + 0.8 * ratio)
    }

    @ViewBuilder
    private func productRow(_ product: Product) -> some View {
        let owned = model.store.purchasedIDs.contains(product.id)
        Button {
            Task { await model.store.purchase(product) }
        } label: {
            HStack {
                Text(verbatim: product.displayName)
                    .foregroundStyle(Color.primary)
                Spacer()
                if owned {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text(verbatim: product.displayPrice)
                        .fontWeight(.semibold)
                }
            }
        }
        .disabled(owned)
    }
}
