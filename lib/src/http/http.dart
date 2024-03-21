import "dart:async";
import "dart:convert";
import "dart:io";

import "package:connectify/src/http/src/certificates/certificates.dart";
import "package:connectify/src/http/src/exceptions/exceptions.dart";
import "package:connectify/src/http/src/http/interface/request_base.dart";
import "package:connectify/src/http/src/http/request/http_request.dart";
import "package:connectify/src/http/src/interceptors/get_modifiers.dart";
import "package:connectify/src/http/src/multipart/form_data.dart";
import "package:connectify/src/http/src/request/request.dart";
import "package:connectify/src/http/src/response/response.dart";
import "package:connectify/src/http/src/status/http_status.dart";

/// Defines a decoder function to convert dynamic data into type T.
typedef Decoder<T> = T Function(T data);

/// Represents a progress function that takes a double value indicating the progress percentage.
typedef Progress = Function(double percent);

/// Represents a response interceptor function that intercepts and potentially modifies
/// the response before it's processed.
typedef ResponseInterceptor<T> = Future<Response<T>?> Function(
  Request<T> request,
  Type targetType,
  HttpClientResponse response,
);

/// A customizable HTTP client for making HTTP requests.
///
/// Use the [GetHttpClient] class to configure and send HTTP requests.
/// You can customize various aspects of the HTTP requests, such as user agent,
/// timeout, follow redirects, authentication, request and response modifiers,
/// and more.
class GetHttpClient {
  /// Creates a new instance of [GetHttpClient].
  GetHttpClient({
    this.userAgent = "connectify-client",
    this.timeout = const Duration(seconds: 8),
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.sendUserAgent = false,
    this.sendContentLength = true,
    this.maxAuthRetries = 1,
    bool allowAutoSignedCert = false,
    this.baseUrl,
    List<TrustedCertificate>? trustedCertificates,
    bool withCredentials = false,
    String Function(Uri url)? findProxy,
    IClient? customClient,
  })  : _httpClient = customClient ??
            createHttp(
              allowAutoSignedCert: allowAutoSignedCert,
              trustedCertificates: trustedCertificates,
              withCredentials: withCredentials,
              findProxy: findProxy,
            ),
        _modifier = GetModifier();

  /// The user agent string to be sent with the requests.
  String userAgent;

  /// The base URL used for constructing request URLs.
  String? baseUrl;

  /// The duration before an HTTP request times out.
  Duration timeout;

  /// Whether to automatically follow redirects.
  bool followRedirects;

  /// The maximum number of redirects to follow.
  int maxRedirects;

  /// The maximum number of authentication retries.
  int maxAuthRetries;

  /// Whether to send the user agent header with requests.
  bool sendUserAgent;

  /// Whether to send the content length header with requests.
  bool sendContentLength;

  /// Whether to handle errors safely.
  ///
  /// If set to true, exceptions during requests will not throw errors but
  /// will return a response with an error message instead. Default is true.
  bool errorSafety = true;

  final IClient _httpClient;

  final GetModifier _modifier;

  String Function(Uri url)? findProxy;

  String defaultContentType = "application/json; charset=utf-8";

  Decoder? defaultDecoder;
  ResponseInterceptor? defaultResponseInterceptor;

  /// Adds an authenticator for the HTTP requests.
  ///
  /// The [auth] parameter should be an instance of [RequestModifier] for authentication.
  void addAuthenticator<T>(RequestModifier<T> auth) {
    _modifier.authenticator = auth as RequestModifier;
  }

  /// Adds a request modifier for the HTTP requests.
  ///
  /// The [interceptor] parameter should be an instance of [RequestModifier] for request modifications.
  void addRequestModifier<T>(RequestModifier<T> interceptor) {
    _modifier.addRequestModifier<T>(interceptor);
  }

  /// Removes a request modifier from the HTTP client.
  ///
  /// The [interceptor] parameter should be the same instance previously added using [addRequestModifier].
  void removeRequestModifier<T>(RequestModifier<T> interceptor) {
    _modifier.removeRequestModifier(interceptor);
  }

  /// Adds a response modifier for the HTTP responses.
  ///
  /// The [interceptor] parameter should be an instance of [ResponseModifier] for response modifications.
  void addResponseModifier<T>(ResponseModifier<T> interceptor) {
    _modifier.addResponseModifier(interceptor);
  }

