import Testing
@testable import SimpleCalc

@Suite("Calculator math")
struct CalculatorTests {

    // MARK: Basic ops

    @Test func add() {
        let c = Calculator()
        c.digit(2); c.setOp(.add); c.digit(3); c.equals()
        #expect(c.display == "5")
    }

    @Test func subtract() {
        let c = Calculator()
        c.digit(9); c.setOp(.sub); c.digit(4); c.equals()
        #expect(c.display == "5")
    }

    @Test func multiply() {
        let c = Calculator()
        c.digit(6); c.setOp(.mul); c.digit(7); c.equals()
        #expect(c.display == "42")
    }

    @Test func divide() {
        let c = Calculator()
        c.digit(8); c.setOp(.div); c.digit(2); c.equals()
        #expect(c.display == "4")
    }

    @Test func divideByZero() {
        let c = Calculator()
        c.digit(5); c.setOp(.div); c.digit(0); c.equals()
        #expect(c.display == "Error")
    }

    // MARK: Multi-digit + chained

    @Test func multiDigitAdd() {
        let c = Calculator()
        c.digit(2); c.digit(4); c.setOp(.add); c.digit(8); c.equals()
        #expect(c.display == "32")
    }

    @Test func reportedBug_1_plus_24_plus_8() {
        let c = Calculator()
        c.digit(1); c.setOp(.add); c.digit(2); c.digit(4); c.setOp(.add); c.digit(8); c.equals()
        #expect(c.display == "33", "1 + 24 + 8 must equal 33 (reported by user)")
    }

    @Test func chainedFiveTerms() {
        let c = Calculator()
        c.digit(1); c.setOp(.add)
        c.digit(2); c.setOp(.add)
        c.digit(3); c.setOp(.add)
        c.digit(4); c.setOp(.add)
        c.digit(5); c.equals()
        #expect(c.display == "15")
    }

    @Test func precedenceMulBeforeAdd() {
        let c = Calculator()
        c.digit(2); c.setOp(.add); c.digit(3); c.setOp(.mul); c.digit(4); c.equals()
        #expect(c.display == "14", "PEMDAS: 2 + 3 * 4 = 14")
    }

    @Test func precedenceMulFirst() {
        let c = Calculator()
        c.digit(5); c.setOp(.mul); c.digit(5); c.setOp(.add); c.digit(3); c.equals()
        #expect(c.display == "28", "5 * 5 + 3 = 28")
    }

    @Test func precedenceAddThenMul() {
        let c = Calculator()
        c.digit(3); c.setOp(.add); c.digit(5); c.setOp(.mul); c.digit(5); c.equals()
        #expect(c.display == "28", "3 + 5 * 5 = 28 (not 40)")
    }

    @Test func precedenceMultipleMulAndAdd() {
        let c = Calculator()
        c.digit(2); c.setOp(.mul); c.digit(3); c.setOp(.add); c.digit(4); c.setOp(.mul); c.digit(5); c.equals()
        #expect(c.display == "26", "2*3 + 4*5 = 26")
    }

    @Test func precedenceDivBeforeSub() {
        let c = Calculator()
        c.digit(2); c.digit(0); c.setOp(.sub); c.digit(1); c.digit(0); c.setOp(.div); c.digit(2); c.equals()
        #expect(c.display == "15", "20 - 10 / 2 = 15")
    }

    // MARK: Parentheses

    @Test func parensOverridePrecedence() {
        let c = Calculator()
        c.openParen(); c.digit(2); c.setOp(.add); c.digit(3); c.closeParen(); c.setOp(.mul); c.digit(4); c.equals()
        #expect(c.display == "20", "(2+3)*4 = 20")
    }

    @Test func nestedParens() {
        let c = Calculator()
        c.openParen(); c.openParen(); c.digit(1); c.setOp(.add); c.digit(2); c.closeParen(); c.setOp(.mul); c.openParen(); c.digit(3); c.setOp(.add); c.digit(4); c.closeParen(); c.closeParen(); c.equals()
        #expect(c.display == "21", "((1+2)*(3+4)) = 21")
    }

    @Test func parensMidExpression() {
        let c = Calculator()
        c.digit(2); c.setOp(.add); c.openParen(); c.digit(3); c.setOp(.mul); c.digit(4); c.closeParen(); c.equals()
        #expect(c.display == "14", "2 + (3*4) = 14")
    }

    @Test func parensImplicitMultiplyAfterNumber() {
        let c = Calculator()
        c.digit(5); c.openParen(); c.digit(2); c.setOp(.add); c.digit(3); c.closeParen(); c.equals()
        #expect(c.display == "25", "5(2+3) implicit-mul = 25")
    }

    // MARK: Decimal

    @Test func decimalAdd() {
        let c = Calculator()
        c.digit(1); c.decimal(); c.digit(5); c.setOp(.add); c.digit(2); c.decimal(); c.digit(5); c.equals()
        #expect(c.display == "4")
    }

    @Test func decimalNoDoubleDot() {
        let c = Calculator()
        c.digit(1); c.decimal(); c.decimal(); c.digit(5)
        #expect(c.display == "1.5")
    }

