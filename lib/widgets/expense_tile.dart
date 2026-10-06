import 'package:flutter/material.dart';
import '../category_ui.dart';
import '../expense.dart';
import '../money.dart';

/// One transaction row. Falls back to the category name as the title
/// when there's no note, so a row is never blank.
class ExpenseTile extends StatelessWidget {
  final Expense expense;

  const ExpenseTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(expense.at).format(context);
    final hasNote = expense.note.isNotEmpty;

    return ListTile(
      leading: CircleAvatar(child: Icon(expense.category.icon, size: 20)),
      title: Text(hasNote ? expense.note : expense.category.label),
      subtitle: Text(hasNote ? '${expense.category.label} · $time' : time),
      trailing: Text(
        formatMoney(expense.amountPaise),
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
