import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/features/address/address_display.dart';

void main() {
  group('Форматирование адреса', () {
    const longAddressWithPrefix = '0x1234567890abcdef1234567890abcdef12345678';
    const longAddressWithoutPrefix = '1234567890abcdef1234567890abcdef12345678';
    const shortAddressWithPrefix = '0x12345abcd';
    const shortAddressWithoutPrefix = '12345abcd';

    test('Не теряется префикс 0x для короткого адреса', () {
      expect(formatAddressForCell(shortAddressWithPrefix, 1), startsWith('0x'));
    });

    test('Не теряется префикс 0x для длинного адреса', () {
      expect(formatAddressForCell(longAddressWithPrefix, 1), startsWith('0x'));
    });

    test('Короткий адрес без изменений с префиксом', () {
      expect(formatAddressForCell(shortAddressWithPrefix, 2), '0x12345abcd');
    });

    test('Короткий адрес без изменений без префикса', () {
      expect(formatAddressForCell(shortAddressWithoutPrefix, 2), '12345abcd');
    });

    test('Длинный адрес с префиксом / 6...4', () {
      expect(formatAddressForCell(longAddressWithPrefix, 1.5), '0x123456…5678');
    });

    test('Длинный адрес с без префикса / 6...4', () {
      expect(formatAddressForCell(longAddressWithoutPrefix, 1.5), '123456…5678');
    });

    test('Длинный адрес с префиксом / 4 + 4 при пограничном коэффициенте 1.6', () {
      expect(formatAddressForCell(longAddressWithPrefix, 1.6), '0x1234…5678');
    });

    test('Длинный адрес без префикса / 4 + 4 при пограничном коэффициенте 1.6', () {
      expect(formatAddressForCell(longAddressWithoutPrefix, 1.6), '1234…5678');
    });
  });
}
