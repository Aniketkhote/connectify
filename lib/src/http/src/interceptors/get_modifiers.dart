import "dart:async";

import "package:connectify/src/http/src/request/request.dart";
import "package:connectify/src/http/src/response/response.dart";

/// Signature for a function that modifies an HTTP request.
///
/// The function takes a [Request] object and returns a modified [Request] object.
typedef RequestModifier<T> = FutureOr<Request<T>> Function(Request<T?> request);

/// Signature for a function that modifies an HTTP response.
///
/// The function takes a [Request] object and the corresponding [Response] object,
/// and returns a modified [Response] object.
typedef ResponseModifier<T> = FutureOr<Response<T>> Function(
    Request<T?> request, Response<T?> response,);

/// Signature for a function that executes a handler.
///
/// The function returns a [Request] object.
typedef HandlerExecute<T> = Future<Request<T>> Function();

/// Manages request and response modifiers for HTTP requests.
///
/// It allows adding and removing request and response modifiers,
/// and provides methods to modify requests and responses accordingly.
class GetModifier<S> {
  final _requestModifiers = <RequestModifier>[];
  final _responseModifiers = <ResponseModifier>[];
  RequestModifier? authenticator;

  /// Adds a request modifier to the list of modifiers.
  void addRequestModifier<T>(RequestModifier<T> interceptor) {
    _requestModifiers.add(interceptor as RequestModifier);
  }

  /// Removes a request modifier from the list of modifiers.
  void removeRequestModifier<T>(RequestModifier<T> interceptor) {
    _requestModifiers.remove(interceptor);
  }

  /// Adds a response modifier to the list of modifiers.
  void addResponseModifier<T>(ResponseModifier<T> interceptor) {
    _responseModifiers.add(interceptor as ResponseModifier);
  }

  /// Removes a response modifier from the list of modifiers.
  void removeResponseModifier<T>(ResponseModifier<T> interceptor) {
    _requestModifiers.remove(interceptor);
  }

  /// Modifies the HTTP request using registered request modifiers.
  ///
  /// Returns the modified [Request] object.
  Future<Request<T>> modifyRequest<T>(Request<T> request) async {
    var newRequest = request;
    if (_requestModifiers.isNotEmpty) {
      for (var interceptor in _requestModifiers) {
        newRequest = await interceptor(newRequest) as Request<T>;
      }
    }

    return newRequest;
  }

  /// Modifies the HTTP response using registered response modifiers.
  ///
  /// Returns the modified [Response] object.
  Future<Response<T>> modifyResponse<T>(
      Request<T> request, Response<T> response,) async {
    var newResponse = response;
    if (_responseModifiers.isNotEmpty) {
      for (var interceptor in _responseModifiers) {
        newResponse = await interceptor(request, response) as Response<T>;
      }
    }

    return newResponse;
  }
}
