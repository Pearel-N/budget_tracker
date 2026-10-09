import 'package:flutter/material.dart';
import '../money.dart';

/// The dashboard hero: what's left to spend today, with month-level
/// context underneath.
///
/// Everything here is derived from the three raw numbers passed in, so
/// there's no way for the label and the figure to disagree.
class BudgetSummary extends StatelessWidget {
  final int allowancePaise;
  final int spentTodayPaise;
  final int monthlyBudgetPaise;
  final int spentThisMonthPaise;
  final int daysLeftInMonth;
  final VoidCallback onSetBudget;

  const BudgetSummary({
    super.key,
    required this.allowancePaise,
    required this.spentTodayPaise,
    required this.monthlyBudgetPaise,
    required this.spentThisMonthPaise,
    required this.daysLeftInMonth,
    required this.onSetBudget,
  });

  int get _remainingPaise => allowancePaise - spentTodayPaise;

  bool get _overBudget => _remainingPaise < 0;

  /// Month-level context. Deliberately small and secondary — the daily
  /// number stays the thing you act on, this is just here so the daily
  /// number is auditable and a bad month is visible before the last day.
  String get _monthLine {
    final spent = formatMoney(spentThisMonthPaise);
    final budget = formatMoney(monthlyBudgetPaise);
    final left = monthlyBudgetPaise - spentThisMonthPaise;

    if (left < 0) {
      return '$spent of $budget spent this month · '
          '${formatMoney(left.abs())} over';
    }

    final dayWord = daysLeftInMonth == 1 ? 'day' : 'days';
    return '$spent of $budget spent this month · '
        '${formatMoney(left)} left for $daysLeftInMonth $dayWord';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (monthlyBudgetPaise <= 0) {
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
        // The hero figure has to stay on one line to read as one number,
        // so at large accessibility text sizes it shrinks to fit instead
        // of wrapping mid-amount or running off the edge.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatMoney(_remainingPaise.abs()),
            maxLines: 1,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _overBudget
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'of ${formatMoney(allowancePaise)} for today',
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