    // MARK: Negate / percent

    @Test func negateCurrent() {
        let c = Calculator()
        c.digit(5); c.negate()
        #expect(c.display == "-5")
        c.negate()
        #expect(c.display == "5")
    }

    @Test func negateThenAdd() {
        let c = Calculator()
        c.digit(5); c.negate(); c.setOp(.add); c.digit(3); c.equals()
        #expect(c.display == "-2")
    }

    @Test func percent() {
        let c = Calculator()
        c.digit(5); c.digit(0); c.percent()
        #expect(c.display == "0.5")
    }

    @Test func percentSubtractsAsFractionOfLhs() {
        let c = Calculator()
        c.digit(1); c.digit(0); c.digit(0); c.setOp(.sub); c.digit(2); c.digit(0); c.percent()
        #expect(c.display == "80", "100 - 20% shows running 80 (live eval, no auto-equals)")
        c.equals()
        #expect(c.display == "80")
    }

    @Test func percentAddsAsFractionOfLhs() {
        let c = Calculator()
        c.digit(1); c.digit(0); c.digit(0); c.setOp(.add); c.digit(2); c.digit(0); c.percent()
        #expect(c.display == "120", "100 + 20% shows running 120 (live eval, no auto-equals)")
        c.equals()
        #expect(c.display == "120")
    }

    @Test func percentMultipliesAsLiteralFraction() {
        let c = Calculator()
        c.digit(1); c.digit(0); c.digit(0); c.setOp(.mul); c.digit(2); c.digit(0); c.percent(); c.equals()
        #expect(c.display == "20", "100 × 20% = 20")
    }

    // MARK: Backspace (atom-by-atom)

    @Test func backspaceDigitsThenOpThenDigits() {
        let c = Calculator()
        c.digit(1); c.setOp(.add); c.digit(2); c.digit(4); c.setOp(.add); c.digit(8)
        #expect(c.expressionText == "1 + 24 + 8")
        c.backspace()
        #expect(c.expressionText == "1 + 24 +", "should peel '8' first")
        c.backspace()
        #expect(c.expressionText == "1 + 24", "should peel trailing '+'")
        c.backspace()
        #expect(c.expressionText == "1 + 2", "should peel one digit of 24")
        c.backspace()
        #expect(c.expressionText == "1 +", "should peel remaining digit")
        c.backspace()
        #expect(c.expressionText == "1", "should peel '+'")
    }

    @Test func backspaceClearsToZero() {
        let c = Calculator()
        c.digit(7); c.backspace()
        #expect(c.display == "0")
    }

    // MARK: Continue from result

    @Test func continueFromLastResult() {
        let c = Calculator()
        c.digit(2); c.setOp(.add); c.digit(3); c.equals()
        #expect(c.display == "5")
        c.setOp(.mul); c.digit(4); c.equals()
        #expect(c.display == "20")
    }

    @Test func digitAfterEqualsRestarts() {
        let c = Calculator()
        c.digit(2); c.setOp(.add); c.digit(3); c.equals()
        c.digit(9)
        #expect(c.display == "9")
        #expect(c.expressionText == "9")
    }

    // MARK: Clear

    @Test func clearWipesEverything() {
        let c = Calculator()
        c.digit(1); c.setOp(.add); c.digit(2); c.clear()
        #expect(c.display == "0")
        #expect(c.expressionText == "")
    }

    // MARK: Op replacement

    @Test func consecutiveOpReplacesLast() {
        let c = Calculator()
        c.digit(5); c.setOp(.add); c.setOp(.mul); c.digit(3); c.equals()
        #expect(c.display == "15", "5 +(replaced by ×) 3 = 15")
    }

    // MARK: Regression — reported bug 2026-05-14

    @Test func reportedBug_BackspaceThroughOpThenContinue() {
        let c = Calculator()
        c.digit(1); c.setOp(.add); c.digit(2); c.setOp(.add); c.digit(3)
        c.backspace(); c.backspace(); c.backspace()
        c.digit(4); c.setOp(.add); c.digit(8); c.equals()
        #expect(c.display == "13", "1+2+3 then BKSP×3 then 4+8 = 13")
    }

    @Test func droppedBackspaceMustNotProduceAdjacentNumbers() {
        let c = Calculator()
        c.digit(1); c.setOp(.add); c.digit(2); c.setOp(.add); c.digit(3)
        c.backspace(); c.backspace()
        c.digit(4); c.setOp(.add); c.digit(8); c.equals()
        #expect(c.display == "13", "Even if a backspace is dropped, must not silently drop a number")
    }

    @Test func backspaceTrailingOpRevealsPreviousOperand() {
        let c = Calculator()
        c.digit(1); c.setOp(.add); c.digit(2); c.setOp(.add)
        #expect(c.display == "3", "After '1 + 2 +', display shows running result 3")
        c.backspace()
        #expect(c.display == "2", "After backspace removes trailing '+', display reverts to last operand 2")
    }
}
