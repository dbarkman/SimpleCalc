# SimpleCalc Manual Test Checklist

Run against the installed app (`/Applications/SimpleCalc.app`). Each row gives the input and
the expected main display; "expr" is the small expression line under it. Press **Esc** (or
AC) before each row. Keys in `code` are typed on the keyboard; buttons are named in **bold**.

## 1. Launch and window

| # | Step | Expected |
|---|---|---|
| 1.1 | Launch the app | Window titled SimpleCalc, display shows `0`, glass buttons in a 4×5 grid |
| 1.2 | Try to resize the window | Size is fixed to the content |
| 1.3 | File menu | No "New Window" item |
| 1.4 | Type `5` immediately after launch, without clicking | Display shows `5` (window has keyboard focus) |

## 2. Arithmetic

| # | Input | Expected display |
|---|---|---|
| 2.1 | `2+3=` | `5` |
| 2.2 | `9-4=` | `5` |
| 2.3 | `6*7=` and `6x7=` | `42` both times |
| 2.4 | `8/2=` | `4` |
| 2.5 | `5/0=` | `Error` |
| 2.6 | `3-8=` | `-5` |
| 2.7 | `2+3*4=` (precedence) | `14` |
| 2.8 | `10-3-2=` / `100/10/5=` | `5` / `2` |
| 2.9 | `1+24+8=` | `33` |
| 2.10 | `0.1+0.2=` | `0.3` |
| 2.11 | `.5+.5=` | `1` |
| 2.12 | `1..2` | `1.2` (second dot ignored) |
| 2.13 | `5+-3=` (operator replaced) | `2` |
| 2.14 | `+5` (operator first) | `5` |
| 2.15 | `2+3==` | `5` (second = does nothing) |
| 2.16 | `2+3=*2=` (continue from result) | `10` |
| 2.17 | `2+3=7` (digit after result) | `7`, expr `7` |
| 2.18 | Type 16 digits `1234567890123456` | `123,456,789,012,345` (15-digit cap) |
| 2.19 | `1234567` | `1,234,567` |
| 2.20 | Click every button 0–9, `.`, `+ − × ÷ =` once each | Each behaves like its key |

## 3. Live result and expression line

| # | Input | Expected |
|---|---|---|
| 3.1 | `5+3` (no =) | display `8`, expr `5 + 3` |
| 3.2 | `2+3*4` | display `14`, expr `2 + 3 × 4` |
| 3.3 | `5+` | display `5`, expr `5 +` |
| 3.4 | `5+3=` | display `8`, expr empty |

## 4. Parentheses

| # | Input | Expected display |
|---|---|---|
| 4.1 | `(2+3)*4=` | `20`, expr before = shows `(2 + 3) × 4` |
| 4.2 | `2(3)=` (implicit ×) | `6` |
| 4.3 | `(2)(3)=` | `6` |
| 4.4 | `((2+3)*(4-1))=` | `15` |
| 4.5 | `(2+3=` (never closed) | `5` |
| 4.6 | `2+3)=` (extra close) | `5` (unmatched `)` is ignored) |
| 4.7 | `(2+)3)=` | `5` (`)` right after an operator is ignored) |

## 5. Negate (± / `n`)

| # | Input | Expected display |
|---|---|---|
| 5.1 | `5n` | `-5` |
| 5.2 | `5nn` | `5` |
| 5.3 | `5+3=n` | `-8` |
| 5.4 | `0n5` | `-5` |
| 5.5 | `10+5n=` | `5` |
| 5.6 | Click **±** | Same as `n` |

## 6. Percent (% / `p`)

| # | Input | Expected display |
|---|---|---|
| 6.1 | `50%` | `0.5` |
| 6.2 | `200+10%=` | `220` |
| 6.3 | `200-10%=` | `180` |
| 6.4 | `200*10%=` | `20` |
| 6.5 | `200/10%=` | `2,000` |
| 6.6 | `100+100=%` | `2` |

## 7. Backspace, clear, rounding shortcut

| # | Input | Expected display |
|---|---|---|
| 7.1 | `123` Delete | `12` |
| 7.2 | `123` Delete ×3 | `0` |
| 7.3 | `12+` Delete | `12`, expr `12` |
| 7.4 | `5+3=` Delete | `0` (an integer result is cleared) |
| 7.5 | `10/3=` Delete | `≈ 3.33` (fractional result rounds to 2 places) |
| 7.6 | `10/3=` Delete Delete | `0` |
| 7.7 | Click **⌫** | Same as Delete |
| 7.8 | Forward-delete key | Same as Delete |
| 7.9 | `12+3` Esc / **AC** / ⌘Delete | `0`, expr empty (each one) |

## 8. Error recovery

| # | Input | Expected display |
|---|---|---|
| 8.1 | `5/0=7` | `7` |
| 8.2 | `5/0=+` | `Error` (operators are ignored on Error) |
| 8.3 | `5/0=+1=` | `1` (the digit starts fresh) |

## 9. Settings (gear button)

