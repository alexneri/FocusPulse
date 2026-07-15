import SwiftUI
import StoreKit

struct ProFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
}

/// The upsell sheet (Story 6.2). Prices come from `StoreManager.products` (never hardcoded).
struct PaywallView: View {
    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false

    private let features: [ProFeature] = [
        ProFeature(icon: "infinity", title: "Unlimited history & export"),
        ProFeature(icon: "music.note", title: "Apple Music automation"),
        ProFeature(icon: "icloud", title: "iCloud sync"),
        ProFeature(icon: "chart.bar.xaxis", title: "Advanced statistics & heatmap"),
        ProFeature(icon: "paintpalette", title: "Curated & custom themes"),
        ProFeature(icon: "app.badge", title: "Alternative app icons")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.orange)
                    Text("Unlock FocusPulse Pro")
                        .font(.title).fontWeight(.bold)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(features) { feature in
                            Label(feature.title, systemImage: feature.icon)
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    productButtons

                    Button("Restore Purchases") {
                        Task { await store.restore(); if store.isPro { dismiss() } }
                    }
                    .font(.subheadline)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder private var productButtons: some View {
        if store.products.isEmpty {
            if store.loadFailed {
                Text("Could not load products.").foregroundStyle(.secondary)
                Button("Retry") { Task { await store.loadProducts() } }
            } else {
                ProgressView()
            }
        } else {
            ForEach(store.products, id: \.id) { product in
                Button {
                    purchasing = true
                    Task {
                        let unlocked = await store.purchase(product)
                        purchasing = false
                        if unlocked { dismiss() }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.displayName).fontWeight(.semibold)
                            if product.id == StoreManager.yearlyID {
                                Text("7-day free trial").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(product.displayPrice).fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(purchasing)
            }
        }
    }
}
