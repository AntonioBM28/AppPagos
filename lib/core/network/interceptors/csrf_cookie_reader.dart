/// Lee la cookie XSRF-TOKEN. En movil siempre devuelve null.
library;

export 'csrf_cookie_reader_stub.dart'
    if (dart.library.js_interop) 'csrf_cookie_reader_web.dart';
