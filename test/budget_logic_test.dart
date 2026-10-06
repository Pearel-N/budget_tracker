import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/budget_logic.dart';
import 'package:budget_tracker/expense.dart';
import 'package:budget_tracker/money.dart';

/// Amounts are written in rupees here because that is how they read; the
/// model stores paise, so expectations below are in paise.
Expense _expense(
  DateTime at,
  num rupees, {
  ExpenseCategory category = ExpenseCategory.other,
  String note = '',
}) {
  return Expense(
    id: '${at.microsecondsSinceEpoch}-$rupees',
    at: at,
    amountPaise: (rupees * paisePerRupee).round(),
    category: category,
    note: note,
  );
}

void main() {
  group('daysInMonth', () {
    test('handles 31-day months', () {
      expect(daysInMonth(DateTime(2026, 8, 15)), 31);
    });

    test('handles 30-day months', () {
      expect(daysInMonth(DateTime(2026, 4, 15)), 30);
    });

    test('handles February in a leap year', () {
      expect(daysInMonth(DateTime(2024, 2, 15)), 29);
    });

    test('handles February in a non-leap year', () {
      expect(daysInMonth(DateTime(2026, 2, 15)), 28);
    });

    test('handles December without rolling the year wrong', () {
      expect(daysInMonth(DateTime(2026, 12, 10)), 31);
    });
  });

  group('daysRemainingIn', () {
    test('includes today', () {
      expect(daysRemainingIn(DateTime(2026, 8, 31)), 1);
    });

    test('counts the whole month on the first', () {
      expect(daysRemainingIn(DateTime(2026, 8, 1)), 31);
    });
  });

  group('allowanceFor', () {
    test('splits evenly when nothing has been spent', () {
      final result = allowanceFor(
        monthlyBudgetPaise: 3100000,
        entries: [],
        day: DateTime(2026, 8, 1),
      );
      expect(result, 100000);
    });

    test('reduces the allowance after overspending', () {
      final result = allowanceFor(
        monthlyBudgetPaise: 3100000,
        entries: [DailyEntry(date: DateTime(2026, 8, 1), spentPaise: 300000)],
        day: DateTime(2026, 8, 2),
      );
      // 28000 left across 30 days
      expect(result, 93333);
    });

    test('raises the allowance after underspending', () {
      final result = allowanceFor(
        monthlyBudgetPaise: 3100000,
        entries: [DailyEntry(date: DateTime(2026, 8, 1), spentPaise: 0)],
        day: DateTime(2026, 8, 2),
      );
      // 31000 left across 30 days
      expect(result, 103333);
    });

    test("ignores today's own spending", () {
      final result = allowanceFor(
        monthlyBudgetPaise: 3100000,
        entries: [DailyEntry(date: DateTime(2026, 8, 1), spentPaise: 50000)],
        day: DateTime(2026, 8, 1),
      );
      expect(result, 100000);
    });

    test('ignores spending from a previous month', () {
      final result = allowanceFor(
        monthlyBudgetPaise: 3100000,
        entries: [DailyEntry(date: DateTime(2026, 7, 15), spentPaise: 999900)],
        day: DateTime(2026, 8, 1),
      );
      expect(result, 100000);
    });
  });

  group('aggregateByDay', () {
    test('returns nothing for an empty list', () {
      expect(aggregateByDay([]), isEmpty);
    });

    test('sums several expenses on the same day into one entry', () {
      final entries = aggregateByDay([
        _expense(DateTime(2026, 8, 1, 9), 100),
        _expense(DateTime(2026, 8, 1, 13), 250),
        _expense(DateTime(2026, 8, 1, 21), 50),
      ]);

      expect(entries, hasLength(1));
      expect(entries.first.date, DateTime(2026, 8, 1));
      expect(entries.first.spentPaise, 40000);
    });

    test('keeps separate days separate and sorts oldest first', () {
      final entries = aggregateByDay([
        _expense(DateTime(2026, 8, 3, 10), 300),
        _expense(DateTime(2026, 8, 1, 10), 100),
        _expense(DateTime(2026, 8, 2, 10), 200),
      ]);

      expect(entries.map((e) => e.date), [
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 2),
        DateTime(2026, 8, 3),
      ]);
      expect(entries.map((e) => e.spentPaise), [10000, 20000, 30000]);
    });

    test('ignores the time of day when grouping', () {
      final entries = aggregateByDay([
        _expense(DateTime(2026, 8, 1, 0, 0, 1), 10),
        _expense(DateTime(2026, 8, 1, 23, 59, 59), 10),
      ]);

      expect(entries, hasLength(1));
      expect(entries.first.spentPaise, 2000);
    });

    test('feeds allowanceFor the same way the old model did', () {
      final expenses = [
        _expense(DateTime(2026, 8, 1, 9), 1000),
        _expense(DateTime(2026, 8, 1, 18), 2000),
      ];

      final result = allowanceFor(
        monthlyBudgetPaise: 3100000,
        entries: aggregateByDay(expenses),
        day: DateTime(2026, 8, 2),
      );

      // 3000 spent yesterday -> 28000 left across 30 days
      expect(result, 93333);
    });
  });

  group('spentOn', () {
    test('totals only the requested day', () {
      final expenses = [
        _expense(DateTime(2026, 8, 1, 9), 100),
        _expense(DateTime(2026, 8, 2, 9), 500),
        _expense(DateTime(2026, 8, 2, 20), 250),
      ];

      expect(spentOn(expenses, DateTime(2026, 8, 2, 14)), 75000);
    });

    test('returns zero for a day with no expenses', () {
      expect(spentOn([], DateTime(2026, 8, 2)), 0);
    });
  });

  group('groupByDayDescending', () {
    test('returns nothing for an empty list', () {
      expect(groupByDayDescending([]), isEmpty);
    });

    test('puts the newest day first', () {
      final groups = groupByDayDescending([
        _expense(DateTime(2026, 8, 1, 10), 100),
        _expense(DateTime(2026, 8, 3, 10), 300),
        _expense(DateTime(2026, 8, 2, 10), 200),
      ]);

      expect(groups.map((g) => g.date), [
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 2),
        DateTime(2026, 8, 1),
      ]);
    });

    test('orders expenses within a day newest first', () {
      final groups = groupByDayDescending([
        _expense(DateTime(2026, 8, 2, 9), 100),
        _expense(DateTime(2026, 8, 2, 20), 200),
        _expense(DateTime(2026, 8, 2, 14), 150),
      ]);

      expect(
        groups.single.expenses.map((e) => e.amountPaise),
        [20000, 15000, 10000],
      );
    });

    test('totals each day', () {
      final groups = groupByDayDescending([
        _expense(DateTime(2026, 8, 2, 9), 100),
        _expense(DateTime(2026, 8, 2, 20), 250),
        _expense(DateTime(2026, 8, 1, 9), 400),
      ]);

      expect(groups[0].totalPaise, 35000);
      expect(groups[1].totalPaise, 40000);
    });

    test('spans months and years without regrouping wrongly', () {
      final groups = groupByDayDescending([
        _expense(DateTime(2025, 12, 31, 10), 100),
        _expense(DateTime(2026, 1, 1, 10), 200),
      ]);

      expect(groups.map((g) => g.date), [
        DateTime(2026, 1, 1),
        DateTime(2025, 12, 31),
      ]);
    });

    test('keeps every expense — none dropped or duplicated', () {
      final expenses = [
        _expense(DateTime(2026, 8, 1, 9), 10),
        _expense(DateTime(2026, 8, 1, 10), 20),
        _expense(DateTime(2026, 8, 2, 9), 30),
        _expense(DateTime(2026, 8, 4, 9), 40),
      ];

      final groups = groupByDayDescending(expenses);
      final flattened = groups.expand((g) => g.expenses).toList();

      expect(flattened, hasLength(expenses.length));
      expect(groups.fold<int>(0, (sum, g) => sum + g.totalPaise), 10000);
    });
  });

  group('spentInMonth', () {
    test('totals every day in the month, today included', () {
      final expenses = [
        _expense(DateTime(2026, 8, 1, 9), 100),
        _expense(DateTime(2026, 8, 15, 9), 500),
        _expense(DateTime(2026, 8, 31, 20), 250),
      ];

      expect(spentInMonth(expenses, DateTime(2026, 8, 15)), 85000);
    });

    test('ignores other months', () {
      final expenses = [
        _expense(DateTime(2026, 7, 31, 23), 9999),
        _expense(DateTime(2026, 8, 2, 9), 300),
        _expense(DateTime(2026, 9, 1, 1), 9999),
      ];

      expect(spentInMonth(expenses, DateTime(2026, 8, 2)), 30000);
    });

    test('ignores the same month in a different year', () {
      final expenses = [
        _expense(DateTime(2025, 8, 10), 9999),
        _expense(DateTime(2026, 8, 10), 400),
      ];

      expect(spentInMonth(expenses, DateTime(2026, 8, 10)), 40000);
    });

    test('returns zero when nothing was spent', () {
      expect(spentInMonth([], DateTime(2026, 8, 10)), 0);
    });
  });

  group('Expense JSON', () {
    test('round-trips without losing anything', () {
      final original = _expense(
        DateTime(2026, 8, 2, 14, 30),
        249.5,
        category: ExpenseCategory.food,
        note: 'Lunch',
      );

      final restored = Expense.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.at, original.at);
      expect(restored.amountPaise, 24950);
      expect(restored.amountPaise, original.amountPaise);
      expect(restored.category, ExpenseCategory.food);
      expect(restored.note, 'Lunch');
    });

    test('falls back to other for an unknown category', () {
      final json = {
        'id': 'x',
        'at': DateTime(2026, 8, 2).toIso8601String(),
        'amountPaise': 1000,
        'category': 'crypto_jetski',
        'note': '',
      };

      expect(Expense.fromJson(json).category, ExpenseCategory.other);
    });

    test('tolerates a missing note', () {
      final json = {
        'id': 'x',
        'at': DateTime(2026, 8, 2).toIso8601String(),
        'amountPaise': 1000,
        'category': 'food',
      };

      expect(Expense.fromJson(json).note, '');
    });

    test('reads a pre-paise rupee amount and converts it', () {
      final json = {
        'id': 'x',
        'at': DateTime(2026, 8, 2).toIso8601String(),
        'amount': 249.5,
        'category': 'food',
        'note': '',
      };

      expect(Expense.fromJson(json).amountPaise, 24950);
    });

    test('prefers the paise field when a row carries both', () {
      final json = {
        'id': 'x',
        'at': DateTime(2026, 8, 2).toIso8601String(),
        'amount': 1,
        'amountPaise': 24950,
        'category': 'food',
        'note': '',
      };

      expect(Expense.fromJson(json).amountPaise, 24950);
    });

    test('throws when a row has no amount at all', () {
      final json = {
        'id': 'x',
        'at': DateTime(2026, 8, 2).toIso8601String(),
        'category': 'food',
        'note': '',
      };

      // BudgetStorage.loadExpenses turns this into a reported load failure.
      expect(() => Expense.fromJson(json), throwsA(isA<FormatException>()));
    });
  });
}
