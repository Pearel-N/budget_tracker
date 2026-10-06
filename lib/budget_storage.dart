import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'expense.dart';
import 'money.dart';

/// Everything that knows *where* data lives goes here. Swapping this
/// for Supabase later means changing this file only.
class BudgetStorage {
  /// Pre-paise key: a double of rupees. Only read now, never written.
  static const _legacyBudgetKey = 'monthly_budget';
  static const _budgetPaiseKey = 'monthly_budget_paise';
  static const _expensesKey = 'expenses';

  /// Falls back to 0 rather than throwing: a stored value of the wrong
  /// type would otherwise take the whole load down with it, and "no budget
  /// set yet" is a state the UI already handles.
  ///
  /// Reads the old rupee key when the paise one isn't there, so an install
  /// from before this change keeps its budget instead of waking up at zero.
  Future<int> loadBudgetPaise() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final paise = prefs.getInt(_budgetPaiseKey);
      if (paise != null) return paise;

      final rupees = prefs.getDouble(_legacyBudgetKey);
      if (rupees == null) return 0;
      return (rupees * paisePerRupee).round();
    } catch (_) {
      return 0;
    }
  }

  Future<void> saveBudgetPaise(int paise) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_budgetPaiseKey, paise);
    // Dropped once the paise value is safely written, so a later load can't
    // pick the stale rupee figure back up.
    await prefs.remove(_legacyBudgetKey);
  }

  /// Never throws. Unreadable stored data is recoverable — starting empty
  /// beats hanging on a spinner forever — but the caller still has to tell
  /// the user, which is why the failure travels back with the data.
  Future<ExpenseLoadResult> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_expensesKey);
      if (raw == null) return const ExpenseLoadResult([]);

      final decoded = jsonDecode(raw) as List;
      return ExpenseLoadResult(
        decoded
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      // Malformed JSON, a changed shape, or a bad field type. The stored
      // string is deliberately left in place so it can still be rescued by
      // hand instead of being overwritten on the next save.
      return const ExpenseLoadResult([], failed: true);
    }
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString(_expensesKey, raw);
  }

  /// Wipes budget and expenses. Used by the debug tools on the settings
  /// screen.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_budgetPaiseKey);
    await prefs.remove(_legacyBudgetKey);
    await prefs.remove(_expensesKey);
  }
}

/// What [BudgetStorage.loadExpenses] gives back. [failed] means the stored
/// data could not be read, not that there was nothing stored — an empty
/// list on a fresh install is a success.
class ExpenseLoadResult {
  final List<Expense> expenses;
  final bool failed;

  const ExpenseLoadResult(this.expenses, {this.failed = false});
}
