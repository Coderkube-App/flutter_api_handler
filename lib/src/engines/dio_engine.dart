import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/api_config.dart';
import '../models/api_response.dart';
import 'base_engine.dart';

class DioEngineImpl implements BaseApiEngine {
  final ApiConfig config;
  final Logger logger;
  late Dio _dio;

  DioEngineImpl({required this.config, required this.logger}) {
    _dio = Dio(BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.timeout,
      receiveTimeout: config.timeout,
      sendTimeout: config.timeout,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add default headers
        if (config.defaultHeaders != null) {
          options.headers.addAll(config.defaultHeaders!);
        }

        // Add language code
        if (config.languageCodeProvider != null) {
          String languageCode = await config.languageCodeProvider!();
          options.headers['Accept-Language'] = languageCode;
        }

        // Add token if needed
        // Note: The 'sendToken' flag is handled per-request in the method calls below,
        // but we can also handle a default behavior here.
        // However, it's safer to do it in the request methods to respect the 'sendToken' flag.
        
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        _logResponse(response);
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        _logError("Dio Error: ${e.message}", e, e.stackTrace);
        if (e.response != null) {
          await _handleUnauthorizedResponse(e.response!.statusCode ?? 0);
        }
        return handler.next(e);
      },
    ));

    if (config.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (object) => logger.i(object.toString()),
      ));
    }
  }

  void _logResponse(Response response) {
    if (config.enableLogging) {
      logger.i("Response [${response.statusCode}] => PATH: ${response.requestOptions.path}");
    }
  }

  void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (config.enableLogging) {
      logger.e(message, error: error, stackTrace: stackTrace);
    }
  }

  Future<bool> _hasNetwork() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.isEmpty) return false;
    return connectivityResult.any((result) => result != ConnectivityResult.none);
  }

  Future<Map<String, String>> _getHeaders(bool sendToken) async {
    Map<String, String> headers = {};
    if (sendToken && config.tokenProvider != null) {
      String? token = await config.tokenProvider!();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<void> _handleUnauthorizedResponse(int statusCode) async {
    if ((statusCode == 401) && config.onUnauthorized != null) {
      try {
        await config.onUnauthorized!(statusCode);
      } catch (e, stackTrace) {
        _logError("Unauthorized handler error", e, stackTrace);
      }
    }
  }

  ApiResponse _mapResponse(Response response) {
    return ApiResponse(
      body: response.data is String ? response.data : jsonEncode(response.data),
      headers: response.headers.map.map((key, value) => MapEntry(key, value.join(', '))),
      statusCode: response.statusCode ?? 0,
      error: (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) ? null : "${response.statusCode}",
    );
  }

  ApiResponse _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiResponse(error: "Request timed out", statusCode: 408);
    } else if (e.type == DioExceptionType.connectionError) {
      return ApiResponse(error: "No internet connection");
    } else if (e.response != null) {
      return _mapResponse(e.response!);
    } else {
      return ApiResponse(error: e.message ?? "Unknown error");
    }
  }

  @override
  Future<ApiResponse> get({required String url, bool sendToken = true}) async {
    if (!(await _hasNetwork())) return ApiResponse(error: "No network available");
    try {
      final headers = await _getHeaders(sendToken);
      final response = await _dio.get(url, options: Options(headers: headers));
      return _mapResponse(response);
    } on DioException catch (e) {
      return _mapError(e);
    }
  }

  @override
  Future<ApiResponse> post({required String url, Map<String, dynamic>? data, bool isNotEncoded = false, bool sendToken = true}) async {
    if (!(await _hasNetwork())) return ApiResponse(error: "No network available");
    try {
      final headers = await _getHeaders(sendToken);
      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: headers),
      );
      return _mapResponse(response);
    } on DioException catch (e) {
      return _mapError(e);
    }
  }

  @override
  Future<ApiResponse> put({required String url, Map<String, dynamic>? data, bool sendToken = true}) async {
    if (!(await _hasNetwork())) return ApiResponse(error: "No network available");
    try {
      final headers = await _getHeaders(sendToken);
      final response = await _dio.put(
        url,
        data: data,
        options: Options(headers: headers),
      );
      return _mapResponse(response);
    } on DioException catch (e) {
      return _mapError(e);
    }
  }

  @override
  Future<ApiResponse> patch({required String url, Map<String, dynamic>? data, bool sendToken = true}) async {
    if (!(await _hasNetwork())) return ApiResponse(error: "No network available");
    try {
      final headers = await _getHeaders(sendToken);
      final response = await _dio.patch(
        url,
        data: data,
        options: Options(headers: headers),
      );
      return _mapResponse(response);
    } on DioException catch (e) {
      return _mapError(e);
    }
  }

  @override
  Future<ApiResponse> delete({required String url, bool sendToken = true}) async {
    if (!(await _hasNetwork())) return ApiResponse(error: "No network available");
    try {
      final headers = await _getHeaders(sendToken);
      final response = await _dio.delete(url, options: Options(headers: headers));
      return _mapResponse(response);
    } on DioException catch (e) {
      return _mapError(e);
    }
  }

  @override
  Future<ApiResponse> formRequest({
    required String methodType,
    required String url,
    Map<String, String>? fields,
    File? singleFile,
    String? singleFileKey,
    List<File>? multipleFiles,
    String? multipleFileKey,
    List<String>? multipleFileKeysList,
    bool sendToken = true,
  }) async {
    if (!(await _hasNetwork())) return ApiResponse(error: "No network available");
    try {
      final headers = await _getHeaders(sendToken);
      
      Map<String, dynamic> formDataMap = {};
      if (fields != null) formDataMap.addAll(fields);

      if (singleFile != null && singleFileKey != null) {
        formDataMap[singleFileKey] = await MultipartFile.fromFile(singleFile.path);
      }

      if (multipleFiles != null && multipleFiles.isNotEmpty) {
        if (multipleFileKeysList != null && multipleFileKeysList.length == multipleFiles.length) {
          for (int i = 0; i < multipleFiles.length; i++) {
            formDataMap[multipleFileKeysList[i]] = await MultipartFile.fromFile(multipleFiles[i].path);
          }
        } else if (multipleFileKey != null) {
          formDataMap[multipleFileKey] = await Future.wait(
            multipleFiles.map((file) => MultipartFile.fromFile(file.path)).toList()
          );
        }
      }

      final formData = FormData.fromMap(formDataMap);
      
      final response = await _dio.request(
        url,
        data: formData,
        options: Options(method: methodType, headers: headers),
      );
      
      return _mapResponse(response);
    } on DioException catch (e) {
      return _mapError(e);
    }
  }
}
