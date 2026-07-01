import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/utils/store_display_helper.dart';

void main() {
  group('StoreDisplayHelper.storeInitials', () {
    test('returns VX for empty name', () {
      expect(StoreDisplayHelper.storeInitials(''), 'VX');
    });

    test('returns VX for whitespace-only name', () {
      expect(StoreDisplayHelper.storeInitials('   '), 'VX');
    });

    test('returns first two chars (upper) for single word', () {
      expect(StoreDisplayHelper.storeInitials('Mağaza'), 'MA');
    });

    test('returns first char of each of the first two words', () {
      expect(StoreDisplayHelper.storeInitials('Cafe Renk'), 'CR');
    });

    test('uses only first two words for three-word names', () {
      expect(StoreDisplayHelper.storeInitials('Berk Güzel Mağaza'), 'BG');
    });

    test('handles extra whitespace between words', () {
      expect(StoreDisplayHelper.storeInitials('Ali  Baba'), 'AB');
    });

    test('produces uppercase result', () {
      final result = StoreDisplayHelper.storeInitials('cafe bar');
      expect(result, result.toUpperCase());
    });

    test('single unicode letter word returns two chars', () {
      // "ÇK" - a word starting with two Turkish uppercase chars
      expect(StoreDisplayHelper.storeInitials('Çiçek'), 'Çİ');
    });
  });
}
