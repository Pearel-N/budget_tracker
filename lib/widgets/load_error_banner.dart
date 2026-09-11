import 'package:flutter/material.dart';

/// Shown at the top of the home screen when saved expenses could not be
/// read. Dismissible rather than permanent: once the message has been
/// seen it shouldn't keep eating space above the day's numbers.
class LoadErrorBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const LoadErrorBanner({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
        child: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Couldn't read your saved expenses, so this list is "
                'starting empty. Anything you add now replaces the old data.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              iconSize: 20,
              color: scheme.onErrorContainer,
              tooltip: 'Dismiss',
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