  /// Removes a response modifier from the HTTP client.
  ///
  /// The [interceptor] parameter should be the same instance previously added using [addResponseModifier].
  void removeResponseModifier<T>(ResponseModifier<T> interceptor) {
    _modifier.removeResponseModifier<T>(interceptor);
  }

  /// Creates a URI object with the specified URL and query parameters.
  ///
  /// If a [baseUrl] is provided, the URL is appended to it. The [query] parameter
  /// contains key-value pairs for query parameters.
  Uri createUri(String? url, Map<String, dynamic>? query) {
    if (baseUrl != null) {
      url = baseUrl! + (url ?? "");
    }
    final Uri uri = Uri.parse(url!);
    if (query != null) {
      return uri.replace(queryParameters: query);
    }
    return uri;
  }

  Future<Request<T>> _requestWithBody<T>(
    String? url,
    String? contentType,
    body,
    String method,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
    Progress? uploadProgress,
  ) async {
    List<int>? bodyBytes;
    Stream<List<int>>? bodyStream;
    final Map<String, String> headers = <String, String>{};

    if (sendUserAgent) {
      headers["user-agent"] = userAgent;
    }

    if (body is FormData) {
      bodyBytes = await body.toBytes();
      headers["content-length"] = bodyBytes.length.toString();
      headers["content-type"] =
          "multipart/form-data; boundary=${body.boundary}";
    } else if (contentType != null &&
        contentType.toLowerCase() == "application/x-www-form-urlencoded" &&
        body is Map) {
      final List parts = <dynamic>[];
      (body as Map<String, dynamic>).forEach((String key, value) {
        parts.add("${Uri.encodeQueryComponent(key)}="
            "${Uri.encodeQueryComponent(value.toString())}");
      });
      final String formData = parts.join("&");
      bodyBytes = utf8.encode(formData);
      _setContentLength(headers, bodyBytes.length);
      headers["content-type"] = contentType;
    } else if (body is Map || body is List) {
      final String jsonString = json.encode(body);
      bodyBytes = utf8.encode(jsonString);
      _setContentLength(headers, bodyBytes.length);
      headers["content-type"] = contentType ?? defaultContentType;
    } else if (body is String) {
      bodyBytes = utf8.encode(body);
      _setContentLength(headers, bodyBytes.length);

      headers["content-type"] = contentType ?? defaultContentType;
    } else if (body == null) {
      _setContentLength(headers, 0);
      headers["content-type"] = contentType ?? defaultContentType;
    } else {
      if (!errorSafety) {
        throw UnexpectedFormat("body cannot be ${body.runtimeType}");
      }
    }

    if (bodyBytes != null) {
      bodyStream = _trackProgress(bodyBytes, uploadProgress);
    }

    final Uri uri = createUri(url, query);
    return Request<T>(
      method: method,
      url: uri,
      headers: headers,
      bodyBytes: bodyStream,
      contentLength: bodyBytes?.length ?? 0,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      decoder: decoder,
      responseInterceptor: responseInterceptor,
    );
  }

  void _setContentLength(Map<String, String> headers, int contentLength) {
    if (sendContentLength) {
      headers["content-length"] = "$contentLength";
    }
  }

  Stream<List<int>> _trackProgress(
    List<int> bodyBytes,
    Progress? uploadProgress,
  ) {
    int total = 0;
    final int length = bodyBytes.length;

    final Stream<List<int>> byteStream =
        Stream.fromIterable(bodyBytes.map((int i) => <int>[i]))
            .transform<List<int>>(
      StreamTransformer.fromHandlers(
        handleData: (List<int> data, EventSink<List<int>> sink) {
          total += data.length;
          if (uploadProgress != null) {
            final double percent = total / length * 100;
            uploadProgress(percent);
          }
          sink.add(data);
        },
      ),
    );
    return byteStream;
  }

  void _setSimpleHeaders(
    Map<String, String> headers,
    String? contentType,
  ) {
    headers["content-type"] = contentType ?? defaultContentType;
    if (sendUserAgent) {
      headers["user-agent"] = userAgent;
    }
  }

