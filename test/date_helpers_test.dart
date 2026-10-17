import 'package:flutter_test/flutter_test.dart';
import 'package:court_ocr_scanner/main.dart';

void main() {
  group('date helpers', () {
    test('fmtDate uses DD/MM/YYYY', () {
      expect(fmtDate(DateTime(2026, 9, 19)), '19/09/2026');
    });

    test('monthYear converts a valid date to abbreviated month and year', () {
      expect(monthYear('19/09/2026'), 'Sep2026');
    });

    test('monthYear rejects invalid dates', () {
      expect(monthYear('31/13/2026'), isEmpty);
      expect(monthYear('31/02/2026'), isEmpty);
      expect(monthYear('29/02/2025'), isEmpty);
      expect(monthYear('not a date'), isEmpty);
    });

    test('monthYear accepts a valid leap-day date', () {
      expect(monthYear('29/02/2024'), 'Feb2024');
    });

    test('parseStrictDate rejects normalized impossible dates', () {
      expect(parseStrictDate('31/02/2026'), isNull);
      expect(parseStrictDate('19/09/2026'), DateTime(2026, 9, 19));
    });
  });
}
