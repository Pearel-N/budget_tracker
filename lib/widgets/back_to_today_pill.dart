import 'package:flutter/material.dart';

/// Floats over the top of the history list once you've scrolled back in
/// time. Must be placed directly inside a [Stack].
class BackToTodayPill extends StatelessWidget {
  final bool visible;
  final VoidCallback onPressed;

  const BackToTodayPill({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      // Without this the hidden pill would still swallow taps meant for
      // the row underneath it.
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, -2),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Center(
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(24),
                color: scheme.secondaryContainer,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onPressed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_upward,
                          size: 16,
                          color: scheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Back to today',
                          style: TextStyle(
                            color: scheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
