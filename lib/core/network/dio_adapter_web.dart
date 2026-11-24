import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Implementación web: configura [BrowserHttpClientAdapter] con withCredentials = true.
HttpClientAdapter? createPlatformHttpClientAdapter() {
  final adapter = BrowserHttpClientAdapter();
  adapter.withCredentials = true;
  return adapter;
}
