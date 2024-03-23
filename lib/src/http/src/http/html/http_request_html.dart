import "dart:async";
// ignore: avoid_web_libraries_in_flutter
import "dart:html";

import "package:connectify/src/http/src/certificates/certificates.dart";
import "package:connectify/src/http/src/exceptions/exceptions.dart";
import "package:connectify/src/http/src/http/interface/request_base.dart";
import "package:connectify/src/http/src/http/utils/body_decoder.dart";
import "package:connectify/src/http/src/request/request.dart";
import "package:connectify/src/http/src/response/response.dart";

/// A `dart:html` implementation of `IClient`.
class HttpRequestImpl implements IClient {
  HttpRequestImpl({
    bool allowAutoSignedCert = true,
    List<TrustedCertificate>? trustedCertificates,
    this.withCredentials = false,
    String Function(Uri url)? findProxy,
  });

  /// The currently active XHRs.
  final _xhrs = <HttpRequest>{};

  ///This option requires that you submit credentials for requests
  ///on different sites. The default is false
  final bool withCredentials;

  @override
  Duration? timeout;

  /// Sends an HTTP request and asynchronously returns the response.
  @override
  Future<Response<T>> send<T>(Request<T> request) async {
    var bytes = await request.bodyBytes.toBytes();
    HttpRequest xhr;

    xhr = HttpRequest()
      ..timeout = timeout?.inMilliseconds
      ..open(request.method, "${request.url}", async: true); // check this

    _xhrs.add(xhr);

    xhr
      ..responseType = "blob"
      ..withCredentials = withCredentials;
    request.headers.forEach(xhr.setRequestHeader);

    var completer = Completer<Response<T>>();
    xhr.onLoad.first.then((_) {
      var blob = xhr.response as Blob? ?? Blob([]);
      var reader = FileReader();

      reader.onLoad.first.then((_) async {
        var bodyBytes = (reader.result as List<int>).toStream();

        if (request.responseInterceptor != null) {
          throw "response interception not implemented for web yet!";
        }

        /*
        TODO to be implemented like in http_request_io.dart
        final interceptionResponse = await request.responseInterceptor?.call(request, T, reponse);

        if (interceptionResponse != null) {
          completer.complete(interceptionResponse);
          return;
        }

        */

        final stringBody =
            await bodyBytesToString(bodyBytes, xhr.responseHeaders);

        String? contentType;

        if (xhr.responseHeaders.containsKey("content-type")) {
          contentType = xhr.responseHeaders["content-type"];
        } else {
          contentType = "application/json";
        }
        // xhr.responseHeaders.containsKey(key)
        final body = bodyDecoded<T>(
          request,
          stringBody,
          contentType,
        );

        final response = Response<T>(
          bodyBytes: bodyBytes,
          statusCode: xhr.status,
          request: request,
          headers: xhr.responseHeaders,
          statusText: xhr.statusText,
          body: body,
          bodyString: stringBody,
        );
        completer.complete(response);
      });

      reader.onError.first.then((error) {
        completer.completeError(
          GetHttpException(error.toString(), request.url),
          StackTrace.current,
        );
      });

      reader.readAsArrayBuffer(blob);
    });

    xhr.onError.first.then((_) {
      completer.completeError(
        GetHttpException("XMLHttpRequest error.", request.url),
        StackTrace.current,
      );
    });

    xhr.send(bytes);

    try {
      return await completer.future;
    } finally {
      _xhrs.remove(xhr);
    }
  }

  /// Closes the client and abort all active requests.
  @override
  void close() {
    for (var xhr in _xhrs) {
      xhr.abort();
    }
  }
}
