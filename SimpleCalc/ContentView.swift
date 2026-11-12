import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var calc = Calculator()
    @State private var showHistory: Bool = false
    @State private var showSettings: Bool = false
    @State private var lockedSize: CGSize? = nil
    @AppStorage("decimalPlaces") private var decimalPlaces: Int = -1
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 0) {
            calcPanel
                .padding(14)

            if showHistory {
                Divider()
                HistoryPanel(calc: calc)
                    .frame(width: 300)
                    .padding(14)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .containerBackground(.thinMaterial, for: .window)
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onAppear {
            focused = true
            calc.decimalPlaces = decimalPlaces
        }
        .onChange(of: decimalPlaces) { _, new in calc.decimalPlaces = new }
        .onKeyPress(phases: .down) { press in handleKey(press) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSettings.toggle()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .help("Settings")
                .popover(isPresented: $showSettings, arrowEdge: .top) {
                    SettingsView()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.snappy) { showHistory.toggle() }
                } label: {
                    Label("History", systemImage: showHistory ? "clock.fill" : "clock")
                }
                .help("Toggle history")
            }
        }
        .navigationTitle("SimpleCalc")
    }

    private var calcPanel: some View {
        VStack(spacing: 12) {
            DisplayView(text: calc.display, expression: calc.expressionText)
                .frame(width: lockedSize?.width)
            ButtonGrid(calc: calc)
                .fixedSize()
        }
        .fixedSize(horizontal: true, vertical: true)
        .background {
            GeometryReader { geo in
                Color.clear.onAppear {
                    if lockedSize == nil { lockedSize = geo.size }
                }
            }
        }
        .frame(width: lockedSize?.width, height: lockedSize?.height)
    }

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        if press.modifiers.contains(.command) {
            guard let ch = press.characters.first else { return .ignored }
            switch ch {
            case "c", "C":
                copyDisplay()
                return .handled
            case "v", "V":
                pasteIntoDisplay()
                return .handled
            case "\u{7F}", "\u{8}":
                calc.clear()
                return .handled
            default:
                return .ignored
            }
        }
        switch press.key {
        case .return:
            calc.equals()
            return .handled
        case .delete, .deleteForward:
            calc.backspace()
            return .handled
        case .escape:
            calc.clear()
            return .handled
        default:
            break
        }
        guard let ch = press.characters.first else { return .ignored }
        switch ch {
        case "\u{7F}", "\u{8}":
            calc.backspace()
            return .handled
        case "0"..."9":
            calc.digit(Int(String(ch)) ?? 0)
            return .handled
        case ".":
            calc.decimal()
            return .handled
        case "+":
            calc.setOp(.add)
            return .handled
        case "-":
            calc.setOp(.sub)
            return .handled
        case "*", "x", "X":
            calc.setOp(.mul)
            return .handled
        case "/":
            calc.setOp(.div)
            return .handled
        case "=", "\u{3}":
            calc.equals()
            return .handled
        case "%", "p", "P":
            calc.percent()
            return .handled
        case "n", "N":
            calc.negate()
            return .handled
        case "(":
            calc.openParen()
            return .handled
        case ")":
            calc.closeParen()
            return .handled
        default:
            return .ignored
        }
    }

    private func copyDisplay() {
        let raw = calc.display
            .replacingOccurrences(of: "≈ ", with: "")
            .replacingOccurrences(of: ",", with: "")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(raw, forType: .string)
    }

    private func pasteIntoDisplay() {
        guard let raw = NSPasteboard.general.string(forType: .string) else { return }
        calc.paste(raw)
    }
}

private struct DisplayView: View {
    let text: String
    let expression: String
    @State private var lockedHeight: CGFloat? = nil

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(text)
                .font(.system(size: 44, weight: .light, design: .rounded).monospacedDigit())
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .contentTransition(.numericText())
                .animation(.snappy, value: text)
            Text(expression.isEmpty ? " " : expression)
                .font(.system(size: 13, design: .rounded).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .animation(.snappy, value: expression)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background {
            GeometryReader { geo in
                Color.clear.onAppear {
                    if lockedHeight == nil { lockedHeight = geo.size.height }
                }
            }
        }
        .frame(height: lockedHeight)
    }
}

