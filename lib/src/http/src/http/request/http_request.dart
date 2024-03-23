import "package:connectify/src/http/src/certificates/certificates.dart";
import "package:connectify/src/http/src/http/stub/http_request_stub.dart"
    if (dart.library.html) "../html/http_request_html.dart"
    if (dart.library.io) "../io/http_request_io.dart";

/// Creates an instance of [HttpRequestImpl] with the provided configurations.
///
/// [allowAutoSignedCert] determines whether to allow auto-signed certificates.
/// Defaults to `true`.
///
/// [trustedCertificates] is a list of trusted certificates. Defaults to `null`.
///
/// [withCredentials] indicates whether to include credentials in cross-origin requests.
/// Defaults to `false`.
///
/// [findProxy] is a function that finds the proxy server to use for the given [url].
/// Defaults to `null`.
///
/// Returns an instance of [HttpRequestImpl] initialized with the provided configurations.
HttpRequestImpl createHttp({
  bool allowAutoSignedCert = true,
  List<TrustedCertificate>? trustedCertificates,
  bool withCredentials = false,
  String Function(Uri url)? findProxy,
}) =>
    HttpRequestImpl(
      allowAutoSignedCert: allowAutoSignedCert,
      trustedCertificates: trustedCertificates,
      withCredentials: withCredentials,
      findProxy: findProxy,
    );
