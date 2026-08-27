import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_address_repository.dart';
import 'package:wallet_test/core/theme/app_tokens.dart';
import 'package:wallet_test/features/address/address_tile.dart';
import 'package:wallet_test/features/address/address_tile_bloc.dart';

void main() {
  const address = '0x1234567890abcdef1234567890abcdef12345678';
  const network = 'Ethereum';

  late InMemoryAddressRepository repository;
  late AddressTileBloc bloc;

  setUp(() async {
    await GetIt.instance.reset();
    repository = InMemoryAddressRepository();
    bloc = AddressTileBloc(repository: repository);
    GetIt.instance.registerSingleton<AddressTileBloc>(bloc);
  });

  tearDown(() async {
    if (!bloc.isClosed) {
      await bloc.close();
    }
    await GetIt.instance.reset();
  });

  Future<void> pumpAddressTile(
    WidgetTester tester, {
    double textScaleFactor = 1,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: const AddressTile(
              address: address,
              network: network,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> tapCopyAndWaitFor(
    WidgetTester tester,
    bool Function(AddressTileState state) predicate,
  ) async {
    final stateFuture = bloc.stream.firstWhere(predicate);

    await tester.tap(find.byType(IconButton));
    await tester.runAsync(
      () => stateFuture.timeout(const Duration(seconds: 2)),
    );
    await tester.pump();
  }

  testWidgets('отображает виджет', (tester) async {
    await pumpAddressTile(tester);

    expect(find.byType(AddressTile), findsOneWidget);
    expect(find.text(network), findsOneWidget);
    expect(find.text('0x123456…5678'), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
  });

  testWidgets('не переполняется при коэффициенте масштаба текста 2.0', (tester) async {
    await pumpAddressTile(tester, textScaleFactor: 2);

    expect(tester.takeException(), isNull);
  });

  testWidgets('вызывает copyAddress при нажатии на кнопку', (tester) async {
    await pumpAddressTile(tester);
    await tapCopyAndWaitFor(tester, (state) => state.copied);

    expect(repository.copyCalls, 1);
    expect(repository.lastAddress, address);
  });

  testWidgets('показывает состояние успешного копирования', (tester) async {
    await pumpAddressTile(tester);
    await tapCopyAndWaitFor(tester, (state) => state.copied);

    final icon = tester.widget<Icon>(find.byIcon(Icons.check));
    expect(icon.color, AppTokens.success);
  });

  testWidgets('показывает состояние ошибки после неудачного копирования', (tester) async {
    repository.shouldFail = true;
    await pumpAddressTile(tester);
    await tapCopyAndWaitFor(tester, (state) => state.error != null);

    final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
    expect(icon.color, AppTokens.danger);
  });

  testWidgets('сбрасывает состояние успешного копирования через 1500 мс', (tester) async {
    await pumpAddressTile(tester);
    await tapCopyAndWaitFor(tester, (state) => state.copied);
    final resetState = bloc.stream.firstWhere(
      (state) => !state.copied && state.error == null,
    );

    await tester.runAsync(
      () => resetState.timeout(const Duration(seconds: 2)),
    );
    await tester.pump();

    final icon = tester.widget<Icon>(find.byIcon(Icons.copy));
    expect(icon.color, AppTokens.textSecondary);
  });

  testWidgets('закрывает BLoC после dispose', (tester) async {
    await pumpAddressTile(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      final timeout = Stopwatch()..start();
      while (!bloc.isClosed && timeout.elapsed < const Duration(seconds: 1)) {
        await Future<void>.delayed(Duration.zero);
      }
    });

    expect(bloc.isClosed, isTrue);
  });
}
