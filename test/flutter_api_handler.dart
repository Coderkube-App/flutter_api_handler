import 'package:flutter_api_handler/flutter_api_handler.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('HttpManager Tests', () {
    test('Initialization works correctly', () {
      final config = ApiConfig(
        baseUrl: 'https://api.example.com',
        enableLogging: false,
      );
      
      APIManager.initialize(config);
      expect(config.baseUrl, 'https://api.example.com');
    });

    test('ApiResponse parses correctly', () {
      final response = ApiResponse(
        statusCode: 200,
        body: '{"status": "success"}',
      );
      expect(response.isSuccess, true);
      expect(response.statusCode, 200);
      expect(response.body, '{"status": "success"}');
    });
    
    test('ApiResponse error status', () {
      final response = ApiResponse(
        statusCode: 404,
        error: '404',
      );
      expect(response.isSuccess, false);
      expect(response.error, '404');
    });
  });
}
