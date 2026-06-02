# flutter_api_handler

A robust and highly customizable Flutter package for standardizing HTTP API calls. It simplifies making requests, handling responses, managing timeouts, dynamic headers, and token-based authentication.

## Features

- **Multi-Engine Support:** Choose between `http` and `dio` packages as your networking engine.
- **Standardized API Calls:** Simplified methods for `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, and `Multipart/Form` requests across both engines.
- **Dynamic Configuration:** Configure base URLs, tokens, headers, and timeouts dynamically across the app.
- **Error Handling:** Built-in network connectivity checks, advanced error mapping (especially for Dio), and custom unauthorized (401) response handling.
- **Clean Response Model:** `ApiResponse` model to standardize the response parsing (status codes, body, errors, headers).
- **Integrated Logging:** Advanced request and response logging for easy debugging.

## Getting started

Add `flutter_api_handler` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_api_handler: ^0.0.1
```

## Usage

### 1. Initialization

Before making any requests, initialize the `HttpManager` with an `ApiConfig`. You can choose the engine using the `engine` property.

#### Using standard `http` engine:
```dart
import 'package:flutter_api_handler/flutter_api_handler.dart';

void main() {
  HttpManager.initialize(
    ApiConfig(
      baseUrl: 'https://api.yourdomain.com/v1',
      engine: HttpEngine.http, // Default is HttpEngine.http
      timeout: const Duration(seconds: 30),
      enableLogging: true,
      tokenProvider: () async => 'your_auth_token_here',
      onUnauthorized: (statusCode) => print("Unauthorized!"),
    ),
  );
  runApp(const MyApp());
}
```

#### Using advanced `dio` engine:
```dart
void main() {
  HttpManager.initialize(
    ApiConfig(
      baseUrl: 'https://api.yourdomain.com/v1',
      engine: HttpEngine.dio, // Switch to Dio for advanced features like interceptors
      timeout: const Duration(seconds: 30),
      enableLogging: true,
      tokenProvider: () async => 'your_auth_token_here',
    ),
  );
  runApp(const MyApp());
}
```

### 2. Making Requests

Once initialized, use `HttpManager` to perform requests. The manager returns an `ApiResponse` object.

#### GET Request
```dart
ApiResponse response = await HttpManager.get(
  url: '/public/posts',
  sendToken: false, 
);

if (response.isSuccess) {
  print("Data: ${response.body}");
} else {
  print("Error: ${response.error}");
}
```

#### POST Request
```dart
ApiResponse response = await HttpManager.post(
  url: '/users/update-profile',
  data: {'name': 'John Doe'},
);
```

#### Multipart/Form Data
```dart
File imageFile = File('path/to/image.png');

ApiResponse response = await HttpManager.formRequest(
  methodType: 'POST',
  url: '/users/upload-profile-picture',
  singleFile: imageFile,
  singleFileKey: 'profile_image',
);
```

## Class Reference

### ApiConfig

| Property | Type | Description |
|---|---|---|
| `baseUrl` | `String` | Base URL for the API. |
| `engine` | `HttpEngine` | Choose between `.http` and `.dio`. |
| `tokenProvider` | `FutureOr<String?> Function()?` | Function to dynamically fetch the auth token. |
| `languageCodeProvider` | `FutureOr<String> Function()?` | Function to dynamically fetch the app language code. |
| `onUnauthorized` | `FutureOr<void> Function(int statusCode)?` | Callback triggered when a 401 or 404 response is received. |
| `defaultHeaders` | `Map<String, String>?` | Additional default headers. |
| `timeout` | `Duration` | Connection timeout (default 30 seconds). |
| `enableLogging` | `bool` | Whether to enable console logging (default true). |

### ApiResponse

| Property | Type | Description |
|---|---|---|
| `body` | `String?` | The response body. |
| `headers` | `Map<String, String>?` | The response headers. |
| `statusCode` | `int?` | The HTTP status code. |
| `error` | `String?` | Error description if the request failed. |
| `isSuccess` | `bool` | Returns `true` if `statusCode` is between 200 and 299. |

## Additional information

For contributions or issues, please visit the repository.

