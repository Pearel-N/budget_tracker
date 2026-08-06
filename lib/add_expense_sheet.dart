import 'package:flutter/material.dart';
import 'category_ui.dart';
import 'expense.dart';

/// Opens the add-expense sheet and resolves to the new [Expense],
/// or null if the user backed out.
Future<Expense?> showAddExpenseSheet(BuildContext context) {
  return showModalBottomSheet<Expense>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AddExpenseSheet(),
  );
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();

  ExpenseCategory _category = ExpenseCategory.food;

  @override
  void initState() {
    super.initState();
    // Straight to the keypad — this flow should take a couple of seconds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  void _save() {
    if (_amount <= 0) return;

    Navigator.of(context).pop(Expense(
      id: Expense.newId(),
      at: DateTime.now(),
      amount: _amount,
      category: _category,
      note: _noteController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _amount > 0;

    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add expense',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            focusNode: _amountFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'What on?',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategory.values.map((category) {
              return ChoiceChip(
                label: Text(category.label),
                avatar: Icon(category.icon, size: 18),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _noteController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
