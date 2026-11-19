# SimpleCalc

A small calculator for the Mac with glass buttons, built in SwiftUI. It works entirely from
the keyboard, and every button does the same thing as its key.

## What it does

- **Live result.** The display shows the answer as you type, with the expression on a
  small line underneath.
- **Operator precedence and parentheses.** `2+3*4` is `14`, `(2+3)*4` is `20`, and `2(3)`
  multiplies.
- **Forgiving input.** A second decimal point is ignored, a new operator replaces the last
  one, and a result carries into the next calculation.
- **Paste a number** to use it as the current operand.
- **Readable numbers.** Thousands are grouped, and `0.1+0.2` is `0.3`.

## How it's built

`Calculator.swift` holds all of the calculator's logic with no UI, and
`CalculatorTests.swift` covers it with 46 tests. `ContentView.swift` is the window: the
display, the 4×5 button grid and the keyboard handling.

`TESTING.md` is the manual checklist for the installed app.

## Build

Open `SimpleCalc.xcodeproj` in Xcode 26 or later and run the `SimpleCalc` scheme. It needs
macOS 26.
