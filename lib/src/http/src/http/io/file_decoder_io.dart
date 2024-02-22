import 'dart:io';

/// Converts the provided [data] into a list of bytes.
///
/// If [data] is a [File], reads the file synchronously and returns its bytes.
/// If [data] is a [String], treats it as a file path, checks if the file exists,
/// and if so, reads the file synchronously and returns its bytes.
/// If [data] is already a [List<int>], returns it as is.
///
/// Throws an error if [data] is not a [File], [String], or [List<int>].
///
/// Throws an error if a file specified by [data] does not exist.
List<int> fileToBytes(dynamic data) {
  if (data is File) {
    return data.readAsBytesSync();
  } else if (data is String) {
    if (File(data).existsSync()) {
      return File(data).readAsBytesSync();
    } else {
      throw 'File $data does not exist';
    }
  } else if (data is List<int>) {
    return data;
  } else {
    throw const FormatException(
        'File is not "File" or "String" or "List<int>"');
  }
}