  Future<Response<T>> _performRequest<T>(
    HandlerExecute<T> handler, {
    bool authenticate = false,
    int requestNumber = 1,
    Map<String, String>? headers,
  }) async {
    final Request<T> request = await handler();

    headers?.forEach((String key, String value) {
      request.headers[key] = value;
    });

    if (authenticate) await _modifier.authenticator!(request);
    final Request<T> newRequest = await _modifier.modifyRequest<T>(request);

    _httpClient.timeout = timeout;
    try {
      final Response<T> response = await _httpClient.send<T>(newRequest);

      final Response<T> newResponse =
          await _modifier.modifyResponse<T>(newRequest, response);

      if (HttpStatus.unauthorized == newResponse.statusCode &&
          _modifier.authenticator != null &&
          requestNumber <= maxAuthRetries) {
        return _performRequest<T>(
          handler,
          authenticate: true,
          requestNumber: requestNumber + 1,
          headers: newRequest.headers,
        );
      } else if (HttpStatus.unauthorized == newResponse.statusCode) {
        if (!errorSafety) {
          throw UnauthorizedException();
        } else {
          return Response<T>(
            request: newRequest,
            headers: newResponse.headers,
            statusCode: newResponse.statusCode,
            body: newResponse.body,
            bodyBytes: newResponse.bodyBytes,
            bodyString: newResponse.bodyString,
            statusText: newResponse.statusText,
          );
        }
      }

      return newResponse;
    } on Exception catch (err) {
      if (!errorSafety) {
        throw GetHttpException(err.toString());
      } else {
        return Response<T>(
          request: newRequest,
          headers: null,
          statusText: "$err",
        );
      }
    }
  }

  Future<Request<T>> _get<T>(
    String url,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
  ) {
    final Map<String, String> headers = <String, String>{};
    _setSimpleHeaders(headers, contentType);
    final Uri uri = createUri(url, query);

    return Future.value(
      Request<T>(
        method: "get",
        url: uri,
        headers: headers,
        decoder: decoder ?? (defaultDecoder as Decoder<T>?),
        responseInterceptor: _responseInterceptor(responseInterceptor),
        contentLength: 0,
        followRedirects: followRedirects,
        maxRedirects: maxRedirects,
      ),
    );
  }

  ResponseInterceptor<T>? _responseInterceptor<T>(
    ResponseInterceptor<T>? actual,
  ) {
    if (actual != null) return actual;
    final ResponseInterceptor? defaultInterceptor = defaultResponseInterceptor;
    return defaultInterceptor != null
        ? (
            Request<T> request,
            Type targetType,
            HttpClientResponse response,
          ) async =>
            await defaultInterceptor(request, targetType, response)
                as Response<T>?
        : null;
  }

  Future<Request<T>> _request<T>(
    String? url,
    String method, {
    required body,
    required Map<String, dynamic>? query,
    required Progress? uploadProgress,
    String? contentType,
    Decoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
  }) =>
      _requestWithBody<T>(
        url,
        contentType,
        body,
        method,
        query,
        decoder ?? (defaultDecoder as Decoder<T>?),
        _responseInterceptor(responseInterceptor),
        uploadProgress,
      );

  Request<T> _delete<T>(
    String url,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
  ) {
    final Map<String, String> headers = <String, String>{};
    _setSimpleHeaders(headers, contentType);
    final Uri uri = createUri(url, query);

    return Request<T>(
      method: "delete",
      url: uri,
      headers: headers,
      decoder: decoder ?? (defaultDecoder as Decoder<T>?),
      responseInterceptor: _responseInterceptor(responseInterceptor),
    );
  }

  /// Sends an HTTP request.
  ///
  /// This method sends the specified [request] and returns a [Future] that resolves
  /// to a [Response] object containing the result of the request.
  ///
  /// The [request] parameter should be an instance of [Request] with the desired
  /// configuration for the HTTP request.
  ///
  /// If an error occurs during the request and the `errorSafety` flag is not set,
  /// it throws a [GetHttpException]. Otherwise, it returns a [Response] object with
  /// an error message.
  Future<Response<T>> send<T>(Request<T> request) async {
    try {
      final Response<T> response =
          await _performRequest<T>(() => Future.value(request));
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(
        Response<T>(
          statusText: "Can not connect to server. Reason: $e",
        ),
      );
    }
  }

