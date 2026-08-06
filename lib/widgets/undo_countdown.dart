import 'package:flutter/material.dart';

/// Snack bar body with a bar that drains as the undo window closes, so
/// the countdown is visible instead of guessed at.
class UndoCountdown extends StatelessWidget {
  final String label;
  final Duration duration;

  const UndoCountdown({
    super.key,
    required this.label,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 0),
          duration: duration,
          curve: Curves.linear,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 3,
              color: scheme.inversePrimary,
              backgroundColor: scheme.onInverseSurface.withValues(alpha: 0.25),
            ),
          ),
        ),
      ],
    );
  }
}
