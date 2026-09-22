import SwiftUI
import Charts

private enum V7Tab: Int { case home, newTrade, journal, stats, bankroll }

struct ContentView: View {
    @EnvironmentObject private var store: TradeStore
    @State private var tab: V7Tab = .home
    @State private var showTools = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 3/255, green: 12/255, blue: 20/255), Color(red: 4/255, green: 18/255, blue: 29/255)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                if tab == .home { homeHeader } else { pageHeader }
                Group {
                    switch tab {
                    case .home: DashboardView()
                    case .newTrade: NewTradeView { tab = .journal }
                    case .journal: JournalView()
                    case .stats: StatsView()
                    case .bankroll: BankrollView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                bottomBar
            }
        }
        .sheet(isPresented: $showTools) { ToolsView() }
        .tint(.cyan)
    }

    private var homeHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.18))
                Image(systemName: "chart.line.uptrend.xyaxis").font(.title2).foregroundStyle(.cyan)
            }.frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 1) {
                Text("FasTrade").font(.system(size: 25, weight: .bold))
                Text("SPORTS TRADING").font(.system(size: 9, weight: .bold)).tracking(2.2).foregroundStyle(.blue)
            }
            Spacer()
            Button { showTools = true } label: {
                Image(systemName: "gearshape.fill").font(.title3).frame(width: 42, height: 42).background(Color.blue.opacity(0.14)).clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 18).padding(.top, 8)
        .overlay(alignment: .bottomLeading) {
            Text("DISCIPLINA  |  STRATEGIA  |  RISULTATI").font(.system(size: 8)).tracking(1.2).foregroundStyle(Color(red: 164/255, green: 191/255, blue: 215/255)).padding(.leading, 78).offset(y: 14)
        }
        .padding(.bottom, 18)
    }

    private var pageHeader: some View {
        HStack {
            Button { tab = .home } label: { Image(systemName: "chevron.left").font(.title3).frame(width: 42, height: 42) }
            Spacer()
            Text(titleForTab).font(.headline)
            Spacer()
            Color.clear.frame(width: 42, height: 42)
        }.padding(.horizontal, 12).padding(.vertical, 5)
    }

    private var titleForTab: String {
        switch tab { case .home: return ""; case .newTrade: return "Nuova Operazione"; case .journal: return "Diario Operazioni"; case .stats: return "Statistiche"; case .bankroll: return "Bankroll" }
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            navItem(.home, "house.fill", "Home")
            navItem(.newTrade, "plus", "Nuova")
            navItem(.journal, "list.bullet.rectangle", "Diario")
            navItem(.stats, "chart.bar.fill", "Statistiche")
            navItem(.bankroll, "eurosign.circle.fill", "Bankroll")
        }
        .padding(.top, 4).padding(.bottom, 6)
        .background(Color(red: 6/255, green: 20/255, blue: 31/255))
    }

    private func navItem(_ target: V7Tab, _ icon: String, _ label: String) -> some View {
        Button { tab = target } label: {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(label).font(.system(size: 9))
            }.frame(maxWidth: .infinity).foregroundStyle(tab == target ? .blue : Color(red: 149/255, green: 169/255, blue: 190/255))
        }
    }
}

