import SwiftUI
import AppKit

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
                    .frame(width: 220)
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
        let cleaned = raw
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, Double(cleaned) != nil else { return }
        calc.clear()
        let negative = cleaned.hasPrefix("-")
        let body = negative ? String(cleaned.dropFirst()) : cleaned
        for ch in body {
            if ch == "." { calc.decimal() }
            else if let d = Int(String(ch)) { calc.digit(d) }
        }
        if negative { calc.negate() }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("History")
                    .font(.headline)
                Spacer()
                Button("Clear") { showClearConfirm = true }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .disabled(calc.history.isEmpty)
            }
            .alert("Clear history?", isPresented: $showClearConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) { calc.clearHistory() }
            } message: {
                Text("All saved calculations will be permanently deleted.")
            }

            if calc.history.isEmpty {
                Spacer()
                ContentUnavailableView("No history", systemImage: "clock")
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(calc.history) { entry in
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(entry.expression)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(entry.result)
                                    .font(.system(.body, design: .rounded).monospacedDigit())
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .scrollIndicators(.never)
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
