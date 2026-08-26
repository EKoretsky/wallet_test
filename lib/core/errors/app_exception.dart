class AppException implements Exception {
  const AppException({
    required this.code,
    this.message,
  });

  final String code;
  final String? message;

  @override
  String toString() => 'AppException($code: $message)';
}

class TransferSyncException extends AppException {
  const TransferSyncException({
    required super.code,
    super.message,
  });

  factory TransferSyncException.fromHttpStatus(int? statusCode) {
    final code = switch (statusCode) {
      401 => 'unauthorized',
      404 => 'notFound',
      409 => 'conflict',
      408 || 429 => 'rateLimited',
      503 => 'serverUnavailable',
      500 => 'internal',
      null => 'network',
      _ => 'internal',
    };

    final message = switch (statusCode) {
      null => 'Network error',
      _ => 'HTTP status: $statusCode',
    };

    return TransferSyncException(
      code: code,
      message: message,
    );
  }
}

class CancelException implements Exception {
  const CancelException();

  @override
  String toString() => 'Cancelled';
}
