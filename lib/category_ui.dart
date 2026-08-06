import 'package:flutter/material.dart';
import 'expense.dart';

/// Visual mapping for categories. Kept out of expense.dart so the model
/// stays Flutter-free and unit testable.
extension ExpenseCategoryUi on ExpenseCategory {
  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.groceries:
        return Icons.local_grocery_store;
      case ExpenseCategory.transport:
        return Icons.directions_bus;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.bills:
        return Icons.receipt_long;
      case ExpenseCategory.health:
        return Icons.local_hospital;
      case ExpenseCategory.fun:
        return Icons.local_activity;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }
}
