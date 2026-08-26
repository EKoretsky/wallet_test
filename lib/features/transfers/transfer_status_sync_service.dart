import 'package:dio/dio.dart';

import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_repository.dart';

class TransferStatusSyncService {
  TransferStatusSyncService({
    required this._api,
    required this._repository,
  });

  final ApiClient _api;
  final ITransferRepository _repository;

  Future<TransferStatus> sync(
    Transfer transfer, {
    CancelToken? cancelToken,
  }) async {
    final idempotencyKey = '${transfer.network.toLowerCase()}:${transfer.txHash}';

    final response = await _getStatus(
      transfer,
      idempotencyKey: idempotencyKey,
      cancelToken: cancelToken,
    );

    final status = TransferStatus.fromName(
      response.data['status'] as String? ?? 'unknown',
    );

    await _repository.applyStatus(
      transfer,
      status,
      DateTime.now(),
    );

    return status;
  }

  Future<Response<dynamic>> _getStatus(
    Transfer transfer, {
    required String idempotencyKey,
    CancelToken? cancelToken,
    int retryIndex = 0,
  }) async {
    try {
      return await _api.dio.get(
        '/v1/transfers/${transfer.txHash}/status',
        cancelToken: cancelToken,
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
        ),
      );
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel) {
        throw const CancelException();
      }

      if (!_isRetryable(error)) {
        throw TransferSyncException.fromHttpStatus(
          error.response?.statusCode,
        );
      }

      switch (retryIndex) {
        case 0:
          await Future<void>.delayed(const Duration(milliseconds: 200));
        case 1:
          await Future<void>.delayed(const Duration(milliseconds: 500));
        default:
          throw TransferSyncException.fromHttpStatus(
            error.response?.statusCode,
          );
      }

      return _getStatus(
        transfer,
        idempotencyKey: idempotencyKey,
        cancelToken: cancelToken,
        retryIndex: retryIndex + 1,
      );
    }
  }

  bool _isRetryable(DioException error) {
    const retryableStatusCodes = {408, 429, 503};
    final retryableExceptionTypes = {
      DioExceptionType.connectionTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };

    if (error.response?.statusCode != null) {
      return retryableStatusCodes.contains(error.response?.statusCode);
    }

    return retryableExceptionTypes.contains(error.type);
  }
}
