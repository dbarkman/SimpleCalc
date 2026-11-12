import Foundation
import Observation

@Observable
final class Calculator {
    enum Op: String, Codable, Hashable { case add = "+", sub = "−", mul = "×", div = "÷" }

    enum Token: Codable, Hashable {
        case number(String)
        case op(Op)
        case openParen
        case closeParen
    }

    struct HistoryEntry: Identifiable, Hashable, Codable {
        var id = UUID()
        let expression: String
        let result: String
        var date: Date = Date()
        var favorite: Bool = false
        var note: String = ""
        var tokens: [Token] = []

        enum CodingKeys: String, CodingKey {
            case id, expression, result, date, favorite, note, tokens
        }

        init(id: UUID = UUID(), expression: String, result: String, date: Date = Date(), favorite: Bool = false, note: String = "", tokens: [Token] = []) {
            self.id = id
            self.expression = expression
            self.result = result
            self.date = date
            self.favorite = favorite
            self.note = note
            self.tokens = tokens
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
            expression = try c.decode(String.self, forKey: .expression)
            result = try c.decode(String.self, forKey: .result)
            date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
            favorite = try c.decodeIfPresent(Bool.self, forKey: .favorite) ?? false
            note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
            tokens = try c.decodeIfPresent([Token].self, forKey: .tokens) ?? []
        }
    }

    var tokens: [Token] = []
    var current: String = ""
    var lastResult: Double? = nil
    var history: [HistoryEntry] = []
    var decimalPlaces: Int = -1  // -1 = unlimited
    var roundOverride: Int? = nil  // one-shot post-equals rounding via backspace

    init() {
        history = Self.loadHistory()
    }

    var display: String {
        if !current.isEmpty {
            if let last = tokens.last, case .op = last, Double(current) != nil {
                var trial = tokens
                trial.append(.number(current))
                if let v = evaluateTokens(trial) { return format(v) }
            }
            return displayFormat(current)
        }
        if let r = lastResult { return format(r) }
        if let last = tokens.last {
            if case .number(let s) = last { return displayFormat(s) }
            if let v = evaluate() { return format(v) }
        }
        return "0"
    }

    var expressionText: String {
        var out = tokens.map { tok -> String in
            switch tok {
            case .number(let s): return displayFormat(s)
            case .op(let o): return o.rawValue
            case .openParen: return "("
            case .closeParen: return ")"
            }
        }.joined(separator: " ")
            .replacingOccurrences(of: "( ", with: "(")
            .replacingOccurrences(of: " )", with: ")")
        if !current.isEmpty {
            if let last = tokens.last, case .op = last {
                out += " " + displayFormat(current)
            } else if let last = tokens.last, case .openParen = last {
                out += displayFormat(current)
            } else if tokens.isEmpty {
                out = displayFormat(current)
            }
        }
        return out
    }

    func digit(_ d: Int) {
        if lastResult != nil { reset() }
        roundOverride = nil
        let digitCount = current.filter { $0.isNumber }.count
        guard digitCount < 15 else { return }
        if current.isEmpty || current == "0" { current = String(d) }
        else if current == "-0" { current = "-" + String(d) }
        else { current += String(d) }
    }

    func decimal() {
        if lastResult != nil { reset() }
        roundOverride = nil
        if current.isEmpty { current = "0." }
        else if !current.contains(".") { current += "." }
    }

    func setOp(_ op: Op) {
        roundOverride = nil
        if lastResult != nil {
            tokens = [.number(formatNumber(lastResult!))]
            lastResult = nil
        }
        commitCurrent()
        if let last = tokens.last, case .op = last { tokens.removeLast() }
        guard !tokens.isEmpty else { return }
        tokens.append(.op(op))
    }

    func equals() {
        roundOverride = nil
        commitCurrent()
        if let last = tokens.last, case .op = last { tokens.removeLast() }
        guard !tokens.isEmpty, let v = evaluate() else { return }
        let hasOp = tokens.contains { if case .op = $0 { return true } else { return false } }
        let expr = expressionText
        let resStr = format(v)
        if hasOp { recordHistory(expression: expr, result: resStr, tokens: tokens) }
        lastResult = v
        if hasOp { tokens = [] }
    }

