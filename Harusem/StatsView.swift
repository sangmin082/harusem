import SwiftUI
import HarusemKit
import StoreKit

/// 설정 탭: 통계 + 데일리 리마인더 + 스토어 + 게임 방법.
struct StatsView: View {
    var model: AppModel
    @AppStorage("harusem.reminder.enabled") private var reminderEnabled = false
    @State private var reminderDenied = false
    @State private var showHelp = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statRow("crown.fill", Theme.goldGradient, "Highest level", model.maxLevel)
                    statRow("checkmark.seal.fill", greenGradient, "Levels cleared", model.levelsCleared)
                    statRow("star.fill", Theme.goldGradient, "Total stars", model.totalStarsEarned)
                    statRow("sparkles", Theme.brandGradient, "Perfect levels", model.perfectLevels)
                    statRow("flame.fill", Theme.flameGradient, "Current streak", model.currentStreak)
                    statRow("calendar", blueGradient, "Days played", model.daysPlayed)
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
                        Text("Get a daily nudge to keep your streak.")
                    }
                }

                Section {
                    let products = model.store.products.filter { $0.id == StoreService.removeAdsID }
                    if products.isEmpty {
                        Text("Store is unavailable right now.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(products, id: \.id) { product in
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

                Section {
                    Button {
                        showHelp = true
                    } label: {
                        HStack {
                            Text("How to play")
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showHelp) { HelpView() }
            .task {
                if model.store.products.isEmpty {
                    await model.store.loadProducts()
                }
            }
        }
    }

    private var greenGradient: LinearGradient {
        LinearGradient(colors: [Theme.success, Theme.success.opacity(0.75)],
                       startPoint: .top, endPoint: .bottom)
    }

    private var blueGradient: LinearGradient {
        LinearGradient(colors: [Color(.systemBlue), Color(.systemTeal)],
                       startPoint: .top, endPoint: .bottom)
    }

    private func statRow(_ symbol: String, _ gradient: LinearGradient,
                         _ title: LocalizedStringKey, _ value: Int) -> some View {
        HStack(spacing: 12) {
            StatBadge(systemName: symbol, gradient: gradient)
            Text(title)
            Spacer()
            Text(verbatim: "\(value)")
                .monospacedDigit()
                .fontWeight(.semibold)
        }
    }

    /// 최근 14일 클리어 히트맵 (하루 5레벨 기준 농도).
    private var recentStrip: some View {
        HStack(spacing: 5) {
            ForEach(model.recentDays(14)) { day in
                RoundedRectangle(cornerRadius: 4)
                    .fill(cellColor(cleared: day.cleared))
                    .frame(height: 22)
                    .accessibilityLabel(Text(verbatim: "\(day.dateKey): \(day.cleared ?? 0)"))
            }
        }
        .padding(.vertical, 4)
    }

    private func cellColor(cleared: Int?) -> Color {
        guard let cleared else { return Color(.systemFill) }
        let ratio = min(1, Double(cleared) / 5.0)
        return Theme.gold.opacity(0.25 + 0.75 * ratio)
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
