import SwiftUI

// MARK: - Add Item View (primary entry screen)
struct AddItemView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var priceText = ""
    @State private var cooldownDays: Int = 7
    @State private var note = ""
    @State private var showValidation = false

    private let cooldownOptions = [1, 3, 7, 14, 21, 30]

    private var priceValue: Double? {
        let cleaned = priceText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        return Double(cleaned)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (priceValue ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.qmCard)
                                .frame(width: 72, height: 72)
                            Image(systemName: "tag")
                                .font(.system(size: 30, weight: .light))
                                .foregroundStyle(Color.qmAccent)
                        }
                        .padding(.top, 8)

                        Text("What are you tempted to buy?")
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Title field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Item")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            TextField("e.g. New headphones", text: $title)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(Color.qmField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal)

                        // Price field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Price")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            HStack {
                                Text("$")
                                    .foregroundStyle(.secondary)
                                    .font(.headline)
                                TextField("0.00", text: $priceText)
                                    .textFieldStyle(.plain)
                                    .keyboardType(.decimalPad)
                                    .font(.headline)
                            }
                            .padding(14)
                            .background(Color.qmField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal)

                        // Cooldown picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Cooldown Period")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                                ForEach(cooldownOptions, id: \.self) { days in
                                    Button {
                                        cooldownDays = days
                                        Haptics.tap()
                                    } label: {
                                        VStack(spacing: 2) {
                                            Text("\(days)")
                                                .font(.title3.weight(.bold))
                                            Text(days == 1 ? "day" : "days")
                                                .font(.caption2)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            cooldownDays == days ? Color.qmAccent : Color.qmCard,
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        )
                                        .foregroundStyle(cooldownDays == days ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.easeOut(duration: 0.15), value: cooldownDays)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Note field (optional)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Note (optional)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            TextField("Why do you want this?", text: $note, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(3, reservesSpace: true)
                                .padding(14)
                                .background(Color.qmField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal)

                        if showValidation && !isValid {
                            Text("Enter an item name and price to continue.")
                                .font(.caption)
                                .foregroundStyle(Color.qmWrong)
                                .padding(.horizontal)
                        }

                        // Cooldown summary
                        if let price = priceValue, !title.isEmpty {
                            CooldownSummaryBanner(title: title, price: price, days: cooldownDays, formatter: appModel.formatCurrency)
                        }

                        Button {
                            if isValid {
                                appModel.addItem(
                                    title: title.trimmingCharacters(in: .whitespaces),
                                    price: priceValue ?? 0,
                                    cooldownDays: cooldownDays,
                                    note: note.trimmingCharacters(in: .whitespaces)
                                )
                                dismiss()
                            } else {
                                showValidation = true
                                Haptics.warning()
                            }
                        } label: {
                            Text("Start Cooldown")
                                .frame(maxWidth: .infinity)
                        }
                        .prominentButton()
                        .padding(.horizontal)
                        .padding(.top, 4)

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .onAppear {
                cooldownDays = appModel.defaultCooldownDays
            }
        }
    }
}

// MARK: - Decide View (shown when cooldown ends)
struct DecideView: View {
    let item: WishItem
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 28) {
                    Spacer()

                    // Tag icon
                    ZStack {
                        Circle()
                            .fill(Color.qmCard)
                            .frame(width: 80, height: 80)
                        Image(systemName: "tag.fill")
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(Color.qmAccent)
                    }

                    VStack(spacing: 8) {
                        Text("Cooldown Complete")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)

                        Text(item.title)
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)

                        Text(appModel.formatCurrency(item.price))
                            .font(.title.weight(.heavy))
                            .foregroundStyle(Color.qmAccent)
                    }
                    .padding(.horizontal, 24)

                    if !item.note.isEmpty {
                        Text("Your note: \"\(item.note)\"")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .qmCard()
                            .padding(.horizontal)
                    }

                    Text("After \(item.cooldownDays) days, do you still want it?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    VStack(spacing: 12) {
                        Button {
                            appModel.decide(item, decision: .skipped)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Skip It — Save \(appModel.formatCurrency(item.price))")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .prominentButton()
                        .padding(.horizontal)

                        Button {
                            appModel.decide(item, decision: .bought)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "cart")
                                Text("Buy It")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .softButton()
                        .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Decision Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
    }
}

// MARK: - Cooldown Summary Banner
struct CooldownSummaryBanner: View {
    let title: String
    let price: Double
    let days: Int
    let formatter: (Double) -> String

    private var decideDate: Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: decideDate)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock")
                .foregroundStyle(Color.qmAccent)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("You'll decide on \(formattedDate)")
                    .font(.subheadline.weight(.medium))
                Text("Could save \(formatter(price)) if you skip")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .qmCard()
        .padding(.horizontal)
    }
}
