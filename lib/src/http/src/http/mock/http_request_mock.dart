import "package:connectify/src/http/src/http/interface/request_base.dart";
import "package:connectify/src/http/src/http/utils/body_decoder.dart";
import "package:connectify/src/http/src/request/request.dart";
import "package:connectify/src/http/src/response/response.dart";

/// A typedef representing a function signature for handling mock HTTP requests and responses.
///
/// The [MockClientHandler] typedef defines a function signature that takes a [Request] object
/// as input and returns a `Future` of [Response]. This function is used as a handler for mocking
/// HTTP requests and responses, allowing custom processing of requests and simulation of responses
/// in tests or mock scenarios.
typedef MockClientHandler = Future<Response> Function(Request request);

/// A mock HTTP client for testing purposes that allows custom handling of requests and responses.
class MockClient extends IClient {
  /// Creates a [MockClient] with a handler function that receives [Request]s and sends [Response]s.
  ///
  /// The [_handler] parameter is a function that defines the behavior of the client by transforming
  /// incoming requests and generating corresponding responses.
  MockClient(this._handler);

  /// The handler function that transforms requests and generates responses.
  final MockClientHandler _handler;

  @override
  Future<Response<T>> send<T>(Request<T> request) async {
    var requestBody = await request.bodyBytes.toBytes();
    var bodyBytes = requestBody.toStream();

    var response = await _handler(request);

    final stringBody = await bodyBytesToString(bodyBytes, response.headers!);

    var mimeType = response.headers!.containsKey("content-type")
        ? response.headers!["content-type"]
        : "";

    final body = bodyDecoded<T>(
      request,
      stringBody,
      mimeType,
    );
    return Response(
      headers: response.headers,
      request: request,
      statusCode: response.statusCode,
      statusText: response.statusText,
      bodyBytes: bodyBytes,
      body: body,
      bodyString: stringBody,
    );
  }

  @override
  void close() {}
}
