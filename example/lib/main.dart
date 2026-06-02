import 'package:flutter/material.dart';
import 'package:flutter_api_handler/flutter_http_api_structure.dart';

void main() {
  // Initialize the API manager globally
  APIManager.initialize(
    ApiConfig(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      engine: HttpEngine.http, // Choose which package you want to use: HttpEngine.http or HttpEngine.dio
      timeout: const Duration(seconds: 15),
      enableLogging: true,
      tokenProvider: () async {
        return 'dummy_token_12345';
      },
      languageCodeProvider: () async {
        return 'en';
      },
      onUnauthorized: (statusCode) {
        debugPrint("User is unauthorized ($statusCode). Logging out...");
      },
    ),
  );


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ApiExampleScreen(),
    );
  }
}

class ApiExampleScreen extends StatefulWidget {
  const ApiExampleScreen({super.key});

  @override
  State<ApiExampleScreen> createState() => _ApiExampleScreenState();
}

class _ApiExampleScreenState extends State<ApiExampleScreen> {
  String _responseResult = "Press a button to call API";
  bool _isLoading = false;

  void _updateResult(String result) {
    setState(() {
      _responseResult = result;
      _isLoading = false;
    });
  }

  void _setLoading() {
    setState(() {
      _isLoading = true;
      _responseResult = "Loading...";
    });
  }

  Future<void> _callGetWithoutToken() async {
    _setLoading();
    // Getting posts. We don't send token for this public API.
    ApiResponse response = await APIManager.get(
      url: '/posts/1',
      sendToken: false, // Don't send token
    );

    if (response.isSuccess) {
      _updateResult("Success! Status: ${response.statusCode}\nBody: ${response.body}");
    } else {
      _updateResult("Error! Status: ${response.statusCode}\nMessage: ${response.error}");
    }
  }

  Future<void> _callPostWithToken() async {
    _setLoading();
    // Creating a post. We send token for this API (default sendToken: true).
    ApiResponse response = await APIManager.post(
      url: '/posts',
      data: {
        'title': 'foo',
        'body': 'bar',
        'userId': 1,
      },
    );

    if (response.isSuccess) {
      _updateResult("Success! Status: ${response.statusCode}\nBody: ${response.body}");
    } else {
      _updateResult("Error! Status: ${response.statusCode}\nMessage: ${response.error}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HttpManager Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _callGetWithoutToken,
              child: const Text('GET /posts/1 (Without Token)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _callPostWithToken,
              child: const Text('POST /posts (With Token)'),
            ),
            const SizedBox(height: 30),
            const Text("Response:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.shade200,
                  child: Text(_responseResult),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
