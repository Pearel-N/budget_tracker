// Pure Dart, no Flutter imports — same rule as budget_logic.dart, so this
// model can be used by the logic layer and unit tested without a widget
// binding. Anything visual (icons, colours) lives in category_ui.dart.

import 'money.dart';

enum ExpenseCategory {
  food('Food'),
  groceries('Groceries'),
  transport('Transport'),
  shopping('Shopping'),
  bills('Bills'),
  health('Health'),
  fun('Fun'),
  other('Other');

  const ExpenseCategory(this.label);

  final String label;

  /// Tolerant lookup so a renamed or unknown category in stored JSON
  /// degrades to `other` instead of throwing on load.
  static ExpenseCategory fromName(String? name) {
    return values.firstWhere(
      (c) => c.name == name,
      orElse: () => ExpenseCategory.other,
    );
  }
}

/// A single transaction. Daily totals are derived from these, never
/// stored — see groupByDayDescending in budget_logic.dart.
class Expense {
  final String id;
  final DateTime at;

  /// Whole paise, never rupees — see money.dart for why.
  final int amountPaise;

  final ExpenseCategory category;
  final String note;

  const Expense({
    required this.id,
    required this.at,
    required this.amountPaise,
    required this.category,
    this.note = '',
  });

  /// Midnight of the day this expense belongs to.
  DateTime get day => DateTime(at.year, at.month, at.day);

  Map<String, dynamic> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'amountPaise': amountPaise,
    'category': category.name,
    'note': note,
  };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      at: DateTime.parse(json['at'] as String),
      amountPaise: _amountPaiseFromJson(json),
      category: ExpenseCategory.fromName(json['category'] as String?),
      note: (json['note'] as String?) ?? '',
    );
  }

  /// Reads either shape of stored amount, which is the whole migration for
  /// data written before the move to paise: those rows carry a rupee
  /// `amount` as a JSON number and are converted on the way in, then saved
  /// back out as `amountPaise` the next time anything is written. Converting
  /// per row rather than in one upfront pass means a list that is only
  /// half-rewritten still loads.
  ///
  /// Throws when neither field is usable, same as the old direct cast did —
  /// BudgetStorage turns that into a reported load failure rather than a
  /// crash.
  static int _amountPaiseFromJson(Map<String, dynamic> json) {
    final paise = json['amountPaise'];
    if (paise is num) return paise.round();

    final rupees = json['amount'];
    if (rupees is num) return (rupees * paisePerRupee).round();

    throw FormatException('Expense JSON has no usable amount: $json');
  }

  /// Good enough for a local-only app: unique per microsecond, no extra
  /// dependency. Swap for a real UUID if this ever syncs to a server.
  static String newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}
