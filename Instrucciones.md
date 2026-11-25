Eres un desarrollador senior de Flutter. Vamos a construir, por partes, "pagosapp": un cliente de comercio digital que consume una API REST existente (Spring Boot) integrada con GestoPago. La misma base de código se compila como app móvil (android, ios) y como aplicación web (Flutter Web), con las mismas funcionalidades y el mismo diseño.

En ESTA parte solo construyes la base del proyecto. NO implementes todavía login, doble factor, catálogo, compras ni historial: vendrán en partes siguientes. No inventes datos: nada de productos, usuarios ni respuestas simuladas dentro de la app.

## 0. Proyecto existente

- El proyecto YA EXISTE en C:\Users\joseb\Desktop\pagosapp (creado con flutter create; paquete: pagosapp; Flutter 3.50.1, Dart ^3.14). NO lo vuelvas a crear: trabaja sobre él.
- Plataformas objetivo: android, ios y web. Deja intactas las carpetas linux, macos y windows, pero no escribas código específico para ellas.
- Reemplaza el contador de ejemplo de lib/main.dart y test/widget_test.dart.
- Material 3; todos los textos de la interfaz en español.
- Inicializa un repositorio Git (git init) con un .gitignore adecuado para Flutter y haz un primer commit con la base.

## 1. Arquitectura (Clean Architecture, organizada por funcionalidades)

lib/
core/ configuración, red, errores, seguridad/sesión, navegación, tema, widgets compartidos, utilidades
features/
<feature>/ (auth, catalogo, compras, historial… se agregan en otras partes)
data/ modelos (DTO JSON), fuentes de datos remotas, implementaciones de repositorios
domain/ entidades, contratos de repositorios, casos de uso
presentation/ pantallas, widgets, cubits/blocs y estados
main.dart, app.dart, injection.dart
Reglas: los widgets NO contienen lógica de negocio ni llamadas HTTP; domain no depende de Flutter ni de Dio; data implementa los contratos de domain.

## 2. Paquetes

flutter_bloc (Cubit/BLoC para el estado), equatable, dio, go_router, flutter_secure_storage, get_it (inyección de dependencias), json_annotation + json_serializable + build_runner, uuid, intl, logger, web (para leer cookies en Flutter Web).
Pruebas: bloc_test, mocktail, http_mock_adapter.
Usa flutter_lints y agrega reglas más estrictas en analysis_options.yaml (prefer_const_constructors, always_declare_return_types, avoid_print, require_trailing_commas, unawaited_futures, etc.).

## 3. Configuración por ambientes (sin secretos en el código)

- Clase AppConfig que lee con String.fromEnvironment: API_BASE_URL y APP_ENV (dev | prod). Sin valores sensibles por defecto.
- Archivos de ejemplo config/dev.example.json y config/prod.example.json para usar con --dart-define-from-file. Agrega los archivos reales (config/dev.json, config/prod.json) a .gitignore.
- En prod, la URL base debe ser https o una cadena vacía (mismo origen, solo en web). Valida esto al arrancar y falla con un mensaje claro si no se cumple.
- URL de producción actual de la API: https://pwa-n2mh.onrender.com
- En web en producción, la app se publica en el mismo dominio que la API, así que API_BASE_URL puede ser "" (mismo origen). En desarrollo (flutter run -d chrome), API_BASE_URL apunta al backend local, que permitirá ese origen por CORS.

## 4. Contrato de la API (respétalo exactamente)

