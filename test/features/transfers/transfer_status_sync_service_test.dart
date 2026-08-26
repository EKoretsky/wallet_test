import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_transfer_repository.dart';
import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_status_sync_service.dart';

import '../../fakes/fake_http_client_adapter.dart';

TransferStatusSyncService _createService(FakeHttpClientAdapter adapter, InMemoryTransferRepository repository) {
  final dio = Dio()..httpClientAdapter = adapter;

  return TransferStatusSyncService(
    api: ApiClient(dio: dio),
    repository: repository,
  );
}

Matcher _hasTransferSyncCode(String code) {
  return isA<TransferSyncException>().having((error) => error.code, 'code', code);
}

void main() {
  group('TransferStatusSyncService', () {
    const transfer = Transfer(
      id: 'transfer-1',
      network: 'ethereum',
      txHash: '0x1234abcd',
    );

    test('после 429 повторяет запрос и сохраняет подтверждённый статус', () async {
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(429),
        HttpOutcome(200, body: {'status': 'confirmed'}),
      ]);
      final repository = InMemoryTransferRepository();
      final service = _createService(adapter, repository);

      final status = await service.sync(transfer);

      expect(status, TransferStatus.confirmed);
      expect(adapter.calls, hasLength(2));
      expect(repository.applyCalls, 1);
      expect(repository.lastStatus, TransferStatus.confirmed);
    });

    test('не повторяет 401 и возвращает unauthorized', () async {
      final adapter = FakeHttpClientAdapter([HttpOutcome(401)]);
      final repository = InMemoryTransferRepository();
      final service = _createService(adapter, repository);

      await expectLater(
        service.sync(transfer),
        throwsA(_hasTransferSyncCode('unauthorized')),
      );

      expect(adapter.calls, hasLength(1));
      expect(repository.applyCalls, 0);
    });

    test('не повторяет 500 и возвращает internal', () async {
      final adapter = FakeHttpClientAdapter([HttpOutcome(500)]);
      final repository = InMemoryTransferRepository();
      final service = _createService(adapter, repository);

      await expectLater(
        service.sync(transfer),
        throwsA(_hasTransferSyncCode('internal')),
      );

      expect(adapter.calls, hasLength(1));
      expect(repository.applyCalls, 0);
    });

    test('после трёх 429 возвращает rateLimited', () async {
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(429),
        HttpOutcome(429),
        HttpOutcome(429),
      ]);
      final repository = InMemoryTransferRepository();
      final service = _createService(adapter, repository);

      await expectLater(
        service.sync(transfer),
        throwsA(_hasTransferSyncCode('rateLimited')),
      );

      expect(adapter.calls, hasLength(3));
      expect(repository.applyCalls, 0);
    });

    test('при ошибке БД возвращает localPersistenceFailed', () async {
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(200, body: {'status': 'confirmed'}),
      ]);
      final repository = InMemoryTransferRepository()..shouldFail = true;
      final service = _createService(adapter, repository);

      await expectLater(
        service.sync(transfer),
        throwsA(_hasTransferSyncCode('localPersistenceFailed')),
      );

      expect(adapter.calls, hasLength(1));
      expect(repository.applyCalls, 1);
    });

    test('передаёт Idempotency-Key с сетью в нижнем регистре', () async {
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(200, body: {'status': 'confirmed'}),
      ]);
      final repository = InMemoryTransferRepository();
      final service = _createService(adapter, repository);
      const mixedCaseTransfer = Transfer(
        id: 'transfer-2',
        network: 'EtHeReUm',
        txHash: '0xAbCd1234',
      );

      await service.sync(mixedCaseTransfer);

      expect(adapter.calls, hasLength(1));
      expect(adapter.calls.single.headers, contains('Idempotency-Key'));
      expect(
        adapter.calls.single.headers['Idempotency-Key'],
        'ethereum:0xAbCd1234',
      );
    });
  });
}