private struct DashboardView: View {
    @EnvironmentObject var store: TradeStore
    @State private var days = 30

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("BANKROLL ATTUALE").font(.caption2).tracking(1.2).foregroundStyle(.secondary)
                    Text(store.currentBank, format: .currency(code: "EUR")).font(.system(size: 34, weight: .bold))
                    HStack { metric("Net Profit", store.netProfit, color: store.netProfit >= 0 ? .green : .red); metric("ROI", store.roi * 100, suffix: "%", color: store.roi >= 0 ? .green : .red); metric("Win Rate", store.winRate * 100, suffix: "%", color: .cyan) }
                }.v7Card()

                HStack { Text("Andamento Bankroll").font(.headline); Spacer(); ForEach([7,30,90,365], id: \.self) { d in Button(d == 7 ? "7G" : d == 30 ? "1M" : d == 90 ? "3M" : "1A") { days = d }.buttonStyle(.borderedProminent).tint(days == d ? .blue : .gray.opacity(0.3)).controlSize(.mini) } }
                Chart(store.bankrollSeries(days: days), id: \.0) { point in LineMark(x: .value("Data", point.0), y: .value("Bank", point.1)).interpolationMethod(.catmullRom); AreaMark(x: .value("Data", point.0), y: .value("Bank", point.1)).opacity(0.12) }.frame(height: 170).v7Card()

                HStack { Text("Oggi").font(.headline); Spacer(); Text(Date.now, format: .dateTime.day().month(.abbreviated).year()).font(.caption).foregroundStyle(.secondary) }
                HStack { metric("Profitto Giornaliero", store.profit(on: .now), color: store.profit(on: .now) >= 0 ? .green : .red); metric("Target 1%", store.currentBank * 0.01, color: .yellow); metric("Operazioni", Double(store.trades(on: .now)), color: .blue) }
                if store.startingBank == 0 { NavigationLinkLikeButton(title: "IMPOSTA STARTING BANK") { } }
            }.padding(16)
        }
    }

    private func metric(_ title: String, _ value: Double, suffix: String = "€", color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) { Text(title).font(.caption2).foregroundStyle(.secondary); Text(suffix == "€" ? value.formatted(.currency(code: "EUR")) : String(format: "%.1f%@", value, suffix)).font(.headline).foregroundStyle(color) }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NewTradeView: View {
    @EnvironmentObject var store: TradeStore
    var onSaved: () -> Void
    @State private var op = TradeOperation()
    @State private var win = true
    @State private var resultText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                DatePicker("Data", selection: $op.date, displayedComponents: .date).v7Field()
                Picker("Sport", selection: $op.sport) { ForEach(store.sports, id: \.self) { Text($0) } }.v7Field()
                TextField("Es. Juventus - Lazio", text: $op.match).v7Field(label: "Match")
                Picker("Mercato", selection: $op.marketType) { ForEach(store.markets, id: \.self) { Text($0) } }.v7Field()
                Picker("Strategia", selection: $op.strategy) { ForEach(store.activeStrategies) { Text($0.name).tag($0.name) } }.v7Field()
                HStack { TextField("45", text: $op.minute).keyboardType(.numberPad).v7Field(label: "Minuto ingresso"); TextField("1", text: $op.tranche).keyboardType(.numberPad).v7Field(label: "Tranche"); TextField("2,0", value: $op.stakePct, format: .number).keyboardType(.decimalPad).v7Field(label: "Stake %") }
                VStack(spacing: 4) { Text("Stake € (calcolato)").font(.caption); Text(store.currentBank * op.stakePct / 100, format: .currency(code: "EUR")).font(.title3.bold()).foregroundStyle(.green) }.frame(maxWidth: .infinity).padding().background(LinearGradient(colors: [.green.opacity(.35), .green.opacity(.12)], startPoint: .leading, endPoint: .trailing)).clipShape(RoundedRectangle(cornerRadius: 14))
                TextField("1,75", value: $op.odds, format: .number).keyboardType(.decimalPad).v7Field(label: "Quota ingresso")
                HStack { resultButton("WIN", true, .green); resultButton("LOSE", false, .red) }
                TextField("Es. 18,75", text: $resultText).keyboardType(.decimalPad).v7Field(label: "Profit / Loss €")
                TextField("A / B / C", text: $op.rating).v7Field(label: "Voto operazione")
                TextField("Aggiungi una nota...", text: $op.notes, axis: .vertical).lineLimit(3...6).v7Field(label: "Note (opzionale)")
                Button("SALVA OPERAZIONE") { save() }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity).controlSize(.large)
            }.padding(16)
        }
    }

    private func resultButton(_ title: String, _ state: Bool, _ color: Color) -> some View { Button(title) { win = state }.frame(maxWidth: .infinity).padding(.vertical, 10).background(win == state ? color : Color.white.opacity(.08)).clipShape(RoundedRectangle(cornerRadius: 10)) }
    private func save() { var x = op; x.stakeEur = store.currentBank * x.stakePct / 100; let normalized = resultText.replacingOccurrences(of: ",", with: "."); let value = Double(normalized) ?? 0; x.result = win ? abs(value) : -abs(value); store.add(x); onSaved() }
}

