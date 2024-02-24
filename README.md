# Connectify

Connectify, formerly known as GetConnect within the Refreshed ecosystem, is a specialized Flutter package dedicated to managing HTTP requests. Derived from the acclaimed Refreshed framework, Connectify maintains a lightweight footprint while offering robust capabilities for handling HTTP communications within your applications. With Connectify, developers can seamlessly integrate HTTP functionality, making it effortless to send requests, handle responses, and manage network interactions. By extracting this module from Refreshed, Connectify ensures a focused and optimized solution for HTTP connectivity, enabling developers to build efficient and responsive Flutter applications with ease.

## Features

- **Effortless Integration**: Seamless integration into Flutter applications for smooth HTTP functionality.
- **Request Handling**: Simplified methods for sending HTTP requests with ease.
- **Response Management**: Efficient handling of HTTP responses within the application.
- **Network Interaction Management**: Tools for managing network interactions and optimizing performance.
- **Lightweight Footprint**: Maintains a lightweight footprint, ensuring optimal performance without compromising on capabilities.

## Installation

You can install Connectify via pub by adding it to your `pubspec.yaml`:

```yaml
dependencies:
  connectify: ^1.x.x
```

Then, run flutter pub get to fetch the package.

## Example

```dart
import 'package:connectify/connectify.dart';

void main() {
  final connectify = Connectify();

  connectify.get('https://api.example.com/data').then((response) {
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
  }).catchError((error) {
    print('Error: $error');
  });
}
```
