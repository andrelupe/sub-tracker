// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
// ignore: unnecessary_import
import 'dart:html' as html;

/// Downloads a file in the browser by creating a temporary anchor element.
void downloadFile(String content, String filename) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  html.Url.revokeObjectUrl(url);
}
