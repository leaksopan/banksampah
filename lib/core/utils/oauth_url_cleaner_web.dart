// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

void cleanOAuthCodeFromBrowserUrl() {
  final uri = Uri.base;
  if (!uri.queryParameters.containsKey('code')) {
    return;
  }

  final path = uri.path.isEmpty ? '/' : uri.path;
  final fragment = uri.fragment.isEmpty ? '' : '#${uri.fragment}';
  html.window.history.replaceState(null, html.document.title, '$path$fragment');
}
