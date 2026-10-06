// Pure date + money calculations. No Flutter imports on purpose —
// this file knows nothing about widgets, so it's easy to reason
// about and trivial to unit test later.

import 'expense.dart';

int daysInMonth(DateTime date) {
  final firstOfNextMonth = date.month < 12
      ? DateTime(date.year, date.month + 1, 1)
      : DateTime(date.year + 1, 1, 1);
  return firstOfNextMonth.subtract(const Duration(days: 1)).day;
}

int daysRemainingIn(DateTime date) {
  return daysInMonth(date) - date.day + 1;
}

/// One day's expenses, newest first, alongside that day's total.
class DayGroup {
  final DateTime date;
  final List<Expense> expenses;
  final int totalPaise;

  const DayGroup({
    required this.date,
    required this.expenses,
    required this.totalPaise,
  });
}

/// Groups expenses into day sections, newest day first. Days with no
/// expenses are omitted — the UI decides whether to synthesise an empty
/// section for today.
///
/// This is the only place that knows how to group by day; everything
/// else derives from it.
List<DayGroup> groupByDayDescending(List<Expense> expenses) {
  final byDay = <DateTime, List<Expense>>{};

  for (final expense in expenses) {
    byDay.putIfAbsent(expense.day, () => []).add(expense);
  }

  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

  return days.map((day) {
    final forDay = byDay[day]!..sort((a, b) => b.at.compareTo(a.at));
    return DayGroup(
      date: day,
      expenses: forDay,
      totalPaise: forDay.fold(0, (sum, e) => sum + e.amountPaise),
    );
  }).toList();
}

/// A day's total spend — the only shape [allowanceFor] needs.
class DailyEntry {
  final DateTime date;
  final int spentPaise;

  const DailyEntry({required this.date, required this.spentPaise});
}

/// Daily totals, oldest first. Derived from [groupByDayDescending] rather
/// than grouping a second time.
List<DailyEntry> aggregateByDay(List<Expense> expenses) {
  return groupByDayDescending(expenses)
      .reversed
      .map(
        (group) => DailyEntry(date: group.date, spentPaise: group.totalPaise),
      )
      .toList();
}

/// Total spent on a specific calendar day.
int spentOn(List<Expense> expenses, DateTime day) {
  final target = DateTime(day.year, day.month, day.day);
  return expenses
      .where((e) => e.day == target)
      .fold(0, (sum, e) => sum + e.amountPaise);
}

/// Total spent across the whole calendar month that [month] falls in,
/// today included. Used for the month-level context line.
int spentInMonth(List<Expense> expenses, DateTime month) {
  return expenses
      .where((e) => e.day.year == month.year && e.day.month == month.month)
      .fold(0, (sum, e) => sum + e.amountPaise);
}

int allowanceFor({
  required int monthlyBudgetPaise,
  required List<DailyEntry> entries,
  required DateTime day,
}) {
  final dayStart = DateTime(day.year, day.month, day.day);

  final spentBefore = entries
      .where((e) =>
          e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.isBefore(dayStart))
      .fold(0, (sum, e) => sum + e.spentPaise);

  final remaining = daysRemainingIn(day);
  if (remaining <= 0) return 0;

  // Truncating division: the leftover paise stay unallocated rather than
  // being handed out to every remaining day and overshooting the budget.
  return (monthlyBudgetPaise - spentBefore) ~/ remaining;
}
