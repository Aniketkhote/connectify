import 'dart:convert';

import 'package:refreshed/refreshed.dart';

import '../../request/request.dart';

/// Decodes the response body based on the provided request and MIME type.
///
/// [request]: The request containing information about the expected type of the response body.
/// [stringBody]: The raw string representation of the response body.
/// [mimeType]: The MIME type of the response body.
///
/// Returns the decoded body of type [T] or `null` if the body is empty.
///
/// The decoding process is determined by the MIME type. If the MIME type contains 'application/json',
/// the string body is decoded as JSON. If decoding fails, the raw string body is used.
/// If no decoder is provided in the request or decoding fails, the raw string body is returned.
/// If an exception occurs during decoding, the raw string body is returned.
T? bodyDecoded<T>(Request<T> request, String stringBody, String? mimeType) {
  T? body;
  dynamic bodyToDecode;

  if (mimeType != null && mimeType.contains('application/json')) {
    try {
      bodyToDecode = jsonDecode(stringBody);
    } on FormatException catch (_) {
      Get.log('Cannot decode server response to json');
      bodyToDecode = stringBody;
    }
  } else {
    bodyToDecode = stringBody;
  }

  try {
    if (stringBody == '') {
      body = null;
    } else if (request.decoder == null) {
      body = bodyToDecode as T?;
    } else {
      body = request.decoder!(bodyToDecode);
    }
  } on Exception catch (_) {
    body = stringBody as T;
  }

  return body;
}
