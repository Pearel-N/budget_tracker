import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/budget_logic.dart';
import 'package:budget_tracker/expense.dart';

Expense _expense(
  DateTime at,
  double amount, {
  ExpenseCategory category = ExpenseCategory.other,
  String note = '',
}) {
  return Expense(
    id: '${at.microsecondsSinceEpoch}-$amount',
    at: at,
    amount: amount,
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
        monthlyBudget: 31000,
        entries: [],
        day: DateTime(2026, 8, 1),
      );
      expect(result, closeTo(1000, 0.01));
    });

    test('reduces the allowance after overspending', () {
      final result = allowanceFor(
        monthlyBudget: 31000,
        entries: [DailyEntry(date: DateTime(2026, 8, 1), spent: 3000)],
        day: DateTime(2026, 8, 2),
      );
      // 28000 left across 30 days
      expect(result, closeTo(933.33, 0.01));
    });

    test('raises the allowance after underspending', () {
      final result = allowanceFor(
        monthlyBudget: 31000,
        entries: [DailyEntry(date: DateTime(2026, 8, 1), spent: 0)],
        day: DateTime(2026, 8, 2),
      );
      // 31000 left across 30 days
      expect(result, closeTo(1033.33, 0.01));
    });

    test("ignores today's own spending", () {
      final result = allowanceFor(
        monthlyBudget: 31000,
        entries: [DailyEntry(date: DateTime(2026, 8, 1), spent: 500)],
        day: DateTime(2026, 8, 1),
      );
      expect(result, closeTo(1000, 0.01));
    });

    test('ignores spending from a previous month', () {
      final result = allowanceFor(
        monthlyBudget: 31000,
        entries: [DailyEntry(date: DateTime(2026, 7, 15), spent: 9999)],
        day: DateTime(2026, 8, 1),
      );
      expect(result, closeTo(1000, 0.01));
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
      expect(entries.first.spent, closeTo(400, 0.01));
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
      expect(entries.map((e) => e.spent), [100, 200, 300]);
    });

    test('ignores the time of day when grouping', () {
      final entries = aggregateByDay([
        _expense(DateTime(2026, 8, 1, 0, 0, 1), 10),
        _expense(DateTime(2026, 8, 1, 23, 59, 59), 10),
      ]);

      expect(entries, hasLength(1));
      expect(entries.first.spent, closeTo(20, 0.01));
    });

    test('feeds allowanceFor the same way the old model did', () {
      final expenses = [
        _expense(DateTime(2026, 8, 1, 9), 1000),
        _expense(DateTime(2026, 8, 1, 18), 2000),
      ];

      final result = allowanceFor(
        monthlyBudget: 31000,
        entries: aggregateByDay(expenses),
        day: DateTime(2026, 8, 2),
      );

      // 3000 spent yesterday -> 28000 left across 30 days
      expect(result, closeTo(933.33, 0.01));
    });
  });

  group('spentOn', () {
    test('totals only the requested day', () {
      final expenses = [
        _expense(DateTime(2026, 8, 1, 9), 100),
        _expense(DateTime(2026, 8, 2, 9), 500),
        _expense(DateTime(2026, 8, 2, 20), 250),
      ];

      expect(spentOn(expenses, DateTime(2026, 8, 2, 14)), closeTo(750, 0.01));
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

      expect(groups.single.expenses.map((e) => e.amount), [200, 150, 100]);
    });

    test('totals each day', () {
      final groups = groupByDayDescending([
        _expense(DateTime(2026, 8, 2, 9), 100),
        _expense(DateTime(2026, 8, 2, 20), 250),
        _expense(DateTime(2026, 8, 1, 9), 400),
      ]);

      expect(groups[0].total, closeTo(350, 0.01));
      expect(groups[1].total, closeTo(400, 0.01));
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
      expect(
        groups.fold<double>(0, (sum, g) => sum + g.total),
        closeTo(100, 0.01),
      );
    });
  });

  group('spentInMonth', () {
    test('totals every day in the month, today included', () {
      final expenses = [
        _expense(DateTime(2026, 8, 1, 9), 100),
        _expense(DateTime(2026, 8, 15, 9), 500),
        _expense(DateTime(2026, 8, 31, 20), 250),
      ];

      expect(spentInMonth(expenses, DateTime(2026, 8, 15)),
          closeTo(850, 0.01));
    });

    test('ignores other months', () {
      final expenses = [
        _expense(DateTime(2026, 7, 31, 23), 9999),
        _expense(DateTime(2026, 8, 2, 9), 300),
        _expense(DateTime(2026, 9, 1, 1), 9999),
      ];

      expect(spentInMonth(expenses, DateTime(2026, 8, 2)), closeTo(300, 0.01));
    });

    test('ignores the same month in a different year', () {
      final expenses = [
        _expense(DateTime(2025, 8, 10), 9999),
        _expense(DateTime(2026, 8, 10), 400),
      ];

      expect(spentInMonth(expenses, DateTime(2026, 8, 10)), closeTo(400, 0.01));
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
      expect(restored.amount, original.amount);
      expect(restored.category, ExpenseCategory.food);
      expect(restored.note, 'Lunch');
    });

    test('falls back to other for an unknown category', () {
      final json = {
        'id': 'x',
        'at': DateTime(2026, 8, 2).toIso8601String(),
        'amount': 10,
        'category': 'crypto_jetski',
        'note': '',
      };

      expect(Expense.fromJson(json).category, ExpenseCategory.other);
    });

    test('tolerates a missing note', () {
      final json = {
        'id': 'x',
        'at': DateTime(2026, 8, 2).toIso8601String(),
        'amount': 10,
        'category': 'food',
      };

      expect(Expense.fromJson(json).note, '');
    });
  });
}
