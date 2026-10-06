// Pure Dart, no Flutter imports — same rule as budget_logic.dart, so the
// logic layer and its tests can use this without a widget binding.

/// Money is carried as a whole number of paise everywhere inside the app.
/// Amounts used to be doubles displayed with toStringAsFixed(0), so each
/// row of a day could round one way while their total rounded the other:
/// ₹10.40 + ₹10.40 showed as 10 + 10 = 21. Integers cannot drift like that.
const int paisePerRupee = 100;

/// Parses user-typed rupees ("249.5", "10.40") into paise. Null for
/// anything that isn't a usable amount: empty, junk, or negative.
///
/// Rounds rather than truncates, so a third decimal that gets pasted in
/// lands on the nearer paisa instead of silently disappearing.
int? parseRupeesToPaise(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;

  final rupees = double.tryParse(text);
  if (rupees == null || rupees.isNaN || rupees.isInfinite || rupees < 0) {
    return null;
  }

  return (rupees * paisePerRupee).round();
}

/// An amount for display, with the currency symbol.
///
/// Every ₹ the user sees comes from here, so the locale-aware grouping that
/// comes next only has to change this one function.
String formatMoney(int paise) => '₹${formatAmount(paise)}';

/// [formatMoney] without the symbol, for fields that show ₹ as their own
/// prefix and for text that has to parse back via [parseRupeesToPaise].
///
/// Paise appear only when there are any: whole rupees stay uncluttered, and
/// an amount with paise in it no longer disagrees with the total it is part
/// of.
String formatAmount(int paise) {
  // Sign is handled up front because ~/ truncates toward zero while % stays
  // positive, which would render -2080 as "-20.20" rather than "-20.80".
  final sign = paise < 0 ? '-' : '';
  final magnitude = paise.abs();

  final rupees = magnitude ~/ paisePerRupee;
  final fraction = magnitude % paisePerRupee;

  if (fraction == 0) return '$sign$rupees';
  return '$sign$rupees.${fraction.toString().padLeft(2, '0')}';
}
