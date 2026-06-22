import SwiftUI
import SwiftData

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showAdd = false
    @State private var showPaywall = false
    @State private var showInsights = false
    @State private var showDecide: WishItem? = nil

    private var readyItems: [WishItem] {
        appModel.waitingItems.filter { $0.isReady }
    }

    private var pendingItems: [WishItem] {
        appModel.waitingItems.filter { !$0.isReady }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary tiles
                        HStack(spacing: 12) {
                            MetricTile(
                                value: appModel.formatCurrency(appModel.totalSaved),
                                label: "Not Spent"
                            )
                            MetricTile(
                                value: "\(appModel.waitingItems.count)",
                                label: "On Cooldown"
                            )
                            MetricTile(
                                value: "\(appModel.skipRecords.count)",
                                label: "Skipped"
                            )
                        }
                        .padding(.horizontal)

                        // Pro / Insights tile
                        Button {
                            if store.isPro { showInsights = true }
                            else { showPaywall = true }
                        } label: {
                            HStack {
                                Image(systemName: store.isPro ? "chart.bar.fill" : "lock.fill")
                                    .foregroundStyle(Color.qmAccent)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.isPro ? "Insights" : "Cooldown Pro")
                                        .font(.headline)
                                    Text(store.isPro ? "History & avoided-spend breakdown" : "Unlock history, reminders & export")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .qmCard()
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        // Ready to decide
                        if !readyItems.isEmpty {
                            SectionHeader(title: "Ready to Decide", count: readyItems.count)
                            ForEach(readyItems) { item in
                                WishItemRow(item: item, onDecide: { showDecide = item }, onDelete: { appModel.deleteItem(item) })
                            }
                        }

                        // Waiting
                        if !pendingItems.isEmpty {
                            SectionHeader(title: "Cooling Down", count: pendingItems.count)
                            ForEach(pendingItems) { item in
                                WishItemRow(item: item, onDecide: nil, onDelete: { appModel.deleteItem(item) })
                            }
                        }

                        if appModel.waitingItems.isEmpty {
                            EmptyStateView(onAdd: { showAdd = true })
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Cooldown")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.qmAccent)
                            .font(.title3.weight(.semibold))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
                    .environmentObject(appModel)
            }
            .sheet(isPresented: $showAdd) {
                AddItemView()
                    .environmentObject(appModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showInsights) {
                InsightsView()
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .sheet(item: $showDecide) { item in
                DecideView(item: item)
                    .environmentObject(appModel)
            }
        }
        .onAppear {
            if let screen = forceScreen {
                switch screen {
                case "paywall": showPaywall = true
                case "settings": showSettings = true
                case "add": showAdd = true
                default: break
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let count: Int
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}

struct WishItemRow: View {
    let item: WishItem
    let onDecide: (() -> Void)?
    let onDelete: () -> Void

    @EnvironmentObject var appModel: AppModel

    private var currencyString: String {
        appModel.formatCurrency(item.price)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(currencyString)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.qmAccent)
                }
                Spacer()
                if item.isReady {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.qmCorrect)
                        .font(.title3)
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(item.daysRemaining)d")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                        Text("left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.qmField)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(item.isReady ? Color.qmCorrect : Color.qmAccent)
                        .frame(width: geo.size.width * item.progressFraction, height: 6)
                }
            }
            .frame(height: 6)

            if item.isReady, let onDecide = onDecide {
                Button(action: onDecide) {
                    Text("Decide Now")
                        .frame(maxWidth: .infinity)
                }
                .prominentButton()
            }
        }
        .qmCard()
        .padding(.horizontal)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct EmptyStateView: View {
    let onAdd: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.qmAccent)
            Text("Nothing on cooldown")
                .font(.title3.weight(.semibold))
            Text("Add a tempting purchase and let it sit before you decide.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Add Your First Item", action: onAdd)
                .prominentButton()
        }
        .padding(.top, 60)
    }
}
