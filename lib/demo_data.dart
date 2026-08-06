import 'dart:math';
import 'expense.dart';

/// Sample data for testing the history view. Seeded so every run produces
/// the same set, and only ever reachable from the debug-only section of
/// the settings screen — delete this file once you're done with it.
List<Expense> generateDemoExpenses({DateTime? now, int daysBack = 50}) {
  final today = now ?? DateTime.now();
  final anchor = DateTime(today.year, today.month, today.day);
  final random = Random(20260806);
  final expenses = <Expense>[];

  for (var offset = 0; offset <= daysBack; offset++) {
    final day = anchor.subtract(Duration(days: offset));

    // Roughly one day in seven with nothing logged, so the history has
    // gaps in it the way real usage would.
    if (offset > 0 && random.nextInt(7) == 0) continue;

    final count = 2 + random.nextInt(4);

    for (var i = 0; i < count; i++) {
      final sample = _samples[random.nextInt(_samples.length)];
      final spread = sample.max - sample.min;
      final amount = (sample.min + random.nextInt(spread + 1)).toDouble();

      // Spread entries across waking hours so ordering within a day
      // looks believable.
      final at = DateTime(
        day.year,
        day.month,
        day.day,
        8 + random.nextInt(14),
        random.nextInt(60),
      );

      expenses.add(Expense(
        id: 'demo-$offset-$i',
        at: at,
        amount: amount,
        category: sample.category,
        note: sample.note,
      ));
    }
  }

  return expenses;
}

class _Sample {
  final ExpenseCategory category;
  final String note;
  final int min;
  final int max;

  const _Sample(this.category, this.note, this.min, this.max);
}

const _samples = <_Sample>[
  _Sample(ExpenseCategory.food, 'Lunch', 120, 380),
  _Sample(ExpenseCategory.food, 'Coffee', 60, 220),
  _Sample(ExpenseCategory.food, 'Dinner out', 400, 1200),
  _Sample(ExpenseCategory.food, 'Breakfast', 80, 200),
  _Sample(ExpenseCategory.food, 'Snacks', 40, 150),
  _Sample(ExpenseCategory.groceries, 'Vegetables', 150, 500),
  _Sample(ExpenseCategory.groceries, 'Supermarket run', 600, 2200),
  _Sample(ExpenseCategory.groceries, 'Milk and eggs', 60, 180),
  _Sample(ExpenseCategory.transport, 'Auto', 40, 160),
  _Sample(ExpenseCategory.transport, 'Cab', 120, 480),
  _Sample(ExpenseCategory.transport, 'Metro', 20, 90),
  _Sample(ExpenseCategory.transport, 'Petrol', 500, 1800),
  _Sample(ExpenseCategory.shopping, 'T-shirt', 400, 1500),
  _Sample(ExpenseCategory.shopping, 'Shoes', 1500, 4000),
  _Sample(ExpenseCategory.shopping, 'Phone case', 200, 900),
  _Sample(ExpenseCategory.bills, 'Phone recharge', 200, 800),
  _Sample(ExpenseCategory.health, 'Pharmacy', 100, 700),
  _Sample(ExpenseCategory.health, 'Doctor visit', 500, 1500),
  _Sample(ExpenseCategory.fun, 'Movie', 200, 800),
  _Sample(ExpenseCategory.fun, 'Concert ticket', 800, 3000),
  _Sample(ExpenseCategory.fun, 'Bowling', 300, 900),
  _Sample(ExpenseCategory.other, 'Gift', 300, 2000),
  _Sample(ExpenseCategory.other, '', 50, 400),
];
