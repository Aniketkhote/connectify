import "package:connectify/src/http/src/certificates/certificates.dart";
import "package:connectify/src/http/src/http/interface/request_base.dart";
import "package:connectify/src/http/src/request/request.dart";
import "package:connectify/src/http/src/response/response.dart";

/// Implementation of HTTP client for making HTTP requests.
class HttpRequestImpl extends IClient {
  /// Constructs a new [HttpRequestImpl].
  ///
  /// [allowAutoSignedCert] determines whether to allow auto-signed certificates. Defaults to `true`.
  ///
  /// [trustedCertificates] is a list of trusted certificates. Defaults to `null`.
  ///
  /// [withCredentials] indicates whether to include credentials in cross-origin requests. Defaults to `false`.
  ///
  /// [findProxy] is a function that finds the proxy server to use for the given [url]. Defaults to `null`.
  HttpRequestImpl({
    bool allowAutoSignedCert = true,
    List<TrustedCertificate>? trustedCertificates,
    bool withCredentials = false,
    String Function(Uri url)? findProxy,
  });

  @override
  void close() {}

  @override
  Future<Response<T>> send<T>(Request<T> request) {
    throw UnimplementedError();
  }
}
