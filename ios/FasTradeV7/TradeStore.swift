import Foundation
import SwiftUI

struct TradeOperation: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date()
    var match: String = ""
    var sport: String = "Calcio"
    var marketType: String = "Over/Under 1.5"
    var strategy: String = "LTD"
    var minute: String = ""
    var tranche: String = ""
    var stakePct: Double = 2.0
    var stakeEur: Double = 0
    var odds: Double = 0
    var result: Double = 0
    var rating: String = ""
    var notes: String = ""
}

struct TradingStrategy: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var description: String = ""
    var defaultStakePct: Double = 0
    var active: Bool = true
    var custom: Bool = false
}

@MainActor
final class TradeStore: ObservableObject {
    @Published var operations: [TradeOperation] = [] { didSet { saveOperations() } }
    @Published var strategies: [TradingStrategy] = [] { didSet { saveStrategies() } }
    @Published var startingBank: Double = 0 { didSet { UserDefaults.standard.set(startingBank, forKey: "startingBank") } }

    let sports = ["Calcio", "Tennis", "Basket", "Altro"]
    let markets = ["Over/Under 0.5", "Over/Under 1.5", "Over/Under 2.5", "Over/Under 3.5", "BTTS", "1X2", "Risultato esatto", "Lay the Draw", "Banca risultato esatto", "Altro"]

    private let operationsKey = "fastrade_v7_operations"
    private let strategiesKey = "fastrade_v7_strategies"

    init() {
        startingBank = UserDefaults.standard.double(forKey: "startingBank")
        loadOperations()
        loadStrategies()
        if strategies.isEmpty { strategies = Self.defaultStrategies }
    }

    static let defaultStrategies: [TradingStrategy] = [
        .init(name: "LTD"), .init(name: "SPLIT UNDER"), .init(name: "SPLIT OVER LINEA 1"),
        .init(name: "SPLIT OVER LINEA 2"), .init(name: "BANCA 1"), .init(name: "BANCA 2"),
        .init(name: "OVER 0,5 PT"), .init(name: "PUNTA 1"), .init(name: "PUNTA 2"),
        .init(name: "PUNTA RIS. ESATTO"), .init(name: "BTTS"), .init(name: "SNIPE RIS. ESATTO"),
        .init(name: "TENNIS")
    ]

    var activeStrategies: [TradingStrategy] { strategies.filter(\.active).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } }
    var netProfit: Double { operations.reduce(0) { $0 + $1.result } }
    var totalStake: Double { operations.reduce(0) { $0 + $1.stakeEur } }
    var roi: Double { totalStake == 0 ? 0 : netProfit / totalStake }
    var wins: Int { operations.filter { $0.result > 0 }.count }
    var totalTrades: Int { operations.count }
    var winRate: Double { totalTrades == 0 ? 0 : Double(wins) / Double(totalTrades) }
    var currentBank: Double { startingBank + netProfit }

    func add(_ operation: TradeOperation) { operations.insert(operation, at: 0) }
    func delete(at offsets: IndexSet) { operations.remove(atOffsets: offsets) }
    func delete(_ operation: TradeOperation) { operations.removeAll { $0.id == operation.id } }

    func profit(on date: Date) -> Double {
        let cal = Calendar.current
        return operations.filter { cal.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.result }
    }

    func trades(on date: Date) -> Int {
        let cal = Calendar.current
        return operations.filter { cal.isDate($0.date, inSameDayAs: date) }.count
    }

    func bankrollSeries(days: Int) -> [(Date, Double)] {
        guard days > 0 else { return [] }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var out: [(Date, Double)] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            let d = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let pnl = operations.filter { $0.date < cal.date(byAdding: .day, value: 1, to: d)! }.reduce(0) { $0 + $1.result }
            out.append((d, startingBank + pnl))
        }
        return out
    }

    func filteredOperations(scope: Int) -> [TradeOperation] {
        let cal = Calendar.current
        let now = Date()
        switch scope {
        case 1:
            return operations.filter { cal.isDateInToday($0.date) }
        case 2:
            let start = cal.date(byAdding: .day, value: -7, to: now) ?? now
            return operations.filter { $0.date >= start }
        case 3:
            let start = cal.date(byAdding: .month, value: -1, to: now) ?? now
            return operations.filter { $0.date >= start }
        default:
            return operations
        }
    }

    func exportCSV() -> String {
        var lines = ["Data,Sport,Match,Mercato,Strategia,Minuto,Tranche,Stake %,Stake €,Quota,Risultato,Voto,Note"]
        let f = DateFormatter(); f.dateFormat = "dd/MM/yyyy"
        for o in operations {
            let vals = [f.string(from: o.date), o.sport, o.match, o.marketType, o.strategy, o.minute, o.tranche, String(format: "%.2f", o.stakePct), String(format: "%.2f", o.stakeEur), String(format: "%.2f", o.odds), String(format: "%.2f", o.result), o.rating, o.notes]
            lines.append(vals.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    func backupData() -> Data? {
        let payload = BackupPayload(operations: operations, strategies: strategies, startingBank: startingBank)
        return try? JSONEncoder().encode(payload)
    }

    func restore(from data: Data) throws {
        let payload = try JSONDecoder().decode(BackupPayload.self, from: data)
        operations = payload.operations
        strategies = payload.strategies
        startingBank = payload.startingBank
    }

    private func saveOperations() { if let data = try? JSONEncoder().encode(operations) { UserDefaults.standard.set(data, forKey: operationsKey) } }
    private func saveStrategies() { if let data = try? JSONEncoder().encode(strategies) { UserDefaults.standard.set(data, forKey: strategiesKey) } }
    private func loadOperations() { if let data = UserDefaults.standard.data(forKey: operationsKey), let value = try? JSONDecoder().decode([TradeOperation].self, from: data) { operations = value } }
    private func loadStrategies() { if let data = UserDefaults.standard.data(forKey: strategiesKey), let value = try? JSONDecoder().decode([TradingStrategy].self, from: data) { strategies = value } }
}

private struct BackupPayload: Codable {
    let operations: [TradeOperation]
    let strategies: [TradingStrategy]
    let startingBank: Double
}
