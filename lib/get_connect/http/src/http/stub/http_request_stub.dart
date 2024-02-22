import '../../certificates/certificates.dart';
import '../../request/request.dart';
import '../../response/response.dart';
import '../interface/request_base.dart';

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
