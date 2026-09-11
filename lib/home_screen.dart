import 'package:flutter/material.dart';
import 'add_expense_sheet.dart';
import 'budget_logic.dart';
import 'budget_storage.dart';
import 'demo_data.dart';
import 'expense.dart';
import 'settings_screen.dart';
import 'widgets/back_to_today_pill.dart';
import 'widgets/budget_summary.dart';
import 'widgets/day_header.dart';
import 'widgets/expense_tile.dart';
import 'widgets/load_error_banner.dart';
import 'widgets/undo_countdown.dart';

/// Scroll distance after which the "Back to today" pill appears.
const _backToTodayThreshold = 220.0;

/// How long a deleted expense can be restored for.
///
/// Since Flutter 3.38 a SnackBar carrying an action defaults to
/// persist: true and never times out — it waits to be dismissed by hand.
/// `persist: false` below opts back into auto-dismissal so this duration
/// is actually honoured.
const _undoDuration = Duration(seconds: 5);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = BudgetStorage();
  final _scrollController = ScrollController();

  double _monthlyBudget = 0;
  final List<Expense> _expenses = [];
  bool _loading = true;
  bool _loadFailed = false;
  bool _showBackToToday = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Guarded end to end, because every failure here used to leave
  /// [_loading] true and the app stuck on its spinner with no way out.
  Future<void> _load() async {
    var budget = 0.0;
    var loaded = const ExpenseLoadResult([]);

    try {
      budget = await _storage.loadBudget();
      loaded = await _storage.loadExpenses();
    } catch (_) {
      // Storage itself is unreachable (a platform channel failure, say).
      loaded = const ExpenseLoadResult([], failed: true);
    }

    if (!mounted) return;

    setState(() {
      _monthlyBudget = budget;
      _expenses
        ..clear()
        ..addAll(loaded.expenses);
      _loadFailed = loaded.failed;
      _loading = false;
    });
  }

  /// Driven by a NotificationListener in build() rather than a listener
  /// attached in initState — initState doesn't re-run on hot reload, so a
  /// listener registered there silently stops existing after an edit.
  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final shouldShow = notification.metrics.pixels > _backToTodayThreshold;
    if (shouldShow != _showBackToToday) {
      setState(() => _showBackToToday = shouldShow);
    }
    return false;
  }

  void _backToToday() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _addExpense() async {
    final expense = await showAddExpenseSheet(context);
    if (expense == null || !mounted) return;

    setState(() => _expenses.add(expense));
    await _storage.saveExpenses(_expenses);
  }

  Future<void> _deleteExpense(Expense expense) async {
    setState(() => _expenses.removeWhere((e) => e.id == expense.id));
    await _storage.saveExpenses(_expenses);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: _undoDuration,
          persist: false,
          content: UndoCountdown(
            label: 'Deleted ₹${expense.amount.toStringAsFixed(0)}',
            duration: _undoDuration,
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _undoDelete(expense),
          ),
        ),
      );
  }

  /// Pressing the action dismisses the snack bar itself, so this only has
  /// to put the expense back.
  void _undoDelete(Expense expense) {
    setState(() => _expenses.add(expense));
    _storage.saveExpenses(_expenses);
  }

  Future<void> _seedDemoData() async {
    final demo = generateDemoExpenses();
    setState(() {
      _expenses
        ..clear()
        ..addAll(demo);
      if (_monthlyBudget == 0) _monthlyBudget = 30000;
    });
    await _storage.saveExpenses(_expenses);
    await _storage.saveBudget(_monthlyBudget);
  }

  Future<void> _clearAllData() async {
    setState(() {
      _expenses.clear();
      _monthlyBudget = 0;
    });
    await _storage.clearAll();
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsScreen(
        monthlyBudget: _monthlyBudget,
        onBudgetChanged: (amount) {
          setState(() => _monthlyBudget = amount);
          _storage.saveBudget(amount);
        },
        onSeedDemoData: _seedDemoData,
        onClearData: _clearAllData,
      ),
    ));
  }

  /// Day sections newest first, with today always present even when
  /// nothing has been logged yet — otherwise the list opens on yesterday
  /// and it looks like today went missing.
  List<DayGroup> _sections(DateTime today) {
    final groups = groupByDayDescending(_expenses);
    final todayStart = DateTime(today.year, today.month, today.day);

    if (groups.isEmpty || groups.first.date != todayStart) {
      return [
        DayGroup(date: todayStart, expenses: const [], total: 0),
        ...groups,
      ];
    }
    return groups;
  }

  /// Flattens day sections into a single row list so the whole history
  /// scrolls as one ListView.
  List<_Row> _buildRows(List<DayGroup> sections, DateTime today) {
    final rows = <_Row>[];

    for (final section in sections) {
      rows.add(_HeaderRow(section, dayLabel(section.date, today)));

      if (section.expenses.isEmpty) {
        rows.add(const _EmptyRow());
      } else {
        rows.addAll(section.expenses.map(_ExpenseRow.new));
      }
    }

    return rows;
  }

  Widget _buildRow(_Row row) {
    switch (row) {
      case _HeaderRow(:final group, :final label):
        return DayHeader(label: label, total: group.total);

      case _EmptyRow():
        return const Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Text('Nothing logged yet today.'),
        );

      case _ExpenseRow(:final expense):
        return Dismissible(
          key: ValueKey(expense.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          onDismissed: (_) => _deleteExpense(expense),
          child: ExpenseTile(expense: expense),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final rows = _buildRows(_sections(now), now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_loadFailed)
              LoadErrorBanner(
                onDismiss: () => setState(() => _loadFailed = false),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: BudgetSummary(
                allowance: allowanceFor(
                  monthlyBudget: _monthlyBudget,
                  entries: aggregateByDay(_expenses),
                  day: now,
                ),
                spentToday: spentOn(_expenses, now),
                monthlyBudget: _monthlyBudget,
                spentThisMonth: spentInMonth(_expenses, now),
                daysLeftInMonth: daysRemainingIn(now),
                onSetBudget: _openSettings,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScroll,
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: rows.length,
                      itemBuilder: (context, index) => _buildRow(rows[index]),
                    ),
                    BackToTodayPill(
                      visible: _showBackToToday,
                      onPressed: _backToToday,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flattened list rows. Sealed so the switch in [_HomeScreenState._buildRow]
/// is exhaustive and adding a row type is a compile error until handled.
sealed class _Row {
  const _Row();
}

class _HeaderRow extends _Row {
  final DayGroup group;
  final String label;

  const _HeaderRow(this.group, this.label);
}

class _ExpenseRow extends _Row {
  final Expense expense;

  const _ExpenseRow(this.expense);
}

class _EmptyRow extends _Row {
  const _EmptyRow();
}
