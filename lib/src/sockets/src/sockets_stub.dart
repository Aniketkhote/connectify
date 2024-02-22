import 'socket_notifier.dart';

/// Base class for WebSocket implementation.
///
/// This class provides a base structure for WebSocket functionality,
/// with methods and properties commonly used in WebSocket connections.
///
/// To use this class, you need either `dart:io` or `dart:html` libraries.
///
/// Example usage:
/// ```dart
/// var socket = BaseWebSocket('ws://example.com/socket');
/// await socket.connect();
/// socket.onOpen((event) {
///   print('WebSocket connection opened.');
/// });
/// socket.onMessage((event) {
///   print('Message received: $event');
/// });
/// socket.send('Hello, WebSocket!');
/// ```
class BaseWebSocket {
  String url;
  Duration ping;
  bool allowSelfSigned;

  /// Creates a new instance of [BaseWebSocket].
  ///
  /// The [url] parameter specifies the WebSocket server URL.
  ///
  /// The optional [ping] parameter specifies the interval for sending
  /// ping messages to the server. The default is 5 seconds.
  ///
  /// The optional [allowSelfSigned] parameter specifies whether to allow
  /// self-signed certificates when using secure WebSocket connections.
  /// The default is `true`.
  BaseWebSocket(
    this.url, {
    this.ping = const Duration(seconds: 5),
    this.allowSelfSigned = true,
  }) {
    throw 'To use sockets you need dart:io or dart:html';
  }

  /// Connects to the WebSocket server.
  ///
  /// Throws an error indicating that `dart:io` or `dart:html` is required
  /// to use WebSocket functionality.
  Future connect() async {
    throw 'To use sockets you need dart:io or dart:html';
  }

  /// Sets up a callback function to be called when the WebSocket connection is opened.
  ///
  /// Throws an error indicating that `dart:io` or `dart:html` is required
  /// to use WebSocket functionality.
  void onOpen(OpenSocket fn) {
    throw 'To use sockets you need dart:io or dart:html';
  }

  /// Sets up a callback function to be called when the WebSocket connection is closed.
  ///
  /// Throws an error indicating that `dart:io` or `dart:html` is required
  /// to use WebSocket functionality.
  void onClose(CloseSocket fn) {
    throw 'To use sockets you need dart:io or dart:html';
  }

  /// Sets up a callback function to be called when an error occurs on the WebSocket connection.
  ///
  /// Throws an error indicating that `dart:io` or `dart:html` is required
  /// to use WebSocket functionality.
  void onError(CloseSocket fn) {
    throw 'To use sockets you need dart:io or dart:html';
  }

  /// Sets up a callback function to be called when a message is received on the WebSocket connection.
  ///
  /// Throws an error indicating that `dart:io` or `dart:html` is required
  /// to use WebSocket functionality.
  void onMessage(MessageSocket fn) {
    throw 'To use sockets you need dart:io or dart:html';
  }

  /// Sets up a callback function to be called when a specific event occurs on the WebSocket connection.
  ///
  /// Throws an error indicating that `dart:io` or `dart:html` is required
  /// to use WebSocket functionality.
  void on(String event, MessageSocket message) {
    throw 'To use sockets you need dart:io or dart:html';
  }

  /// Closes the WebSocket connection.
  ///
  /// Throws an error indicating that `dart:io` or `dart:html` is required
  /// to use WebSocket functionality.
  void close([int? status, String? reason]) {
    throw 'To use sockets you need dart:io or dart:html';
  }

  /// Sends data over the WebSocket connection.
  ///
  /// Throws an error indicating that `dart:io` or `dart:html` is required
  /// to use WebSocket functionality.
  void send(dynamic data) async {
    throw 'To use sockets you need dart:io or dart:html';
  }

  /// Disposes the resources associated with the WebSocket connection.
  ///
  /// Throws an error indicating that `dart:io` or `dart:html` is required
  /// to use WebSocket functionality.
  void dispose() {
    throw 'To use sockets you need dart:io or dart:html';
  }

  /// Emits an event with associated data over the WebSocket connection.
  ///
  /// Throws an error indicating that `dart:io` or `dart:html` is required
  /// to use WebSocket functionality.
  void emit(String event, dynamic data) {
    throw 'To use sockets you need dart:io or dart:html';
  }
}
