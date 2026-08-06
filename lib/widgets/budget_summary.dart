import 'package:flutter/material.dart';

/// The dashboard hero: what's left to spend today, with month-level
/// context underneath.
///
/// Everything here is derived from the three raw numbers passed in, so
/// there's no way for the label and the figure to disagree.
class BudgetSummary extends StatelessWidget {
  final double allowance;
  final double spentToday;
  final double monthlyBudget;
  final double spentThisMonth;
  final int daysLeftInMonth;
  final VoidCallback onSetBudget;

  const BudgetSummary({
    super.key,
    required this.allowance,
    required this.spentToday,
    required this.monthlyBudget,
    required this.spentThisMonth,
    required this.daysLeftInMonth,
    required this.onSetBudget,
  });

  double get _remaining => allowance - spentToday;

  bool get _overBudget => _remaining < 0;

  /// Month-level context. Deliberately small and secondary — the daily
  /// number stays the thing you act on, this is just here so the daily
  /// number is auditable and a bad month is visible before the last day.
  String get _monthLine {
    final spent = spentThisMonth.toStringAsFixed(0);
    final budget = monthlyBudget.toStringAsFixed(0);
    final left = monthlyBudget - spentThisMonth;

    if (left < 0) {
      return '₹$spent of ₹$budget spent this month · '
          '₹${left.abs().toStringAsFixed(0)} over';
    }

    final dayWord = daysLeftInMonth == 1 ? 'day' : 'days';
    return '₹$spent of ₹$budget spent this month · '
        '₹${left.toStringAsFixed(0)} left for $daysLeftInMonth $dayWord';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (monthlyBudget <= 0) {
      return Column(
        children: [
          Text('No spending budget set', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onSetBudget,
            child: const Text('Set monthly spending money'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _overBudget ? 'Over budget by' : 'Left to spend today',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '₹${_remaining.abs().toStringAsFixed(0)}',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: _overBudget
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'of ₹${allowance.toStringAsFixed(0)} for today',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(
          _monthLine,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
