import "package:connectify/src/http/http.dart";
import "package:connectify/src/http/src/certificates/certificates.dart";
import "package:connectify/src/http/src/exceptions/exceptions.dart";
import "package:connectify/src/http/src/response/response.dart";
import "package:connectify/src/sockets/sockets.dart";
import "package:refreshed/get_instance/get_instance.dart";

export "http/http.dart";
export "http/src/certificates/certificates.dart";
export "http/src/multipart/form_data.dart";
export "http/src/multipart/multipart_file.dart";
export "http/src/response/response.dart";
export "sockets/sockets.dart";

/// Interface defining methods for making HTTP requests and WebSocket connections.
///
/// This interface provides a set of abstract methods for performing various HTTP
/// operations such as GET, POST, PUT, DELETE, PATCH, as well as executing GraphQL
/// queries and mutations. Additionally, it includes a method for establishing WebSocket
/// connections.
abstract class GetConnectInterface with GetLifeCycleMixin {
  List<GetSocket>? sockets;
  GetHttpClient get httpClient;

  /// Performs a GET request.
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  });

  /// Makes a generic HTTP request.
  Future<Response<T>> request<T>(
    String url,
    String method, {
    body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  });

  /// Sends a POST request.
  Future<Response<T>> post<T>(
    String url,
    body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  });

  /// Executes a PUT request.
  Future<Response<T>> put<T>(
    String url,
    body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  });

  /// Sends a DELETE request.
  Future<Response<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  });

  /// Executes a PATCH request.
  Future<Response<T>> patch<T>(
    String url,
    body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  });

  /// Executes a GraphQL query.
  Future<GraphQLResponse<T>> query<T>(
    String query, {
    String? url,
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
  });

  /// Executes a GraphQL mutation.
  Future<GraphQLResponse<T>> mutation<T>(
    String mutation, {
    String? url,
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
  });

  /// Establishes a WebSocket connection.
  GetSocket socket(
    String url, {
    Duration ping = const Duration(seconds: 5),
  });
}

/// A class for managing HTTP connections.
class GetConnect extends GetConnectInterface {
  /// Constructs a new [GetConnect] instance with default configurations.
  ///
  /// [userAgent] sets the user agent string for HTTP requests.
  /// [timeout] sets the maximum duration to wait for a response.
  /// [followRedirects] determines whether to follow HTTP redirects.
  /// [maxRedirects] sets the maximum number of HTTP redirects to follow.
  /// [sendUserAgent] determines whether to send the user agent string in requests.
  /// [maxAuthRetries] sets the maximum number of authentication retries.
  /// [allowAutoSignedCert] determines whether to allow automatically signed certificates.
  /// [withCredentials] determines whether to include credentials in cross-origin requests.
  GetConnect({
    this.userAgent = "connectify-client",
    this.timeout = const Duration(seconds: 5),
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.sendUserAgent = false,
    this.maxAuthRetries = 1,
    this.allowAutoSignedCert = false,
    this.withCredentials = false,
  });

  /// The user agent string for HTTP requests.
  String userAgent;

  /// Determines whether to send the user agent string in requests.
  bool sendUserAgent;

  /// The base URL for HTTP requests.
  String? baseUrl;

  /// The default content type for HTTP requests.
  String defaultContentType = "application/json; charset=utf-8";

  /// Determines whether to follow HTTP redirects.
  bool followRedirects;

  /// The maximum number of HTTP redirects to follow.
  int maxRedirects;

  /// The maximum number of authentication retries.
  int maxAuthRetries;

  /// The maximum duration to wait for a response.
  Duration timeout;

  /// The list of trusted certificates for secure connections.
  List<TrustedCertificate>? trustedCertificates;

  /// A function that finds a proxy for a given URL.
  String Function(Uri url)? findProxy;

  /// The HTTP client used for making requests.
  GetHttpClient? _httpClient;

  /// The list of sockets associated with the connection.
  List<GetSocket>? _sockets;

  /// Determines whether to allow automatically signed certificates.
  bool allowAutoSignedCert;

  /// Determines whether to include credentials in cross-origin requests.
  bool withCredentials;

  @override
  List<GetSocket> get sockets => _sockets ??= <GetSocket>[];

