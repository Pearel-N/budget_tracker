import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'budget_logic.dart';

/// Monthly budget lives here rather than on the dashboard — it's a
/// set-it-once value, not something you touch daily.
class SettingsScreen extends StatefulWidget {
  final double monthlyBudget;
  final ValueChanged<double> onBudgetChanged;
  final Future<void> Function() onSeedDemoData;
  final Future<void> Function() onClearData;

  const SettingsScreen({
    super.key,
    required this.monthlyBudget,
    required this.onBudgetChanged,
    required this.onSeedDemoData,
    required this.onClearData,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _budgetController;
  late double _budget;

  @override
  void initState() {
    super.initState();
    _budget = widget.monthlyBudget;
    _budgetController = TextEditingController(
      text: _budget == 0 ? '' : _budget.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final amount = double.tryParse(value.trim()) ?? 0;
    setState(() => _budget = amount);
    widget.onBudgetChanged(amount);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final perDay = _budget / daysInMonth(now);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monthly spending money',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              onChanged: _onChanged,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What goes in this number',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Only your day-to-day spending money — food, groceries, '
                    'transport, shopping, and the rest of what you decide on '
                    'as you go.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leave out rent, EMIs, insurance premiums and '
                    'subscriptions. This app does not track those, so if you '
                    'include them here your daily allowance will come out far '
                    'too high.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _budget == 0
                  ? 'Enter an amount to start tracking.'
                  : "That's about ₹${perDay.toStringAsFixed(0)} a day across "
                        '${daysInMonth(now)} days. Your daily allowance '
                        'adjusts up or down as you under- or overspend.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 12),
              Text('Debug tools', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                'Debug builds only — this section disappears in release.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _seed,
                icon: const Icon(Icons.science_outlined),
                label: const Text('Load ~50 days of sample data'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _confirmClear,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Clear all data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _seed() async {
    await widget.onSeedDemoData();
    if (!mounted) return;
    // Straight back to the list so the seeded history is visible.
    Navigator.of(context).pop();
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'Removes your budget and every recorded expense. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await widget.onClearData();
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