private struct ButtonGrid: View {
    let calc: Calculator

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                CalcButton(label: "AC", role: .utility) { calc.clear() }
                CalcButton(label: "±", role: .utility) { calc.negate() }
                CalcButton(label: "%", role: .utility) { calc.percent() }
                CalcButton(label: "÷", role: .op) { calc.setOp(.div) }
            }
            GridRow {
                CalcButton(label: "7") { calc.digit(7) }
                CalcButton(label: "8") { calc.digit(8) }
                CalcButton(label: "9") { calc.digit(9) }
                CalcButton(label: "×", role: .op) { calc.setOp(.mul) }
            }
            GridRow {
                CalcButton(label: "4") { calc.digit(4) }
                CalcButton(label: "5") { calc.digit(5) }
                CalcButton(label: "6") { calc.digit(6) }
                CalcButton(label: "−", role: .op) { calc.setOp(.sub) }
            }
            GridRow {
                CalcButton(label: "1") { calc.digit(1) }
                CalcButton(label: "2") { calc.digit(2) }
                CalcButton(label: "3") { calc.digit(3) }
                CalcButton(label: "+", role: .op) { calc.setOp(.add) }
            }
            GridRow {
                CalcButton(label: "0") { calc.digit(0) }
                CalcButton(label: ".") { calc.decimal() }
                CalcButton(label: "⌫", role: .utility) { calc.backspace() }
                    .keyboardShortcut(.delete, modifiers: [])
                CalcButton(label: "=", role: .equals) { calc.equals() }
                    .keyboardShortcut(.return, modifiers: [])
            }
        }
    }
}

private struct CalcButton: View {
    enum Role { case digit, op, utility, equals }

    let label: String
    var role: Role = .digit
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .frame(width: 64, height: 64)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(tint)
        .controlSize(.large)
    }

    private var tint: Color {
        switch role {
        case .digit: .secondary
        case .op: .orange
        case .utility: .gray
        case .equals: .accentColor
        }
    }
}

private struct HistoryPanel: View {
    let calc: Calculator
    @State private var showClearConfirm: Bool = false
    @State private var searchText: String = ""
    @State private var favoritesOnly: Bool = false
    @State private var showDateRange: Bool = false
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var dateRangeActive: Bool = false
    @State private var editingNoteId: UUID? = nil
    @State private var noteDraft: String = ""

