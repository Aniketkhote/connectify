// import 'dart:html' as html;

List<int> fileToBytes(dynamic data) {
  if (data is List<int>) {
    return data;
  } else {
    throw const FormatException(
        'File is not "File" or "String" or "List<int>"');
  }
}
