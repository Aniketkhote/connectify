import "dart:async";
import "dart:convert";
// ignore: avoid_web_libraries_in_flutter
import "dart:html";

import "package:connectify/src/sockets/src/connection_status.dart";
import "package:connectify/src/sockets/src/socket_notifier.dart";
import "package:refreshed/get_core/get_core.dart";

/// A class for managing WebSocket connections.
class BaseWebSocket {
  /// Constructs a [BaseWebSocket] with the given [url], [ping] interval, and [allowSelfSigned] flag.
  BaseWebSocket(
    this.url, {
    this.ping = const Duration(seconds: 5),
    this.allowSelfSigned = true,
  }) {
    // Ensure proper URL format for WebSocket connection.
    url = url.startsWith("https")
        ? url.replaceAll("https:", "wss:")
        : url.replaceAll("http:", "ws:");
  }

  /// The URL of the WebSocket server.
  String url;

  /// The WebSocket connection.
  WebSocket? socket;

  /// Notifier for socket events.
  SocketNotifier? socketNotifier = SocketNotifier();

  /// The duration between ping requests.
  Duration ping;

  /// Flag indicating whether the object has been disposed.
  bool isDisposed = false;

  /// Flag indicating whether self-signed certificates are allowed.
  bool allowSelfSigned;

  /// The current status of the connection.
  ConnectionStatus? connectionStatus;

  /// Timer for sending ping requests.
  Timer? _t;

  /// Closes the WebSocket connection.
  void close([int? status, String? reason]) {
    socket?.close(status, reason);
  }

  /// Establishes a WebSocket connection.
  void connect() {
    try {
      connectionStatus = ConnectionStatus.connecting;
      socket = WebSocket(url);
      socket!.onOpen.listen((e) {
        socketNotifier?.open();
        _t = Timer?.periodic(ping, (t) {
          socket!.send("");
        });
        connectionStatus = ConnectionStatus.connected;
      });

      socket!.onMessage.listen((event) {
        socketNotifier!.notifyData(event.data);
      });

      socket!.onClose.listen((e) {
        _t?.cancel();

        connectionStatus = ConnectionStatus.closed;
        socketNotifier!.notifyClose(Close(e.reason, e.code));
      });
      socket!.onError.listen((event) {
        _t?.cancel();
        socketNotifier!.notifyError(Close(event.toString(), 0));
        connectionStatus = ConnectionStatus.closed;
      });
    } on Exception catch (e) {
      _t?.cancel();
      socketNotifier!.notifyError(Close(e.toString(), 500));
      connectionStatus = ConnectionStatus.closed;
      //  close(500, e.toString());
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
    send(jsonEncode({"type": event, "data": data}));
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
  void send(dynamic data) {
    if (connectionStatus == ConnectionStatus.closed) {
      connect();
    }
    if (socket != null && socket!.readyState == WebSocket.OPEN) {
      socket!.send(data);
    } else {
      Get.log("WebSocket not connected, message $data not sent");
    }
  }
}
