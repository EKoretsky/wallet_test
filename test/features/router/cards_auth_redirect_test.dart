import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/features/router/cards_auth_redirect.dart';

void main() {
  group('cardsAuthRedirect', () {
    test('перенаправляет неавторизованный deep link на onboarding', () {
      final uri = Uri.parse('/cards/card_1/issue?step=2');

      final redirect = cardsAuthRedirect(uri, false);

      expect(
        redirect,
        '/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2',
      );
    });

    test('возвращает авторизованного пользователя по безопасному next', () {
      final uri = Uri.parse(
        '/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2',
      );

      final redirect = cardsAuthRedirect(uri, true);

      expect(redirect, '/cards/card_1/issue?step=2');
    });

    test('заменяет внешний next на маршрут списка карт', () {
      final uri = Uri.parse(
        '/onboarding?next=https%3A%2F%2Fevil.com',
      );

      final redirect = cardsAuthRedirect(uri, true);

      expect(redirect, '/cards');
    });

    test('не перенаправляет с onboarding без авторизации', () {
      final redirect = cardsAuthRedirect(Uri.parse('/onboarding'), false);

      expect(redirect, isNull);
    });

    test('не перенаправляет с cards после авторизации', () {
      final redirect = cardsAuthRedirect(Uri.parse('/cards'), true);

      expect(redirect, isNull);
    });
  });
}
