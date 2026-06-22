import SwiftUI
import SwiftData

// MARK: - Decision enum
enum ItemDecision: String, Codable {
    case waiting
    case bought
    case skipped
}

// MARK: - SwiftData Models

@Model
final class WishItem {
    var id: UUID
    var title: String
    var price: Double
    var addedDate: Date
    var cooldownDays: Int
    var decision: String  // ItemDecision.rawValue
    var decidedDate: Date?
    var note: String

    init(title: String, price: Double, cooldownDays: Int = 7, note: String = "") {
        self.id = UUID()
        self.title = title
        self.price = price
        self.addedDate = Date()
        self.cooldownDays = cooldownDays
        self.decision = ItemDecision.waiting.rawValue
        self.decidedDate = nil
        self.note = note
    }

    var itemDecision: ItemDecision {
        get { ItemDecision(rawValue: decision) ?? .waiting }
        set { decision = newValue.rawValue }
    }

    var cooldownEndsAt: Date {
        Calendar.current.date(byAdding: .day, value: cooldownDays, to: addedDate) ?? addedDate
    }

    var isReady: Bool {
        Date() >= cooldownEndsAt
    }

    var daysRemaining: Int {
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: cooldownEndsAt).day ?? 0
        return max(0, diff)
    }

    var progressFraction: Double {
        let total = Double(cooldownDays) * 86400
        let elapsed = Date().timeIntervalSince(addedDate)
        return min(1.0, max(0.0, elapsed / total))
    }
}

@Model
final class SkipRecord {
    var id: UUID
    var itemTitle: String
    var amountSaved: Double
    var date: Date

    init(itemTitle: String, amountSaved: Double, date: Date = Date()) {
        self.id = UUID()
        self.itemTitle = itemTitle
        self.amountSaved = amountSaved
        self.date = date
    }
}

@Model
final class CooldownSettings {
    var id: UUID
    var defaultCooldownDays: Int

    init(defaultCooldownDays: Int = 7) {
        self.id = UUID()
        self.defaultCooldownDays = defaultCooldownDays
    }
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var waitingItems: [WishItem] = []
    @Published private(set) var decidedItems: [WishItem] = []
    @Published private(set) var skipRecords: [SkipRecord] = []
    @Published private(set) var totalSaved: Double = 0
    @Published private(set) var defaultCooldownDays: Int = 7

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([WishItem.self, SkipRecord.self, CooldownSettings.self])
        do {
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
        } catch {
            let cfg = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [cfg])) ?? {
                fatalError("Cannot create ModelContainer: \(error)")
            }()
        }
    }

    func reload() {
        let ctx = container.mainContext
        let allItems = (try? ctx.fetch(FetchDescriptor<WishItem>(sortBy: [SortDescriptor(\.addedDate, order: .reverse)]))) ?? []
        waitingItems = allItems.filter { $0.itemDecision == .waiting }
        decidedItems = allItems.filter { $0.itemDecision != .waiting }

        let records = (try? ctx.fetch(FetchDescriptor<SkipRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
        skipRecords = records
        totalSaved = records.reduce(0) { $0 + $1.amountSaved }

        let settings = (try? ctx.fetch(FetchDescriptor<CooldownSettings>())) ?? []
        if let s = settings.first {
            defaultCooldownDays = s.defaultCooldownDays
        }
    }

    func refresh() { reload() }

    func addItem(title: String, price: Double, cooldownDays: Int, note: String = "") {
        let item = WishItem(title: title, price: price, cooldownDays: cooldownDays, note: note)
        container.mainContext.insert(item)
        try? container.mainContext.save()
        Haptics.success()
        reload()
    }

    func decide(_ item: WishItem, decision: ItemDecision) {
        item.itemDecision = decision
        item.decidedDate = Date()
        if decision == .skipped {
            let record = SkipRecord(itemTitle: item.title, amountSaved: item.price)
            container.mainContext.insert(record)
            Haptics.success()
        } else {
            Haptics.tap()
        }
        try? container.mainContext.save()
        reload()
    }

    func deleteItem(_ item: WishItem) {
        container.mainContext.delete(item)
        try? container.mainContext.save()
        reload()
    }

    func updateDefaultCooldown(_ days: Int) {
        let ctx = container.mainContext
        let settings = (try? ctx.fetch(FetchDescriptor<CooldownSettings>())) ?? []
        if let s = settings.first {
            s.defaultCooldownDays = days
        } else {
            ctx.insert(CooldownSettings(defaultCooldownDays: days))
        }
        try? ctx.save()
        reload()
    }

    func deleteAllData() {
        let ctx = container.mainContext
        let items = (try? ctx.fetch(FetchDescriptor<WishItem>())) ?? []
        for i in items { ctx.delete(i) }
        let records = (try? ctx.fetch(FetchDescriptor<SkipRecord>())) ?? []
        for r in records { ctx.delete(r) }
        try? ctx.save()
        reload()
    }

    // Formatting helpers
    func formatCurrency(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }
}
