import SwiftUI
import StoreKit

/// IAP 페이월: 아카이브 잠금 해제 + 광고 제거.
struct PaywallView: View {
    var store: StoreService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text(verbatim: "🗓️")
                .font(.system(size: 56))
                .padding(.top, 24)
            Text("Unlock the full archive")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Free for the last \(AppModel.freeArchiveDays) days")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if store.products.isEmpty {
                if store.isLoading {
                    ProgressView()
                        .padding(.vertical, 24)
                } else {
                    Text("Store is unavailable right now.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 24)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(store.products, id: \.id) { product in
                        productButton(product)
                    }
                }
                .padding(.top, 8)
            }

            Button("Restore purchases") {
                Task { await store.restore() }
            }
            .font(.footnote)

            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
            }
        }
        .onChange(of: store.ownsArchive) { _, owned in
            if owned { dismiss() }
        }
    }

    @ViewBuilder
    private func productButton(_ product: Product) -> some View {
        let owned = store.purchasedIDs.contains(product.id)
        Button {
            Task { await store.purchase(product) }
        } label: {
            HStack {
                Text(verbatim: product.displayName)
                Spacer()
                if owned {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text(verbatim: product.displayPrice)
                        .fontWeight(.semibold)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        }
        .buttonStyle(.plain)
        .disabled(owned)
    }
}