private struct JournalView: View {
    @EnvironmentObject var store: TradeStore
    @State private var scope = 0
    private let names = ["Tutte", "Oggi", "Settimana", "Mese"]
    var body: some View {
        VStack(spacing: 8) {
            Picker("Periodo", selection: $scope) { ForEach(names.indices, id: \.self) { Text(names[$0]).tag($0) } }.pickerStyle(.segmented).padding(.horizontal, 16)
            List {
                ForEach(store.filteredOperations(scope: scope)) { o in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack { Text(o.match.isEmpty ? "—" : o.match).font(.headline); Spacer(); Text(o.result, format: .currency(code: "EUR")).foregroundStyle(o.result >= 0 ? .green : .red).bold() }
                        Text("\(o.marketType) | \(o.strategy)").font(.caption).foregroundStyle(.secondary)
                        Text("\(o.sport)  •  \(o.minute.isEmpty ? "—" : o.minute + "'")  •  @\(o.odds, specifier: "%.2f")  •  Stake \(o.stakeEur, format: .currency(code: "EUR"))").font(.caption2).foregroundStyle(.secondary)
                        if !o.notes.isEmpty { Text(o.notes).font(.caption) }
                    }.padding(.vertical, 4).listRowBackground(Color(red: 5/255, green: 23/255, blue: 35/255))
                }.onDelete(perform: store.delete)
            }.scrollContentBackground(.hidden)
        }
    }
}

private struct StatsView: View {
    @EnvironmentObject var store: TradeStore
    var body: some View {
        ScrollView { VStack(spacing: 14) {
            HStack { stat("Operazioni", "\(store.totalTrades)"); stat("Win Rate", String(format: "%.1f%%", store.winRate * 100)); stat("ROI", String(format: "%.1f%%", store.roi * 100)) }.v7Card()
            strategyBreakdown
        }.padding(16) }
    }
    private func stat(_ a: String, _ b: String) -> some View { VStack { Text(a).font(.caption).foregroundStyle(.secondary); Text(b).font(.title3.bold()) }.frame(maxWidth: .infinity) }
    private var strategyBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) { Text("Performance per Strategia").font(.headline); ForEach(Dictionary(grouping: store.operations, by: \.strategy).keys.sorted(), id: \.self) { key in let ops = store.operations.filter { $0.strategy == key }; let pnl = ops.reduce(0) { $0 + $1.result }; HStack { Text(key); Spacer(); Text("\(ops.count) trade").foregroundStyle(.secondary); Text(pnl, format: .currency(code: "EUR")).foregroundStyle(pnl >= 0 ? .green : .red).frame(width: 90, alignment: .trailing) }.font(.subheadline) } }.v7Card()
    }
}

private struct BankrollView: View {
    @EnvironmentObject var store: TradeStore
    @State private var bankText = ""
    var body: some View {
        ScrollView { VStack(spacing: 16) {
            VStack(spacing: 6) { Text("Bankroll Attuale").foregroundStyle(.secondary); Text(store.currentBank, format: .currency(code: "EUR")).font(.system(size: 34, weight: .bold)); Text("Net Profit \(store.netProfit, format: .currency(code: "EUR"))").foregroundStyle(store.netProfit >= 0 ? .green : .red) }.v7Card()
            TextField("Starting Bank", text: $bankText).keyboardType(.decimalPad).v7Field(label: "Starting Bank")
            Button("SALVA STARTING BANK") { store.startingBank = Double(bankText.replacingOccurrences(of: ",", with: ".")) ?? store.startingBank }.buttonStyle(.borderedProminent)
            Chart(store.bankrollSeries(days: 30), id: \.0) { p in LineMark(x: .value("Data", p.0), y: .value("Bank", p.1)); AreaMark(x: .value("Data", p.0), y: .value("Bank", p.1)).opacity(.12) }.frame(height: 230).v7Card()
        }.padding(16) }.onAppear { bankText = String(format: "%.2f", store.startingBank) }
    }
}

private struct ToolsView: View {
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack { List {
            Section("Strategie") { ForEach($store.strategies) { $s in Toggle(s.name, isOn: $s.active) } }
            Section("Dati") { ShareLink(item: store.exportCSV(), preview: SharePreview("FasTrade V7 - Operazioni.csv")) { Label("Esporta CSV", systemImage: "square.and.arrow.up") } }
        }.navigationTitle("Strumenti").toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fine") { dismiss() } } } }
    }
}

private struct NavigationLinkLikeButton: View { let title: String; let action: () -> Void; var body: some View { Button(title, action: action).buttonStyle(.borderedProminent).frame(maxWidth: .infinity) } }

private extension View {
    func v7Card() -> some View { self.padding(14).background(Color(red: 8/255, green: 25/255, blue: 38/255)).clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 31/255, green: 63/255, blue: 88/255), lineWidth: 0.7)) }
    func v7Field(label: String? = nil) -> some View { VStack(alignment: .leading, spacing: 6) { if let label { Text(label).font(.caption).foregroundStyle(.secondary) }; self.padding(11).background(Color(red: 14/255, green: 34/255, blue: 50/255)).clipShape(RoundedRectangle(cornerRadius: 11)) }.frame(maxWidth: .infinity, alignment: .leading) }
}
