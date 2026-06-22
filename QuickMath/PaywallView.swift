import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let benefits: [(icon: String, text: String)] = [
        ("clock.arrow.circlepath", "Lifetime skip history and total avoided-spend insights by category"),
        ("bell.badge", "Custom cooldown rules by price tier and daily 'ready to decide' reminders"),
        ("calendar.badge.exclamationmark", "Annual 'impulse saved' recap and CSV export")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.qmCard)
                                .frame(width: 80, height: 80)
                            Image(systemName: "tag")
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(Color.qmAccent)
                        }
                        .padding(.top, 16)

                        VStack(spacing: 6) {
                            Text("Cooldown Pro")
                                .font(.largeTitle.weight(.bold))
                            Text("$0.99 / month. Auto-renews until you cancel.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // Benefits
                        VStack(spacing: 12) {
                            ForEach(benefits, id: \.text) { benefit in
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: benefit.icon)
                                        .font(.title3)
                                        .foregroundStyle(Color.qmAccent)
                                        .frame(width: 28, alignment: .center)
                                    Text(benefit.text)
                                        .font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                }
                            }
                        }
                        .qmCard()
                        .padding(.horizontal)

                        // Subscribe button
                        Button {
                            Task { await store.purchase() }
                        } label: {
                            if store.purchaseInFlight {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Unlock for \(store.displayPrice)/mo")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .prominentButton()
                        .disabled(store.purchaseInFlight)
                        .padding(.horizontal)

                        // Restore
                        Button("Restore Purchase") {
                            Task { await store.restore() }
                        }
                        .softButton()
                        .padding(.horizontal)

                        // Disclosure
                        Text("Subscription is \(store.displayPrice)/month, billed monthly. Auto-renews unless cancelled at least 24 hours before the end of the current period. Cancel anytime in your Apple ID subscription settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        HStack(spacing: 20) {
                            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                .font(.caption)
                                .foregroundStyle(Color.qmAccent)
                            Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/cooldown-site/privacy.html")!)
                                .font(.caption)
                                .foregroundStyle(Color.qmAccent)
                        }

                        Spacer(minLength: 32)
                    }
                }
            }
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .onChange(of: store.isPro) { _, newVal in
                if newVal { dismiss() }
            }
        }
    }
}