- Todas las respuestas, de éxito y de error, son JSON con este sobre: { "codigo": 0 | 1, "mensaje": "texto en español", ...datos }. codigo 0 = éxito; codigo 1 = error. El campo "mensaje" de los errores ya viene redactado para el usuario: muéstralo tal cual.
- La API NO usa parámetros en la URL ni query strings: las consultas son POST con un cuerpo JSON (por ejemplo, POST /cuentas/saldo con {"numeroCuenta":"1000000001"}).
- Códigos HTTP que usa: 200, 201, 202 (operación pendiente), 400 (validación), 401 (sin sesión, sesión inválida o expirada), 403 (sin permiso), 404, 409 (conflicto), 413, 422 (regla de negocio, por ejemplo saldo insuficiente o compra rechazada), 429 (demasiadas peticiones; trae el header Retry-After en segundos), 500, 502, 503 y 504 (falla de GestoPago).
- La sesión dura 60 minutos (el login devuelve "expiraEnSegundos").
- Cómo viaja la sesión depende de la plataforma (sección 7):
  · Móvil: header Authorization: Bearer <token>.
  · Web: cookie HttpOnly que pone el servidor; la app nunca ve el token.

## 5. Capa de red (core/network)

- ApiEndpoints: clase con todas las rutas como constantes. Por ahora deja la estructura más GET /auth/sesion; cada parte agregará las suyas.
- ApiClient sobre Dio con: baseUrl de AppConfig, Content-Type y Accept application/json, connectTimeout 10 s, receiveTimeout 30 s, sendTimeout 15 s.
- En web usa BrowserHttpClientAdapter con withCredentials = true para que el navegador envíe la cookie de sesión.
- Interceptores:
  1. AuthInterceptor (solo móvil): agrega Authorization: Bearer <token> desde el almacenamiento seguro, excepto en rutas públicas (lista configurable). En web no agrega nada. Inyecta la plataforma para poder probarlo.
  2. CsrfInterceptor (solo web): el servidor entrega un token CSRF en la cookie legible XSRF-TOKEN; en cada POST, PUT, PATCH o DELETE copia ese valor en el header X-XSRF-TOKEN. Lee la cookie con package:web (document.cookie), aislado en un archivo con import condicional para que la app móvil siga compilando.
  3. ErrorInterceptor: convierte DioException y el sobre de error en excepciones propias (sección 6).
  4. SessionInterceptor: ante un 401 en una ruta protegida, borra la sesión local y notifica al SessionManager para que la navegación lleve al login con el mensaje "Tu sesión expiró o fue cerrada. Inicia sesión de nuevo".
  5. LoggingInterceptor (solo en dev): registra método, ruta, estatus y duración. NUNCA registra los headers Authorization, X-XSRF-TOKEN ni Idempotency-Key, ni contraseñas, tokens, códigos OTP o cuerpos completos.
- Deserialización con json_serializable. Antes de entregar datos, valida que la respuesta tenga "codigo"; si el JSON no corresponde al contrato, lanza InvalidResponseException.

## 6. Errores (core/error)

- Excepciones de la capa data: NetworkException (sin conexión), TimeoutException, UnauthorizedException (401), ForbiddenException (403), NotFoundException (404), ValidationException (400, con el mensaje de la API), ConflictException (409), BusinessRuleException (422), TooManyRequestsException (429, con retryAfter), ServerException (5xx), InvalidResponseException.
- Domain trabaja con Failures (clases selladas) que tienen un mensaje para el usuario; los repositorios convierten excepciones en Failures. Usa un tipo Result<T> (Success | Failure) propio, sin paquetes externos.
- Mensajes genéricos solo cuando la API no mande "mensaje": sin conexión → "Revisa tu conexión a internet"; timeout → "El servidor tardó demasiado en responder"; 5xx → "El servicio no está disponible, intenta más tarde". Nunca muestres trazas ni detalles técnicos.

## 7. Sesión y seguridad (core/security)

- Interfaz SessionStore con dos implementaciones, registradas en get_it según la plataforma (kIsWeb):
  a) MobileSessionStore (android/ios): guarda el token, su expiración y los datos de sesión (usuario, rol, clienteId) en flutter_secure_storage (encryptedSharedPreferences en Android).
  b) WebSessionStore (web): NUNCA guarda el token (viaja en una cookie HttpOnly que JavaScript no puede leer). Solo guarda en memoria los datos NO sensibles: usuario, rol, clienteId y expiración. Prohibido usar localStorage, sessionStorage o flutter_secure_storage para el token en web.
