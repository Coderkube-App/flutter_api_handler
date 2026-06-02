import 'dart:io';
import 'package:logger/logger.dart';

import 'config/api_config.dart';
import 'models/api_response.dart';
import 'engines/base_engine.dart';
import 'engines/http_engine.dart';
import 'engines/dio_engine.dart';

class APIManager {
  static BaseApiEngine? _engine;

  
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  /// Initialize the HttpManager with the given [ApiConfig].
  /// This must be called before making any HTTP requests.
  static void initialize(ApiConfig config) {
    switch (config.engine) {

      case HttpEngine.http:
        _engine = HttpEngineImpl(config: config, logger: _logger);
        break;
      case HttpEngine.dio:
        _engine = DioEngineImpl(config: config, logger: _logger);
        break;
    }
  }

  static BaseApiEngine get _instance {
    if (_engine == null) {
      throw Exception('HttpManager is not initialized. Call HttpManager.initialize() first.');
    }
    return _engine!;
  }

  /// Perform an HTTP POST request
  static Future<ApiResponse> post({
    required String url,
    Map<String, dynamic>? data,
    bool isNotEncoded = false,
    bool sendToken = true,
  }) {
    return _instance.post(
      url: url,
      data: data,
      isNotEncoded: isNotEncoded,
      sendToken: sendToken,
    );
  }

  /// Perform an HTTP GET request
  static Future<ApiResponse> get({
    required String url,
    bool sendToken = true,
  }) {
    return _instance.get(
      url: url,
      sendToken: sendToken,
    );
  }

  /// Perform an HTTP PATCH request
  static Future<ApiResponse> patch({
    required String url,
    Map<String, dynamic>? data,
    bool sendToken = true,
  }) {
    return _instance.patch(
      url: url,
      data: data,
      sendToken: sendToken,
    );
  }

  /// Perform an HTTP PUT request
  static Future<ApiResponse> put({
    required String url,
    Map<String, dynamic>? data,
    bool sendToken = true,
  }) {
    return _instance.put(
      url: url,
      data: data,
      sendToken: sendToken,
    );
  }

  /// Perform an HTTP DELETE request
  static Future<ApiResponse> delete({
    required String url,
    bool sendToken = true,
  }) {
    return _instance.delete(
      url: url,
      sendToken: sendToken,
    );
  }

  /// Perform an HTTP Multipart/Form request
  static Future<ApiResponse> formRequest({
    required String methodType,
    required String url,
    Map<String, String>? fields,
    File? singleFile,
    String? singleFileKey,
    List<File>? multipleFiles,
    String? multipleFileKey,
    List<String>? multipleFileKeysList,
    bool sendToken = true,
  }) {
    return _instance.formRequest(
      methodType: methodType,
      url: url,
      fields: fields,
      singleFile: singleFile,
      singleFileKey: singleFileKey,
      multipleFiles: multipleFiles,
      multipleFileKey: multipleFileKey,
      multipleFileKeysList: multipleFileKeysList,
      sendToken: sendToken,
    );
  }
}

