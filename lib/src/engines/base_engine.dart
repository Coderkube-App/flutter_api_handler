import 'dart:io';
import '../models/api_response.dart';

abstract class BaseApiEngine {
  Future<ApiResponse> get({
    required String url,
    bool sendToken = true,
  });

  Future<ApiResponse> post({
    required String url,
    Map<String, dynamic>? data,
    bool isNotEncoded = false,
    bool sendToken = true,
  });

  Future<ApiResponse> put({
    required String url,
    Map<String, dynamic>? data,
    bool sendToken = true,
  });

  Future<ApiResponse> patch({
    required String url,
    Map<String, dynamic>? data,
    bool sendToken = true,
  });

  Future<ApiResponse> delete({
    required String url,
    bool sendToken = true,
  });

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
  });
}