- Identificador de dispositivo: un UUID generado una sola vez y persistido (en móvil, en flutter_secure_storage). Se usará en la parte de sesión única.
- Nunca guardes contraseñas. No uses SharedPreferences para datos sensibles.
- SessionManager: expone el estado de la sesión como Stream y avisa cuándo expira, comparando la expiración guardada con la hora actual.
- Recuperar la sesión al abrir la app:
  · Móvil: lee el SessionStore y verifica que no haya expirado.
  · Web (incluido al refrescar el navegador): llama a GET /auth/sesion (la cookie viaja sola). Respuesta 200: {"codigo":0,"mensaje":"...","usuario":"...","rol":"CLIENTE|EJECUTIVO","clienteId":1,"expiraEnSegundos":3400}. Respuesta 401: no hay sesión → /login.

## 8. Navegación (core/router)

- go_router con redirect global: sin sesión válida, cualquier ruta protegida redirige a /login; con sesión, /login redirige a /inicio. El router se refresca cuando cambia el Stream del SessionManager.
- Mientras se recupera la sesión al arrancar (sobre todo en web), muestra una pantalla de carga; no muestres ni un instante una pantalla protegida antes de confirmar la sesión.
- Pantallas de marcador de posición (sin lógica) para: /login, /verificar-codigo, /inicio, /catalogo, /historial y /perfil. Usa un ShellRoute con navegación inferior en pantallas compactas y NavigationRail en pantallas anchas.
- El build web debe funcionar servido desde la raíz del dominio (base href "/").

## 9. Diseño y componentes reutilizables (core/theme, core/widgets)

- Tema claro y oscuro con Material 3, una paleta de color de marca, tipografía y espaciados definidos como constantes (nada de valores mágicos dispersos).
- Breakpoints responsivos: compacto < 600, mediano < 1024, expandido ≥ 1024. Crea un widget ResponsiveLayout.
- Widgets: AppButton (estados normal, cargando y deshabilitado; mientras carga ignora toques repetidos), AppTextField (con validación y mensaje de error), LoadingView, ErrorView (mensaje y botón Reintentar), EmptyView, AppSnackbar (éxito, error, información) y ConfirmDialog.
- Accesibilidad: etiquetas Semantics, área táctil mínima de 48x48, contraste suficiente y soporte para escalar texto.
- Todas las pantallas deben poder desplazarse (SingleChildScrollView o listas) para no desbordarse en resoluciones pequeñas.
- Seguridad en web: no uses HtmlElementView ni construyas HTML a partir de datos de la API; todo texto del servidor se muestra con widgets Text.

## 10. Pruebas de esta parte (ninguna llama a la API real; usa http_mock_adapter o mocktail)

- AppConfig: rechaza http en prod.
- Conversión de DioException y del sobre de error a excepciones, para cada código HTTP de la sección 4.
- AuthInterceptor: agrega el token en rutas protegidas, no en públicas, y nunca en web.
- CsrfInterceptor: agrega X-XSRF-TOKEN solo en métodos que modifican datos.
- SessionInterceptor: un 401 limpia la sesión y notifica.
- LoggingInterceptor: no registra headers ni datos sensibles.
- WebSessionStore: no persiste el token.
- Redirect del router: con sesión, sin sesión y mientras se recupera la sesión.

## 11. Entregables

- `flutter analyze` sin warnings y `flutter test` en verde.
- README.md con: requisitos (Flutter 3.50.1), cómo ejecutar en móvil y en Chrome con --dart-define-from-file=config/dev.json, cómo compilar para web (flutter build web), estructura de carpetas y explicación breve de cada capa.
- docs/decisiones-tecnicas.md explicando: por qué Clean Architecture, por qué BLoC/Cubit, por qué Dio con interceptores, por qué flutter_secure_storage en móvil y, en una sección "Sesión en web vs. móvil", por qué la web usa una cookie HttpOnly en lugar de guardar el JWT en el navegador (protección contra XSS) y por qué hace falta el token CSRF cuando la sesión viaja en una cookie.
