class ApiResponse {
  final String? body;
  final Map<String, String>? headers;
  final String? error;
  final int? statusCode;

  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;

  ApiResponse({
    this.body,
    this.headers,
    this.error,
    this.statusCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'body': body,
      'headers': headers,
      'error': error,
      'statusCode': statusCode,
      'isSuccess': isSuccess,
    };
  }

  @override
  String toString() =>
      'ApiResponse(statusCode: $statusCode, error: $error, body: $body)';
}
