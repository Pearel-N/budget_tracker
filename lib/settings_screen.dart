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
  late final FocusNode _budgetFocus;

  /// The amount that has actually been saved. Kept apart from [_draft] so a
  /// half-typed or unreadable entry always has something good to fall back
  /// to.
  late double _budget;

  /// What the field parses to right now, for the live "per day" line only.
  /// Null while the text is empty or not a usable amount.
  double? _draft;

  /// Set before the debug tools pop, because they change the budget
  /// themselves — without it the pop-time save would put the now-stale text
  /// still sitting in the field back over what they just did.
  bool _skipCommitOnPop = false;

  @override
  void initState() {
    super.initState();
    _budget = widget.monthlyBudget;
    _draft = _budget == 0 ? null : _budget;
    _budgetController = TextEditingController(
      text: _budget == 0 ? '' : _budget.toStringAsFixed(0),
    );
    _budgetFocus = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _budgetFocus.removeListener(_handleFocusChange);
    _budgetFocus.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  /// Typing only moves the preview. Saving used to happen here too, which
  /// meant entering 30000 stored 3, then 30, then 300, and so on up.
  void _onChanged(String value) {
    setState(() => _draft = _parse(value));
  }

  void _handleFocusChange() {
    if (!_budgetFocus.hasFocus) _commit();
  }

  /// Null for anything that isn't a usable amount: empty, junk, negative.
  double? _parse(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  /// Writes the field through to storage. Runs on submit, on blur, and on
  /// leaving the screen — never mid-word.
  void _commit() {
    // The focus listener can fire while the screen is on its way out.
    if (!mounted) return;

    final parsed = _parse(_budgetController.text);

    // Text that doesn't parse is a typo in progress, not an instruction to
    // wipe the budget, so leave storage alone and put the saved value back
    // on screen so the field matches what is actually stored.
    if (parsed == null) {
      _budgetController.text = _budget == 0 ? '' : _budget.toStringAsFixed(0);
      setState(() => _draft = _budget == 0 ? null : _budget);
      return;
    }

    if (parsed == _budget) return;

    setState(() {
      _budget = parsed;
      _draft = parsed;
    });
    widget.onBudgetChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final double preview = _draft ?? 0;
    final perDay = preview / daysInMonth(now);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // PopScope wraps the field rather than the Scaffold because it
            // guards this one edit: leaving the screen has to count as
            // finishing it, or the back button throws away what was typed.
            PopScope(
              onPopInvokedWithResult: (didPop, _) {
                if (didPop && !_skipCommitOnPop) _commit();
              },
              child: TextField(
                controller: _budgetController,
                focusNode: _budgetFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Monthly spending money',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                onChanged: _onChanged,
                onSubmitted: (_) => _commit(),
              ),
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
              preview == 0
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
    _skipCommitOnPop = true;
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
    _skipCommitOnPop = true;
    Navigator.of(context).pop();
  }
}
