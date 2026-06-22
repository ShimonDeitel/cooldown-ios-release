import SwiftUI
import Charts

// MARK: - Insights View (Pro feature)
struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var showExportSheet = false
    @State private var exportText = ""

    private var monthlyData: [(month: String, amount: Double)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var grouped: [String: Double] = [:]
        for record in appModel.skipRecords {
            let key = formatter.string(from: record.date)
            grouped[key, default: 0] += record.amountSaved
        }
        return grouped.sorted { $0.key < $1.key }.map { (month: $0.key, amount: $0.value) }
    }

    private var csvString: String {
        var lines = ["Date,Item,Amount Saved"]
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        for record in appModel.skipRecords {
            lines.append("\(formatter.string(from: record.date)),\"\(record.itemTitle)\",\(String(format: "%.2f", record.amountSaved))")
        }
        return lines.joined(separator: "\n")
    }

    private var annualTotal: Double {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        return appModel.skipRecords
            .filter { calendar.component(.year, from: $0.date) == year }
            .reduce(0) { $0 + $1.amountSaved }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Top stats
                        HStack(spacing: 12) {
                            MetricTile(
                                value: appModel.formatCurrency(appModel.totalSaved),
                                label: "Total Saved"
                            )
                            MetricTile(
                                value: "\(appModel.skipRecords.count)",
                                label: "Items Skipped"
                            )
                            MetricTile(
                                value: appModel.formatCurrency(annualTotal),
                                label: "This Year"
                            )
                        }
                        .padding(.horizontal)

                        // Chart
                        if !monthlyData.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Avoided Spend by Month")
                                    .font(.headline)
                                    .padding(.horizontal, 4)

                                Chart(monthlyData, id: \.month) { entry in
                                    BarMark(
                                        x: .value("Month", entry.month),
                                        y: .value("Saved", entry.amount)
                                    )
                                    .foregroundStyle(Color.qmAccent)
                                    .cornerRadius(6)
                                }
                                .frame(height: 180)
                                .chartYAxis {
                                    AxisMarks(position: .leading)
                                }
                            }
                            .qmCard()
                            .padding(.horizontal)
                        }

                        // Skip history
                        if !appModel.skipRecords.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Skip History")
                                    .font(.headline)
                                    .padding(.horizontal, 4)

                                ForEach(appModel.skipRecords.prefix(50)) { record in
                                    SkipRecordRow(record: record, formatter: appModel.formatCurrency)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar")
                                    .font(.system(size: 40, weight: .thin))
                                    .foregroundStyle(.secondary)
                                Text("No skips yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("When you skip a temptation, your savings appear here.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .padding(.top, 40)
                        }

                        // Export
                        Button {
                            exportText = csvString
                            showExportSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export CSV")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .softButton()
                        .padding(.horizontal)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSheet(csvText: exportText)
            }
        }
    }
}

// MARK: - Supporting views

struct SkipRecordRow: View {
    let record: SkipRecord
    let formatter: (Double) -> String

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: record.date)
    }

    var body: some View {
        HStack {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Color.qmCorrect)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.itemTitle)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatter(record.amountSaved))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.qmCorrect)
        }
        .qmCard()
    }
}

struct ExportSheet: View {
    let csvText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(csvText)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: csvText, subject: Text("Cooldown Savings"), message: Text("My avoided-spend history")) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundStyle(Color.qmAccent)
                }
            }
        }
    }
}
