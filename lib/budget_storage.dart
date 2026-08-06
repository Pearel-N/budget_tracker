import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'expense.dart';

/// Everything that knows *where* data lives goes here. Swapping this
/// for Supabase later means changing this file only.
class BudgetStorage {
  static const _budgetKey = 'monthly_budget';
  static const _expensesKey = 'expenses';

  Future<double> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_budgetKey) ?? 0;
  }

  Future<void> saveBudget(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_budgetKey, amount);
  }

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_expensesKey);
    if (raw == null) return [];

    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
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
    await prefs.remove(_budgetKey);
    await prefs.remove(_expensesKey);
  }
}
