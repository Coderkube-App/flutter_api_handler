import 'dart:async';

enum HttpEngine { http, dio }

class ApiConfig {
  /// Base URL for the API
  final String baseUrl;

  /// The engine to use for HTTP requests
  final HttpEngine engine;

  /// Function to retrieve the current authorization token
  final FutureOr<String?> Function()? tokenProvider;

  /// Function to retrieve the current language code
  final FutureOr<String> Function()? languageCodeProvider;

  /// Function called when an unauthorized response (e.g., 401 or 404) is received
  final FutureOr<void> Function(int statusCode)? onUnauthorized;

  /// Additional default headers to be sent with every request
  final Map<String, String>? defaultHeaders;

  /// Connect timeout
  final Duration timeout;

  /// Whether to log network requests
  final bool enableLogging;

  ApiConfig({
    required this.baseUrl,
    this.engine = HttpEngine.http,
    this.tokenProvider,
    this.languageCodeProvider,
    this.onUnauthorized,
    this.defaultHeaders,
    this.timeout = const Duration(seconds: 30),
    this.enableLogging = true,
  });
}