    func backspace() {
        if let r = lastResult, roundOverride == nil {
            let scaled = r * 100
            if abs(scaled - scaled.rounded()) > 1e-9 {
                roundOverride = 2
                return
            }
        }
        if lastResult != nil {
            lastResult = nil
        }
        roundOverride = nil
        if !current.isEmpty {
            current.removeLast()
            if current == "-" { current = "" }
        } else if !tokens.isEmpty {
            let popped = tokens.removeLast()
            if case .number(let s) = popped {
                var rest = s
                if !rest.isEmpty { rest.removeLast() }
                if rest == "-" { rest = "" }
                current = rest
            }
        }
    }

    func clear() {
        reset()
    }

    func openParen() {
        roundOverride = nil
        if lastResult != nil { reset() }
        if !current.isEmpty {
            commitCurrent()
            tokens.append(.op(.mul))
        } else if let last = tokens.last {
            if case .number = last { tokens.append(.op(.mul)) }
            else if case .closeParen = last { tokens.append(.op(.mul)) }
        }
        tokens.append(.openParen)
    }

    func closeParen() {
        roundOverride = nil
        commitCurrent()
        tokens.append(.closeParen)
    }

    func negate() {
        if !current.isEmpty {
            current = current.hasPrefix("-") ? String(current.dropFirst()) : "-" + current
        } else if let last = tokens.last, case .number(let s) = last {
            tokens.removeLast()
            let flipped = s.hasPrefix("-") ? String(s.dropFirst()) : "-" + s
            tokens.append(.number(flipped))
        } else if let r = lastResult {
            lastResult = -r
        }
    }

