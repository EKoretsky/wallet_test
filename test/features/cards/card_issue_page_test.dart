import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/dev_stubs/dev_card_issuer.dart';
import 'package:wallet_test/features/cards/card_issue_bloc.dart';
import 'package:wallet_test/features/cards/card_issue_page.dart';
import 'package:wallet_test/features/cards/card_issuer.dart';

import '../../helpers/test_get_it.dart';

void main() {
  testWidgets(
    'использует зависимости из GetIt и освобождает их при удалении страницы',
    (tester) => testWithGetIt(() async {
      final getIt = GetIt.instance;
      final issuer = getIt<ICardIssuer>() as DevCardIssuer;
      final bloc = getIt<CardIssueBloc>();

      await getIt.unregister<CardIssueBloc>();
      getIt.registerSingleton<CardIssueBloc>(bloc);

      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      expect(find.text('Issue card'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        final timeout = Stopwatch()..start();

        while (!bloc.isClosed && timeout.elapsed < const Duration(seconds: 1)) {
          await Future<void>.delayed(Duration.zero);
        }
      });

      expect(bloc.isClosed, isTrue);
      expect(issuer.cancelCalls, 1);
    }),
  );
}
