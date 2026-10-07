// Pure Dart, no Flutter imports — same rule as budget_logic.dart, so the
// logic layer and its tests can use this without a widget binding.
//
// intl is a plain Dart package rather than a Flutter one, so that rule still
// holds. NumberFormat carries its own number data, so unlike DateFormat it
// needs no initialisation call before the first format.
import 'package:intl/intl.dart';

/// Money is carried as a whole number of paise everywhere inside the app.
/// Amounts used to be doubles displayed with toStringAsFixed(0), so each
/// row of a day could round one way while their total rounded the other:
/// ₹10.40 + ₹10.40 showed as 10 + 10 = 21. Integers cannot drift like that.
const int paisePerRupee = 100;

/// The only written ₹ in the app, so a currency change is one edit.
const String rupeeSymbol = '₹';

/// Pinned to en_IN rather than the device locale: the amounts are rupees, and
/// the lakh grouping belongs to the currency, not to whatever language the
/// phone happens to be set to.
final NumberFormat _grouping = NumberFormat.decimalPattern('en_IN');

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

/// An amount for display: currency symbol plus Indian digit grouping —
/// ₹1,23,456, lakhs rather than thousands once past the first three digits.
String formatMoney(int paise) =>
    '$rupeeSymbol${_formatRupees(paise, grouped: true)}';

/// [formatMoney] without the symbol, for fields that show ₹ as their own
/// prefix. Ungrouped on purpose: this is the inverse of [parseRupeesToPaise],
/// which reads "30,000" as junk, so grouping here would make a saved budget
/// unparseable the next time the field was read back.
String formatAmount(int paise) => _formatRupees(paise, grouped: false);

/// Paise appear only when there are any: whole rupees stay uncluttered, and
/// an amount with paise in it no longer disagrees with the total it is part
/// of.
String _formatRupees(int paise, {required bool grouped}) {
  // Sign is handled up front because ~/ truncates toward zero while % stays
  // positive, which would render -2080 as "-20.20" rather than "-20.80".
  final sign = paise < 0 ? '-' : '';
  final magnitude = paise.abs();

  final rupees = magnitude ~/ paisePerRupee;
  final fraction = magnitude % paisePerRupee;

  // Only the rupee part goes through NumberFormat, and as an int: the paise
  // are appended as digits, so grouping never routes money back via a double.
  final whole = grouped ? _grouping.format(rupees) : '$rupees';

  if (fraction == 0) return '$sign$whole';
  return '$sign$whole.${fraction.toString().padLeft(2, '0')}';
}
