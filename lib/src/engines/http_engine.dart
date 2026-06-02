import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../config/api_config.dart';
import '../models/api_response.dart';
import 'base_engine.dart';

class HttpEngineImpl implements BaseApiEngine {
  final ApiConfig config;
  final Logger logger;

  HttpEngineImpl({required this.config, required this.logger});

  void _log(String message) {
    if (config.enableLogging) {
      logger.i(message);
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
    Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (config.defaultHeaders != null) {
      headers.addAll(config.defaultHeaders!);
    }

    if (config.languageCodeProvider != null) {
      String languageCode = await config.languageCodeProvider!();
      headers['Accept-Language'] = languageCode;
    }

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
      _log("⚠️ Unauthorized or Not Found ($statusCode) – Triggering onUnauthorized callback");
      try {
        await config.onUnauthorized!(statusCode);
      } catch (e, stackTrace) {
        _logError("Unauthorized handler error", e, stackTrace);
      }
    }
  }

  Uri _buildUri(String url) {
    final baseUrl = config.baseUrl.endsWith('/') ? config.baseUrl : '${config.baseUrl}/';
    final path = url.startsWith('/') ? url.substring(1) : url;
    return Uri.parse('$baseUrl$path');
  }

  Future<ApiResponse> _executeRequest(Future<http.Response> Function() requestFunc, String methodName, String url) async {
    if (!(await _hasNetwork())) {
      return ApiResponse(error: "No network available");
    }

    try {
      final response = await requestFunc().timeout(config.timeout);
      
      _log("$methodName Response Code -- '${response.statusCode}'");
      _log("$methodName Response -- '${response.body}'");

      await _handleUnauthorizedResponse(response.statusCode);

      return ApiResponse(
        body: response.body,
        headers: response.headers,
        statusCode: response.statusCode,
        error: (response.statusCode >= 200 && response.statusCode < 300) ? null : "${response.statusCode}",
      );
    } on SocketException {
      return ApiResponse(error: "No internet connection");
    } on TimeoutException {
      return ApiResponse(error: "Request timed out");
    } catch (e) {
      return ApiResponse(error: e.toString());
    }
  }

  @override
  Future<ApiResponse> get({required String url, bool sendToken = true}) async {
    final header = await _getHeaders(sendToken);
    final uri = _buildUri(url);
    _log("Get URL -- '$uri'");
    _log("Get Header -- '$header'");

    return _executeRequest(() => http.get(uri, headers: header), 'Get', url);
  }

  @override
  Future<ApiResponse> post({required String url, Map<String, dynamic>? data, bool isNotEncoded = false, bool sendToken = true}) async {
    final header = await _getHeaders(sendToken);
    final uri = _buildUri(url);
    _log("Post URL -- '$uri'");
    if (data != null) _log("Post Data -- '${jsonEncode(data)}'");
    _log("Post Header -- '$header'");

    return _executeRequest(() {
      return http.post(
        uri,
        headers: header,
        body: data == null ? null : (isNotEncoded ? data : jsonEncode(data)),
      );
    }, 'Post', url);
  }

  @override
  Future<ApiResponse> put({required String url, Map<String, dynamic>? data, bool sendToken = true}) async {
    final header = await _getHeaders(sendToken);
    final uri = _buildUri(url);
    _log("Put URL -- '$uri'");
    if (data != null) _log("Put Data -- '$data'");
    _log("Put Header -- '$header'");

    return _executeRequest(() {
      return http.put(uri, headers: header, body: data == null ? null : jsonEncode(data));
    }, 'Put', url);
  }

  @override
  Future<ApiResponse> patch({required String url, Map<String, dynamic>? data, bool sendToken = true}) async {
    final header = await _getHeaders(sendToken);
    final uri = _buildUri(url);
    _log("Patch URL -- '$uri'");
    if (data != null) _log("Patch Data -- '$data'");
    _log("Patch Header -- '$header'");

    return _executeRequest(() {
      return http.patch(uri, headers: header, body: data == null ? null : jsonEncode(data));
    }, 'Patch', url);
  }

  @override
  Future<ApiResponse> delete({required String url, bool sendToken = true}) async {
    final header = await _getHeaders(sendToken);
    final uri = _buildUri(url);
    _log("Delete URL -- '$uri'");
    _log("Delete Header -- '$header'");

    return _executeRequest(() => http.delete(uri, headers: header), 'Delete', url);
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
    if (!(await _hasNetwork())) {
      return ApiResponse(error: "No network available");
    }

    final header = await _getHeaders(sendToken);
    final uri = _buildUri(url);

    _log("Form URL -- '$uri'");
    _log("Form Header -- '$header'");

    final request = http.MultipartRequest(methodType, uri);
    request.headers.addAll(header);

    if (fields != null) {
      request.fields.addAll(fields);
      _log("Form Fields -- '$fields'");
    }

    if (singleFile != null && singleFileKey != null) {
      request.files.add(await http.MultipartFile.fromPath(singleFileKey, singleFile.path));
      _log("Form Single File -- '${singleFile.path}'");
    }

    if (multipleFiles != null && multipleFiles.isNotEmpty) {
      if (multipleFileKeysList != null && multipleFileKeysList.length == multipleFiles.length) {
        for (int i = 0; i < multipleFiles.length; i++) {
          request.files.add(await http.MultipartFile.fromPath(multipleFileKeysList[i], multipleFiles[i].path));
        }
      } else if (multipleFileKey != null) {
        for (var file in multipleFiles) {
          request.files.add(await http.MultipartFile.fromPath(multipleFileKey, file.path));
        }
      }
      _log("Form Multiple Files Count -- '${multipleFiles.length}'");
    }

    try {
      final streamedResponse = await request.send().timeout(config.timeout);
      final response = await http.Response.fromStream(streamedResponse);

      _log("Form Response Code -- '${response.statusCode}'");
      _log("Form Response -- '${response.body}'");

      await _handleUnauthorizedResponse(response.statusCode);

      return ApiResponse(
        body: response.body,
        headers: response.headers,
        statusCode: response.statusCode,
        error: (response.statusCode >= 200 && response.statusCode < 300) ? null : "${response.statusCode}",
      );
    } on SocketException {
      return ApiResponse(error: "No internet connection");
    } on TimeoutException {
      return ApiResponse(error: "Request timed out");
    } catch (e) {
      return ApiResponse(error: e.toString());
    }
  }
}
