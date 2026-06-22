import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    private var theme: AppTheme {
        get { AppTheme(rawValue: themeRaw) ?? .system }
        set { themeRaw = newValue.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                List {
                    // Pro status
                    Section("Subscription") {
                        if store.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.qmAccent)
                                Text("Cooldown Pro Active")
                                    .font(.subheadline.weight(.semibold))
                            }
                            Link("Manage Subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                                .foregroundStyle(Color.qmAccent)
                        } else {
                            Button("Upgrade to Cooldown Pro") { showPaywall = true }
                                .foregroundStyle(Color.qmAccent)
                        }
                        Button("Restore Purchases") {
                            Task { await store.restore() }
                        }
                        .foregroundStyle(Color.qmAccent)
                    }

                    // Default cooldown
                    Section("Defaults") {
                        Stepper("Default Cooldown: \(appModel.defaultCooldownDays) days",
                                value: Binding(
                                    get: { appModel.defaultCooldownDays },
                                    set: { appModel.updateDefaultCooldown($0) }
                                ),
                                in: 1...90)
                    }

                    // Appearance
                    Section("Appearance") {
                        Picker("Theme", selection: $themeRaw) {
                            ForEach(AppTheme.allCases) { t in
                                Text(t.label).tag(t.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Legal
                    Section("Legal") {
                        Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/cooldown-site/privacy.html")!)
                            .foregroundStyle(Color.qmAccent)
                        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .foregroundStyle(Color.qmAccent)
                    }

                    // Data
                    Section("Data") {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .confirmationDialog(
                "Delete All Data",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    appModel.deleteAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your wish items, skip history, and settings. This cannot be undone.")
            }
        }
    }
}
