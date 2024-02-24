import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:refreshed/get_core/get_core.dart';

import 'connection_status.dart';
import 'socket_notifier.dart';

/// A base class for managing WebSocket connections.
class BaseWebSocket {
  /// The URL of the WebSocket server.
  String url;

  /// The WebSocket connection.
  WebSocket? socket;

  /// Notifier for socket events.
  SocketNotifier? socketNotifier = SocketNotifier();

  /// Flag indicating whether the object has been disposed.
  bool isDisposed = false;

  /// The duration between ping requests.
  final Duration ping;

  /// Flag indicating whether self-signed certificates are allowed.
  final bool allowSelfSigned;

  /// The current status of the connection.
  ConnectionStatus? connectionStatus;

  /// Constructs a [BaseWebSocket] with the given [url], [ping] interval, and [allowSelfSigned] flag.
  BaseWebSocket(
    this.url, {
    this.ping = const Duration(seconds: 5),
    this.allowSelfSigned = true,
  });

  /// Closes the WebSocket connection.
  void close([int? status, String? reason]) {
    socket?.close(status, reason);
  }

  /// Establishes a WebSocket connection.
  Future connect() async {
    if (isDisposed) {
      socketNotifier = SocketNotifier();
    }
    try {
      connectionStatus = ConnectionStatus.connecting;
      socket = allowSelfSigned
          ? await _connectForSelfSignedCert(url)
          : await WebSocket.connect(url);

      socket!.pingInterval = ping;
      socketNotifier?.open();
      connectionStatus = ConnectionStatus.connected;

      socket!.listen((data) {
        socketNotifier!.notifyData(data);
      }, onError: (err) {
        socketNotifier!.notifyError(Close(err.toString(), 1005));
      }, onDone: () {
        connectionStatus = ConnectionStatus.closed;
        socketNotifier!
            .notifyClose(Close('Connection Closed', socket!.closeCode));
      }, cancelOnError: true);
      return;
    } on SocketException catch (e) {
      connectionStatus = ConnectionStatus.closed;
      socketNotifier!
          .notifyError(Close(e.osError!.message, e.osError!.errorCode));
      return;
    }
  }

  /// Disposes the WebSocket connection.
  void dispose() {
    socketNotifier!.dispose();
    socketNotifier = null;
    isDisposed = true;
  }

  /// Emits an event with associated [data] over the WebSocket connection.
  void emit(String event, dynamic data) {
    send(jsonEncode({'type': event, 'data': data}));
  }

  /// Registers a callback [message] to handle incoming messages with a specific [event] type.
  void on(String event, MessageSocket message) {
    socketNotifier!.addEvents(event, message);
  }

  /// Registers a callback [fn] to handle the WebSocket connection closure.
  void onClose(CloseSocket fn) {
    socketNotifier!.addCloses(fn);
  }

  /// Registers a callback [fn] to handle errors that occur within the WebSocket connection.
  void onError(CloseSocket fn) {
    socketNotifier!.addErrors(fn);
  }

  /// Registers a callback [fn] to handle incoming messages.
  void onMessage(MessageSocket fn) {
    socketNotifier!.addMessages(fn);
  }

  /// Registers a callback [fn] to handle the WebSocket connection opening.
  void onOpen(OpenSocket fn) {
    socketNotifier!.open = fn;
  }

  /// Sends [data] over the WebSocket connection.
  void send(dynamic data) async {
    if (connectionStatus == ConnectionStatus.closed) {
      await connect();
    }

    if (socket != null) {
      socket!.add(data);
    }
  }

  // Private method to establish a WebSocket connection allowing self-signed certificates.
  Future<WebSocket> _connectForSelfSignedCert(String url) async {
    try {
      var r = Random();
      var key = base64.encode(List<int>.generate(16, (_) => r.nextInt(255)));
      var client = HttpClient(context: SecurityContext());
      client.badCertificateCallback = (cert, host, port) {
        Get.log(
            'BaseWebSocket: Allow self-signed certificate => $host:$port. ');
        return true;
      };

      var request = await client.getUrl(Uri.parse(url))
        ..headers.add('Connection', 'Upgrade')
        ..headers.add('Upgrade', 'websocket')
        ..headers.add('Cache-Control', 'no-cache')
        ..headers.add('Sec-WebSocket-Version', '13')
        ..headers.add('Sec-WebSocket-Key', key.toLowerCase());

      var response = await request.close();
      var socket = await response.detachSocket();
      var webSocket = WebSocket.fromUpgradedSocket(
        socket,
        serverSide: false,
      );

      return webSocket;
    } on Exception catch (_) {
      rethrow;
    }
  }
}