  @override
  GetHttpClient get httpClient => _httpClient ??= GetHttpClient(
        userAgent: userAgent,
        sendUserAgent: sendUserAgent,
        timeout: timeout,
        followRedirects: followRedirects,
        maxRedirects: maxRedirects,
        maxAuthRetries: maxAuthRetries,
        allowAutoSignedCert: allowAutoSignedCert,
        baseUrl: baseUrl,
        trustedCertificates: trustedCertificates,
        withCredentials: withCredentials,
        findProxy: findProxy,
      );

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) {
    _checkIfDisposed();
    return httpClient.get<T>(
      url,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String? url,
    body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    _checkIfDisposed();
    return httpClient.post<T>(
      url,
      body: body,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );
  }

  @override
  Future<Response<T>> put<T>(
    String url,
    body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    _checkIfDisposed();
    return httpClient.put<T>(
      url,
      body: body,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String url,
    body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    _checkIfDisposed();
    return httpClient.patch<T>(
      url,
      body: body,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );
  }

  @override
  Future<Response<T>> request<T>(
    String url,
    String method, {
    body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    _checkIfDisposed();
    return httpClient.request<T>(
      url,
      method,
      body: body,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) {
    _checkIfDisposed();
    return httpClient.delete(
      url,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
    );
  }

  @override
  GetSocket socket(
    String url, {
    Duration ping = const Duration(seconds: 5),
  }) {
    _checkIfDisposed(isHttp: false);

    final GetSocket newSocket = GetSocket(_concatUrl(url)!, ping: ping);
    sockets.add(newSocket);
    return newSocket;
  }

  String? _concatUrl(String? url) {
    if (url == null) {
      return baseUrl;
    }
    return baseUrl == null ? url : baseUrl! + url;
  }

  /// query allow made GraphQL raw queries
  /// final connect = GetConnect();
  /// connect.baseUrl = 'https://countries.trevorblades.com/';
  /// final response = await connect.query(
  /// r"""
  /// {
  ///  country(code: "BR") {
  ///    name
  ///    native
  ///    currency
  ///    languages {
  ///      code
  ///      name
  ///    }
  ///  }
  ///}
  ///""",
  ///);
  ///print(response.body);
  @override
  Future<GraphQLResponse<T>> query<T>(
    String query, {
    String? url,
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
  }) async {
    try {
      final Response res = await post(
        url,
        <String, Object?>{"query": query, "variables": variables},
        headers: headers,
      );

      final listError = res.body["errors"];
      if ((listError is List) && listError.isNotEmpty) {
        return GraphQLResponse<T>(
          graphQLErrors: listError
              .map(
                (e) => GraphQLError(
                  code: (e["extensions"] != null
                          ? e["extensions"]["code"] ?? ""
                          : "")
                      .toString(),
                  message: (e["message"] ?? "").toString(),
                ),
              )
              .toList(),
        );
      }
      return GraphQLResponse<T>.fromResponse(res);
    } on Exception catch (_) {
      return GraphQLResponse<T>(
        graphQLErrors: <GraphQLError>[
          GraphQLError(
            message: _.toString(),
          ),
        ],
      );
    }
  }

  @override
  Future<GraphQLResponse<T>> mutation<T>(
    String mutation, {
    String? url,
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
  }) async {
    try {
      final Response res = await post(
        url,
        <String, Object?>{"query": mutation, "variables": variables},
        headers: headers,
      );

      final listError = res.body["errors"];
      if ((listError is List) && listError.isNotEmpty) {
        return GraphQLResponse<T>(
          graphQLErrors: listError
              .map(
                (e) => GraphQLError(
                  code: e["extensions"]["code"]?.toString(),
                  message: e["message"]?.toString(),
                ),
              )
              .toList(),
        );
      }
      return GraphQLResponse<T>.fromResponse(res);
    } on Exception catch (_) {
      return GraphQLResponse<T>(
        graphQLErrors: <GraphQLError>[
          GraphQLError(
            message: _.toString(),
          ),
        ],
      );
    }
  }

  /// A flag indicating whether the connection is disposed.
  bool _isDisposed = false;

  /// Returns `true` if the connection is disposed, otherwise `false`.
  bool get isDisposed => _isDisposed;

  /// Throws an exception if the connection is disposed.
  ///
  /// [isHttp] specifies whether the check is for an HTTP client.
  void _checkIfDisposed({bool isHttp = true}) {
    if (_isDisposed) {
      throw Exception("Cannot emit events to disposed clients");
    }
  }

  /// Disposes of the connection by closing sockets and the HTTP client.
  void dispose() {
    _sockets?.forEach((GetSocket socket) => socket.close());
    _sockets?.clear();
    sockets = null;
    _httpClient?.close();
    _httpClient = null;
    _isDisposed = true;
  }
}
