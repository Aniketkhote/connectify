import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:connectify/src/http/http.dart";
import "package:connectify/src/http/src/multipart/form_data.dart";

/// Represents an HTTP request.
///
/// This class encapsulates details of an HTTP request, including the request method,
/// URL, headers, body, and other relevant properties.
class Request<T> {

  /// Constructs a new [Request] instance.
  factory Request({
    required Uri url,
    required String method,
    required Map<String, String> headers,
    Stream<List<int>>? bodyBytes,
    bool followRedirects = true,
    int maxRedirects = 4,
    int? contentLength,
    FormData? files,
    bool persistentConnection = true,
    Decoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
  }) {
    if (followRedirects) {
      assert(maxRedirects > 0);
    }
    return Request._(
        url: url,
        method: method,
        bodyBytes: bodyBytes ??= <int>[].toStream(),
        headers: Map.from(headers),
        followRedirects: followRedirects,
        maxRedirects: maxRedirects,
        contentLength: contentLength,
        files: files,
        persistentConnection: persistentConnection,
        decoder: decoder,
        responseInterceptor: responseInterceptor,);
  }

  const Request._({
    required this.method,
    required this.bodyBytes,
    required this.url,
    required this.headers,
    required this.contentLength,
    required this.followRedirects,
    required this.maxRedirects,
    required this.files,
    required this.persistentConnection,
    required this.decoder,
    this.responseInterceptor,
  });
  /// Headers attach to this [Request]
  final Map<String, String> headers;

  /// The [Uri] from request
  final Uri url;

  /// The decoder function for decoding the response body.
  final Decoder<T>? decoder;

  /// The interceptor function for processing the response before decoding.
  final ResponseInterceptor<T>? responseInterceptor;

  /// The Http Method from this [Request]
  /// ex: `GET`,`POST`,`PUT`,`DELETE`
  final String method;

  /// The content length of the request body.
  final int? contentLength;

  /// The BodyBytesStream of body from this [Request]
  final Stream<List<int>> bodyBytes;

  /// When true, the client will follow redirects to resolves this [Request]
  final bool followRedirects;

  /// The maximum number of redirects if [followRedirects] is true.
  final int maxRedirects;

  /// Indicates whether the connection should be kept alive.
  final bool persistentConnection;

  /// The form data associated with the request, if any.
  final FormData? files;

  /// Creates a copy of this [Request] with the specified changes.
  Request<T> copyWith({
    Uri? url,
    String? method,
    Map<String, String>? headers,
    Stream<List<int>>? bodyBytes,
    bool? followRedirects,
    int? maxRedirects,
    int? contentLength,
    FormData? files,
    bool? persistentConnection,
    Decoder<T>? decoder,
    bool appendHeader = true,
    ResponseInterceptor<T>? responseInterceptor,
  }) {
    // If appendHeader is set to true, we will merge origin headers with that
    if (appendHeader && headers != null) {
      headers.addAll(this.headers);
    }

    return Request<T>._(
        url: url ?? this.url,
        method: method ?? this.method,
        bodyBytes: bodyBytes ?? this.bodyBytes,
        headers: headers == null ? this.headers : Map.from(headers),
        followRedirects: followRedirects ?? this.followRedirects,
        maxRedirects: maxRedirects ?? this.maxRedirects,
        contentLength: contentLength ?? this.contentLength,
        files: files ?? this.files,
        persistentConnection: persistentConnection ?? this.persistentConnection,
        decoder: decoder ?? this.decoder,
        responseInterceptor: responseInterceptor ?? this.responseInterceptor,);
  }
}

/// Extension methods for [List<int>] to convert it into a stream.
extension StreamExt on List<int> {
  /// Converts a [List<int>] into a broadcast stream of bytes.
  Stream<List<int>> toStream() => Stream.value(this).asBroadcastStream();
}

/// Extension methods for [Stream<List<int>>] for byte conversion.
extension BodyBytesStream on Stream<List<int>> {
  /// Converts a stream of bytes into a byte array.
  Future<Uint8List> toBytes() {
    var completer = Completer<Uint8List>();
    var sink = ByteConversionSink.withCallback(
      (bytes) => completer.complete(
        Uint8List.fromList(bytes),
      ),
    );
    listen((val) => sink.add(val),
        onError: completer.completeError,
        onDone: sink.close,
        cancelOnError: true,);
    return completer.future;
  }

  /// Converts a stream of bytes into a string using the specified encoding.
  Future<String> bytesToString([Encoding encoding = utf8]) =>
      encoding.decodeStream(this);
}
