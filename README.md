# Daily Budget

A small Flutter app that turns a monthly spending budget into a single
number: how much is left to spend today.

Rather than showing a month-long total that feels like a lot of money on
the 3rd and not enough on the 28th, the app divides what's left of the
budget across the days remaining in the month, and re-derives that figure
every day. Underspend today and tomorrow's allowance rises; overspend and
it falls.

## Scope

This tracks **day-to-day discretionary spending only** — food, groceries,
transport, shopping, and similar. Rent, EMIs, insurance premiums and
subscriptions are deliberately left out, so the monthly budget you enter
should be your spending money, not your whole outgoings. Mixing fixed
commitments in will inflate the daily allowance badly.

## How the allowance works

```
allowance(today) = (monthlyBudget − spentEarlierThisMonth) ÷ daysLeftInMonth
```

Today's own spending is excluded from `spentEarlierThisMonth`, which is
what lets the number count down through the day instead of resetting. On
the 1st of a new month the previous month's expenses drop out of the
filter, so the budget carries over without any manual reset.

## Features

- One-tap expense entry via a bottom sheet: amount, category, optional note
- Daily allowance with month-level context underneath
- Scrollable history grouped by day, with per-day totals
- Swipe to delete with a timed undo
- Monthly budget behind a settings screen, since it's set once, not daily

## Project layout

```
lib/
  main.dart               app root
  home_screen.dart        dashboard, history list, state
  settings_screen.dart    monthly budget + debug tools
  add_expense_sheet.dart  the add-expense modal
  budget_logic.dart       pure date + money maths (no Flutter imports)
  expense.dart            Expense model + categories (no Flutter imports)
  budget_storage.dart     shared_preferences persistence
  category_ui.dart        category → icon mapping
  demo_data.dart          sample data generator (debug only)
  widgets/                presentational widgets
test/
  budget_logic_test.dart  unit tests for the maths
```

`budget_logic.dart` and `expense.dart` intentionally import nothing from
Flutter, so the maths is testable without a widget binding — which is why
the test suite runs fast and covers month boundaries, leap years and
grouping edge cases.

## Running

```bash
flutter pub get
flutter run
flutter test
flutter analyze
```

To try the history view without a month of real data, open Settings and
tap **Load ~50 days of sample data**. That section only appears in debug
builds; `demo_data.dart` can be deleted once it's no longer useful.

## Known gaps

- No editing an expense — delete and re-add instead
- No category breakdown or charts yet
- Expenses live in a single `shared_preferences` JSON blob, rewritten on
  every save; fine at this scale, would want SQLite after a year or so
- Large one-off purchases (a flight, a laptop) have no good home yet —
  they distort a daily allowance, and sinking funds aren't implemented
