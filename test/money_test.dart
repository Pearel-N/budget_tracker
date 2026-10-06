import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/money.dart';

void main() {
  group('parseRupeesToPaise', () {
    test('reads whole rupees', () {
      expect(parseRupeesToPaise('30000'), 3000000);
    });

    test('reads paise', () {
      expect(parseRupeesToPaise('10.40'), 1040);
      expect(parseRupeesToPaise('249.5'), 24950);
    });

    test('ignores surrounding space', () {
      expect(parseRupeesToPaise('  120 '), 12000);
    });

    test('rounds a third decimal to the nearer paisa', () {
      expect(parseRupeesToPaise('10.404'), 1040);
      expect(parseRupeesToPaise('10.406'), 1041);
    });

    test('accepts zero', () {
      expect(parseRupeesToPaise('0'), 0);
    });

    test('rejects empty, junk and negative text', () {
      expect(parseRupeesToPaise(''), isNull);
      expect(parseRupeesToPaise('   '), isNull);
      expect(parseRupeesToPaise('abc'), isNull);
      expect(parseRupeesToPaise('12,000'), isNull);
      expect(parseRupeesToPaise('-50'), isNull);
    });
  });

  group('formatAmount', () {
    test('drops the decimals on a whole rupee amount', () {
      expect(formatAmount(3000000), '30000');
      expect(formatAmount(0), '0');
    });

    test('pads a single paisa', () {
      expect(formatAmount(1005), '10.05');
    });

    test('keeps paise when there are any', () {
      expect(formatAmount(1040), '10.40');
    });

    test('puts the sign before the whole amount', () {
      expect(formatAmount(-2080), '-20.80');
      expect(formatAmount(-2000), '-20');
    });

    test('round-trips through parseRupeesToPaise', () {
      for (final paise in [0, 1, 99, 100, 1040, 3000000]) {
        expect(parseRupeesToPaise(formatAmount(paise)), paise);
      }
    });
  });

  test('formatMoney adds the currency symbol', () {
    expect(formatMoney(1040), '₹10.40');
  });

  test('two amounts that each show paise agree with their total', () {
    // The bug this whole change exists for: as doubles rounded to whole
    // rupees, these two rows showed 10 and 10 while their total showed 21.
    expect(formatAmount(1040), '10.40');
    expect(formatAmount(1040 + 1040), '20.80');
  });
}