| # | Step | Expected |
|---|---|---|
| 9.1 | Click gear | Popover with Decimal Places picker (Unlimited, 0–10) |
| 9.2 | Places = 2, `1/3=` | `≈ 0.33` |
| 9.3 | Places = 2, `1/4=` | `0.25` |
| 9.4 | Places = 2, `2*3=` | `6.00` |
| 9.5 | Places = 0, `7/2=` | `≈ 4` |
| 9.6 | Quit and relaunch | Decimal Places choice is kept |
| 9.7 | Set back to Unlimited, `10/3=` | `3.33333333333333` |

## 10. Copy (⌘C)

| # | Step | Expected clipboard (paste into TextEdit to check) |
|---|---|---|
| 10.1 | `10/3=` ⌘C | `3.33333333333333` |
| 10.2 | `1234567` ⌘C | `1234567` (no commas) |
| 10.3 | `5+3` ⌘C (no =) | `8` (the live result) |
| 10.4 | Places = 2, `10/3=` ⌘C | `3.33` (no `≈`) |
| 10.5 | `-1234` ⌘C | `-1234` |
| 10.6 | Edit menu → Copy | Copies the display, same as ⌘C — check whether it is greyed out |

## 11. Paste (⌘V)

Copy the "Clipboard" text from TextEdit first.

| # | Display before | Clipboard | Then type | Expected display |
|---|---|---|---|---|
| 11.1 | — | `42` | | `42` |
| 11.2 | — | `1,234.5` | | `1,234.5` |
| 11.3 | — | `-3.5` | | `-3.5` |
| 11.4 | — | ` 7 ` + newline | | `7` |
| 11.5 | `9` | `abc` | | `9` (ignored) |
| 11.6 | — | `12` | `+3=` | `15` |
| 11.7 | `12+` | `3` | `=` | `15` (paste keeps the pending expression) |
| 11.8 | — | `12345678901234567` | | `12,345,678,901,234,600` (rounded to 15 significant digits) |
| 11.9 | — | `1e5` | | `100,000` |
| 11.10 | `9` | `nan` | | `9` (ignored) |
| 11.11 | `9` | `$5.00` | | `5.00` |
| 11.12 | `9` | `(2+3)` | | `9` (expressions are not pasted) |
| 11.13 | `(2+3)` | `4` | `=` | `20` (implicit ×) |
| 11.14 | `5+3=` | `2` | `+1=` | `3` (paste after a result starts fresh) |
| 11.15 | — | `-.5` | | `-0.5` |
| 11.16 | Edit menu → Paste | | | Same as ⌘V — check whether it is greyed out |

## 12. Keyboard focus around text fields

| # | Step | Expected |
|---|---|---|
| 12.1 | Open History, type `rent` in Search, then click a calculator digit button and type `5` | Typed `5` reaches the calculator |
| 12.2 | In Search, type `12` then press Delete | Deletes from the search text, not the calculator |
| 12.3 | Edit a note, type text, press Return | Note behaves sensibly; the calculator does not run `=` |
| 12.4 | In Search, ⌘C / ⌘V | Copies/pastes text in the search field, not the display |

## 13. History panel (clock button)

| # | Step | Expected |
|---|---|---|
| 13.1 | Click clock | Panel slides in from the right; icon fills |
| 13.2 | `2+3=`, `7=`, `1234*2=` | Two new entries (bare `7=` is not recorded); newest on top: `1,234 × 2` / `2,468` |
| 13.3 | Entries grouped by day | Header shows weekday + date and `Σ` subtotal of results |
| 13.4 | Click an entry's star | Star fills yellow |
| 13.5 | Header star button | Shows favorites only; click again to show all |
| 13.6 | Pencil → type `rent, split` → Save | Note shows under the entry |
| 13.7 | Pencil → Cancel | Note unchanged |
| 13.8 | Search `rent` / `2,468` / `1,234` | Matches note / result / expression; clear (x) restores the list |
| 13.9 | Search `zzz` | "No matches" |
| 13.10 | Double-click an entry | Display shows `2,468`, expr line shows `1,234 × 2`; `=` keeps `2,468` |
| 13.11 | Calendar → Last 7 days | Calendar icon gets a checkmark; only recent entries shown |
| 13.12 | Calendar → toggle off | All entries return |
| 13.13 | ⋯ → Export CSV… → save | CSV has header `Date,Expression,Result,Favorite,Note`; the note `rent, split` is quoted |
| 13.14 | ⋯ → Export PDF… → save | PDF titled "SimpleCalc History" lists the filtered entries, stars, notes |
| 13.15 | Quit and relaunch | History, favorites, and notes persist |
| 13.16 | ⋯ → Clear History… → Cancel | Nothing removed |
| 13.17 | ⋯ → Clear History… → Clear | "No history"; Clear History is greyed out afterwards |

## 14. Known limits (not bugs)

- Results beyond ~15–16 significant digits lose precision (`99999999*99999999` shows
  `9,999,999,800,000,000`).
- In Unlimited mode, results are cut to 15 significant digits without `≈`.