  /// Performs an HTTP PATCH request.
  ///
  /// This method sends an HTTP PATCH request to the specified [url] with optional [body],
  /// [contentType], [headers], [query], [decoder], [responseInterceptor], and [uploadProgress].
  ///
  /// Returns a [Future] that resolves to a [Response] object containing the result of the request.
  Future<Response<T>> patch<T>(
    String url, {
    body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
    Progress? uploadProgress,
  }) async {
    try {
      final Response<T> response = await _performRequest<T>(
        () => _request<T>(
          url,
          "patch",
          contentType: contentType,
          body: body,
          query: query,
          decoder: decoder,
          responseInterceptor: responseInterceptor,
          uploadProgress: uploadProgress,
        ),
        headers: headers,
      );
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(
        Response<T>(
          statusText: "Can not connect to server. Reason: $e",
        ),
      );
    }
  }

  /// Performs an HTTP POST request.
  ///
  /// This method sends an HTTP POST request to the specified [url] with optional [body],
  /// [contentType], [headers], [query], [decoder], [responseInterceptor], and [uploadProgress].
  ///
  /// Returns a [Future] that resolves to a [Response] object containing the result of the request.
  Future<Response<T>> post<T>(
    String? url, {
    body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
    Progress? uploadProgress,
  }) async {
    try {
      final Response<T> response = await _performRequest<T>(
        () => _request<T>(
          url,
          "post",
          contentType: contentType,
          body: body,
          query: query,
          decoder: decoder,
          responseInterceptor: responseInterceptor,
          uploadProgress: uploadProgress,
        ),
        headers: headers,
      );
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(
        Response<T>(
          statusText: "Can not connect to server. Reason: $e",
        ),
      );
    }
  }

  /// Performs an HTTP request with the specified [method].
  ///
  /// This method sends an HTTP request with the specified [method] to the specified [url]
  /// with optional [body], [contentType], [headers], [query], [decoder], [responseInterceptor],
  /// and [uploadProgress].
  ///
  /// Returns a [Future] that resolves to a [Response] object containing the result of the request.
  Future<Response<T>> request<T>(
    String url,
    String method, {
    body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
    Progress? uploadProgress,
  }) async {
    try {
      final Response<T> response = await _performRequest<T>(
        () => _request<T>(
          url,
          method,
          contentType: contentType,
          query: query,
          body: body,
          decoder: decoder,
          responseInterceptor: responseInterceptor,
          uploadProgress: uploadProgress,
        ),
        headers: headers,
      );
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(
        Response<T>(
          statusText: "Can not connect to server. Reason: $e",
        ),
      );
    }
  }

  /// Performs an HTTP PUT request.
  ///
  /// This method sends an HTTP PUT request to the specified [url] with optional [body],
  /// [contentType], [headers], [query], [decoder], [responseInterceptor], and [uploadProgress].
  ///
  /// Returns a [Future] that resolves to a [Response] object containing the result of the request.
  Future<Response<T>> put<T>(
    String url, {
    body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
    Progress? uploadProgress,
  }) async {
    try {
      final Response<T> response = await _performRequest<T>(
        () => _request<T>(
          url,
          "put",
          contentType: contentType,
          query: query,
          body: body,
          decoder: decoder,
          responseInterceptor: responseInterceptor,
          uploadProgress: uploadProgress,
        ),
        headers: headers,
      );
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(
        Response<T>(
          statusText: "Can not connect to server. Reason: $e",
        ),
      );
    }
  }

  /// Performs an HTTP GET request.
  ///
  /// This method sends an HTTP GET request to the specified [url] with optional [headers],
  /// [contentType], [query], [decoder], and [responseInterceptor].
  ///
  /// Returns a [Future] that resolves to a [Response] object containing the result of the request.
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
  }) async {
    try {
      final Response<T> response = await _performRequest<T>(
        () => _get<T>(url, contentType, query, decoder, responseInterceptor),
        headers: headers,
      );
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(
        Response<T>(
          statusText: "Can not connect to server. Reason: $e",
        ),
      );
    }
  }

  /// Performs an HTTP DELETE request.
  ///
  /// This method sends an HTTP DELETE request to the specified [url] with optional [headers],
  /// [contentType], [query], [decoder], and [responseInterceptor].
  ///
  /// Returns a [Future] that resolves to a [Response] object containing the result of the request.
  Future<Response<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
  }) async {
    try {
      final Response<T> response = await _performRequest<T>(
        () async =>
            _delete<T>(url, contentType, query, decoder, responseInterceptor),
        headers: headers,
      );
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(
        Response<T>(
          statusText: "Can not connect to server. Reason: $e",
        ),
      );
    }
  }

  /// Closes the underlying HTTP client connection.
  void close() {
    _httpClient.close();
  }
}