    func percent() {
        if !current.isEmpty, let v = Double(current) {
            if tokens.count >= 2,
               case .op(let pending) = tokens.last,
               (pending == .add || pending == .sub),
               case .number(let lhsStr) = tokens[tokens.count - 2],
               let lhs = Double(lhsStr) {
                current = formatNumber(lhs * v / 100)
            } else {
                current = formatNumber(v / 100)
            }
        } else if let last = tokens.last, case .number(let s) = last, let v = Double(s) {
            tokens.removeLast()
            tokens.append(.number(formatNumber(v / 100)))
        } else if let r = lastResult {
            lastResult = r / 100
        }
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    func toggleFavorite(id: UUID) {
        guard let idx = history.firstIndex(where: { $0.id == id }) else { return }
        history[idx].favorite.toggle()
        saveHistory()
    }

    func setNote(id: UUID, _ note: String) {
        guard let idx = history.firstIndex(where: { $0.id == id }) else { return }
        history[idx].note = note
        saveHistory()
    }

    func loadEntry(_ entry: HistoryEntry) {
        roundOverride = nil
        current = ""
        lastResult = nil
        if !entry.tokens.isEmpty {
            tokens = entry.tokens
        } else {
            tokens = Self.parseExpression(entry.expression)
        }
    }

    static func parseExpression(_ s: String) -> [Token] {
        var tokens: [Token] = []
        var buffer = ""
        func flushNumber() {
            if !buffer.isEmpty {
                tokens.append(.number(buffer))
                buffer = ""
            }
        }
        for ch in s {
            switch ch {
            case " ":
                flushNumber()
            case ",":
                continue
            case "0"..."9", ".":
                buffer.append(ch)
            case "-":
                if buffer.isEmpty { buffer.append(ch) }
                else { flushNumber() }
            case "+":
                flushNumber(); tokens.append(.op(.add))
            case "−":
                flushNumber(); tokens.append(.op(.sub))
            case "×":
                flushNumber(); tokens.append(.op(.mul))
            case "÷":
                flushNumber(); tokens.append(.op(.div))
            case "(":
                flushNumber(); tokens.append(.openParen)
            case ")":
                flushNumber(); tokens.append(.closeParen)
            default:
                continue
            }
        }
        flushNumber()
        return tokens
    }

    private func reset() {
        tokens = []
        current = ""
        lastResult = nil
        roundOverride = nil
    }

    private func commitCurrent() {
        guard !current.isEmpty else { return }
        if let last = tokens.last, case .number = last {
            tokens.removeLast()
        }
        tokens.append(.number(current))
        current = ""
    }

    private func evaluate() -> Double? {
        return evaluateTokens(tokens)
    }

    private func evaluateTokens(_ tokens: [Token]) -> Double? {
        guard !tokens.isEmpty else { return nil }

        var input = tokens
        while let last = input.last {
            switch last {
            case .op, .openParen: input.removeLast()
            default: return evalCompleted(input)
            }
        }
        return nil
    }

    private func evalCompleted(_ tokens: [Token]) -> Double? {
        guard !tokens.isEmpty else { return nil }
        var output: [Token] = []
        var opStack: [Token] = []
        for tok in tokens {
            switch tok {
            case .number:
                output.append(tok)
            case .op(let o):
                while let top = opStack.last {
                    if case .op(let topOp) = top, precedence(topOp) >= precedence(o) {
                        output.append(opStack.removeLast())
                    } else { break }
                }
                opStack.append(tok)
            case .openParen:
                opStack.append(tok)
            case .closeParen:
                var matched = false
                while let top = opStack.last {
                    if case .openParen = top {
                        opStack.removeLast()
                        matched = true
                        break
                    }
                    output.append(opStack.removeLast())
                }
                if !matched { return nil }
            }
        }
        while let top = opStack.popLast() {
            if case .openParen = top { continue }
            output.append(top)
        }
        var stack: [Double] = []
        for tok in output {
            switch tok {
            case .number(let s):
                guard let v = Double(s) else { return nil }
                stack.append(v)
            case .op(let o):
                guard stack.count >= 2 else { return nil }
                let b = stack.removeLast()
                let a = stack.removeLast()
                stack.append(compute(a, b, o))
            case .openParen, .closeParen:
                return nil
            }
        }
        return stack.last
    }

    private func precedence(_ op: Op) -> Int {
        switch op {
        case .add, .sub: return 1
        case .mul, .div: return 2
        }
    }

    private func compute(_ a: Double, _ b: Double, _ op: Op) -> Double {
        switch op {
        case .add: return a + b
        case .sub: return a - b
        case .mul: return a * b
        case .div: return b == 0 ? .nan : a / b
        }
    }

    private func formatNumber(_ d: Double) -> String {
        if d.isNaN || d.isInfinite { return "Error" }
        let places = roundOverride ?? decimalPlaces
        if d == d.rounded() && abs(d) < 1e15 && places < 0 {
            return String(format: "%.0f", d)
        }
        if places >= 0 {
            let factor = pow(10.0, Double(places))
            let r = (d * factor).rounded() / factor
            return String(format: "%.\(places)f", r)
        }
        return d.formatted(.number.precision(.significantDigits(1...15)).grouping(.never))
    }

    func displayFormat(_ s: String) -> String {
        let negative = s.hasPrefix("-")
        let body = negative ? String(s.dropFirst()) : s
        let trailingDot = body.hasSuffix(".")
        let parts = body.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        let intPart = parts.first ?? ""
        let fracPart = parts.count > 1 ? parts[1] : ""
        guard let intVal = Int(intPart) ?? (intPart.isEmpty ? 0 : nil) else { return s }
        let groupedInt = intVal.formatted(.number.grouping(.automatic))
        var out = groupedInt
        if !fracPart.isEmpty || trailingDot {
            out += "." + fracPart
        }
        if negative { out = "-" + out }
        return out
    }

    private func wasRounded(_ d: Double) -> Bool {
        guard !d.isNaN, !d.isInfinite else { return false }
        if d == d.rounded() && abs(d) < 1e15 { return false }
        let places = roundOverride ?? decimalPlaces
        if places >= 0 {
            let factor = pow(10.0, Double(places))
            let r = (d * factor).rounded() / factor
            return abs(d - r) > 1e-12
        }
        let capped = d.formatted(.number.precision(.significantDigits(1...15)).grouping(.never))
        if let back = Double(capped) {
            return abs(d - back) > 1e-12
        }
        return false
    }

    private func format(_ d: Double) -> String {
        let text = displayFormat(formatNumber(d))
        return wasRounded(d) ? "≈ \(text)" : text
    }

    private func recordHistory(expression: String, result: String, tokens: [Token] = []) {
        let entry = HistoryEntry(expression: expression, result: result, tokens: tokens)
        history.insert(entry, at: 0)
        saveHistory()
    }

    private static var storeURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("SimpleCalc", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }

    private static func loadHistory() -> [HistoryEntry] {
        guard let data = try? Data(contentsOf: storeURL),
              let entries = try? JSONDecoder().decode([HistoryEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        try? data.write(to: Self.storeURL, options: .atomic)
    }
}
