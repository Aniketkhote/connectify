// import 'dart:html' as html;

/// Converts the given data into a list of bytes.
///
/// [data]: The input data to convert, which can be either a list of integers,
/// a file object, or a string.
///
/// Returns a list of bytes representing the input data.
///
/// Throws a [FormatException] if the input data is not a list of integers,
/// a file object, or a string.
List<int> fileToBytes(dynamic data) {
  if (data is List<int>) {
    return data;
  } else {
    throw const FormatException(
        'File is not "File" or "String" or "List<int>"',);
  }
}