    var filtered: [Calculator.HistoryEntry] {
        var entries = calc.history
        if favoritesOnly { entries = entries.filter { $0.favorite } }
        if dateRangeActive {
            let cal = Calendar.current
            let start = cal.startOfDay(for: startDate)
            let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: endDate)) ?? endDate
            entries = entries.filter { $0.date >= start && $0.date < end }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            entries = entries.filter {
                $0.expression.lowercased().contains(q)
                    || $0.result.lowercased().contains(q)
                    || $0.note.lowercased().contains(q)
            }
        }
        return entries
    }

    var grouped: [(date: Date, entries: [Calculator.HistoryEntry])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.date) }
        return dict.keys.sorted(by: >).map { (date: $0, entries: dict[$0] ?? []) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("History").font(.headline)
                Spacer()
                Button {
                    favoritesOnly.toggle()
                } label: {
                    Image(systemName: favoritesOnly ? "star.fill" : "star")
                        .foregroundStyle(favoritesOnly ? .yellow : .secondary)
                }
                .buttonStyle(.borderless)
                .help("Show favorites only")

                Button {
                    showDateRange.toggle()
                } label: {
                    Image(systemName: dateRangeActive ? "calendar.badge.checkmark" : "calendar")
                        .foregroundStyle(dateRangeActive ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.borderless)
                .help("Date range")
                .popover(isPresented: $showDateRange) {
                    dateRangePopover
                }

                Menu {
                    Button("Export CSV…") { exportCSV() }
                    Button("Export PDF…") { exportPDF() }
                    Divider()
                    Button("Clear History…", role: .destructive) { showClearConfirm = true }
                        .disabled(calc.history.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
            }
            .alert("Clear history?", isPresented: $showClearConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) { calc.clearHistory() }
            } message: {
                Text("All saved calculations will be permanently deleted.")
            }

            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))

            if calc.history.isEmpty {
                Spacer()
                ContentUnavailableView("No history", systemImage: "clock")
                    .frame(maxWidth: .infinity)
                Spacer()
            } else if filtered.isEmpty {
                Spacer()
                ContentUnavailableView("No matches", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12, pinnedViews: [.sectionHeaders]) {
                        ForEach(grouped, id: \.date) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    entryRow(entry)
                                }
                            } header: {
                                groupHeader(date: group.date, entries: group.entries)
                            }
                        }
                    }
                }
                .scrollIndicators(.never)
            }
        }
    }

    private var dateRangePopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Filter by date range", isOn: $dateRangeActive)
                .toggleStyle(.switch)
            DatePicker("From", selection: $startDate, displayedComponents: .date)
            DatePicker("To", selection: $endDate, displayedComponents: .date)
            HStack {
                Button("Last 7 days") {
                    startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                    endDate = Date()
                    dateRangeActive = true
                }
                Button("Last 30 days") {
                    startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                    endDate = Date()
                    dateRangeActive = true
                }
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .padding(14)
        .frame(width: 260)
    }

    private func groupHeader(date: Date, entries: [Calculator.HistoryEntry]) -> some View {
        let subtotal = entries.reduce(0.0) { acc, e in
            acc + (Double(e.result.replacingOccurrences(of: "≈ ", with: "").replacingOccurrences(of: ",", with: "")) ?? 0)
        }
        return HStack {
            Text(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text("Σ \(formatSubtotal(subtotal))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(.thinMaterial)
    }

    private func entryRow(_ entry: Calculator.HistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                Button {
                    calc.toggleFavorite(id: entry.id)
                } label: {
                    Image(systemName: entry.favorite ? "star.fill" : "star")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(entry.favorite ? .yellow : .secondary)
                        .font(.body)
                }
                .buttonStyle(.borderless)
                .help(entry.favorite ? "Unfavorite" : "Favorite")

                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.expression)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.result)
                        .font(.system(.body, design: .rounded).monospacedDigit())
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            if editingNoteId == entry.id {
                HStack(spacing: 6) {
                    TextField("Note", text: $noteDraft)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.small)
                    Button("Save") {
                        calc.setNote(id: entry.id, noteDraft)
                        editingNoteId = nil
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    Button("Cancel") {
                        editingNoteId = nil
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            } else {
                HStack(spacing: 6) {
                    if !entry.note.isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(entry.note)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Button {
                        noteDraft = entry.note
                        editingNoteId = entry.id
                    } label: {
                        Image(systemName: entry.note.isEmpty ? "square.and.pencil" : "pencil")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help(entry.note.isEmpty ? "Add note" : "Edit note")
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture(count: 2) {
            calc.loadEntry(entry)
        }
        .help("Double-tap to load expression")
    }

    private func formatSubtotal(_ v: Double) -> String {
        if v == v.rounded() && abs(v) < 1e15 {
            return Int(v).formatted(.number.grouping(.automatic))
        }
        return v.formatted(.number.precision(.fractionLength(0...4)).grouping(.automatic))
    }

    private func exportCSV() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "SimpleCalc-History.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        var csv = "Date,Expression,Result,Favorite,Note\n"
        let fmt = ISO8601DateFormatter()
        for entry in filtered {
            let cells = [fmt.string(from: entry.date), entry.expression, entry.result, entry.favorite ? "yes" : "no", entry.note]
            csv += cells.map { csvEscape($0) }.joined(separator: ",") + "\n"
        }
        try? csv.write(to: url, atomically: true, encoding: .utf8)
    }

    private func csvEscape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }

    private func exportPDF() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "SimpleCalc-History.pdf"
        panel.allowedContentTypes = [.pdf]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let entries = filtered
        let pdfContent = HistoryPDFView(entries: entries)
            .frame(width: 612)
            .padding(36)
        let renderer = ImageRenderer(content: pdfContent)
        renderer.render { size, ctxClosure in
            var box = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(url: url as CFURL),
                  let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else { return }
            ctx.beginPDFPage(nil)
            ctxClosure(ctx)
            ctx.endPDFPage()
            ctx.closePDF()
        }
    }
}

private struct HistoryPDFView: View {
    let entries: [Calculator.HistoryEntry]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SimpleCalc History")
                .font(.title2.bold())
            Text("Exported \(Date().formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
            ForEach(entries) { e in
                HStack(alignment: .top) {
                    if e.favorite {
                        Image(systemName: "star.fill").foregroundStyle(.yellow)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.expression).font(.body)
                        Text("= \(e.result)").font(.body.bold())
                        if !e.note.isEmpty {
                            Text(e.note).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(e.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Divider()
            }
        }
    }
}

private struct SettingsView: View {
    @AppStorage("decimalPlaces") private var decimalPlaces: Int = -1

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Decimal Places")
                    .font(.subheadline)
                Picker("Decimal Places", selection: $decimalPlaces) {
                    Text("Unlimited").tag(-1)
                    ForEach(0...10, id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                Text("When a result is rounded, the display shows ≈ before the number.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(width: 260)
    }
}

#Preview {
    ContentView()
        .frame(width: 320, height: 460)
}
