import 'package:flutter/material.dart';

/// Section header in the history list: "Today", "Yesterday", or a date,
/// with that day's total on the right.
class DayHeader extends StatelessWidget {
  final String label;
  final double total;

  const DayHeader({super.key, required this.label, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹${total.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}

/// Relative label for a day. The year only appears once the date falls
/// outside the current year, which keeps recent headers short.
String dayLabel(DateTime day, DateTime today) {
  final todayStart = DateTime(today.year, today.month, today.day);
  final difference = todayStart.difference(day).inDays;

  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';

  final weekday = _weekdays[day.weekday - 1];
  final month = _months[day.month - 1];
  final year = day.year == today.year ? '' : ' ${day.year}';
  return '$weekday, ${day.day} $month$year';
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
