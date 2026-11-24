import 'package:web/web.dart' as web;

/// Implementación web para leer la cookie XSRF-TOKEN expuesta por el servidor.
String? readCsrfTokenCookie() {
  try {
    final cookieString = web.document.cookie;
    if (cookieString.isEmpty) return null;

    final cookies = cookieString.split(';');
    for (final cookie in cookies) {
      final parts = cookie.trim().split('=');
      if (parts.length >= 2 && parts[0].trim() == 'XSRF-TOKEN') {
        return Uri.decodeComponent(parts.sublist(1).join('='));
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}
