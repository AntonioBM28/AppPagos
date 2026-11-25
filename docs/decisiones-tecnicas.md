# Decisiones técnicas

## 1. Clean Architecture organizada por funcionalidades

Cada funcionalidad (`auth`, `catalogo`, `compras`, `historial`) tiene sus capas `data`, `domain`
y `presentation`; lo compartido vive en `core`.

- **Por qué**: las reglas de negocio (por ejemplo, cuándo reintentar una compra) quedan en
  `domain`, en Dart puro, y se prueban sin interfaz ni red. Cambiar Dio por otro cliente, o la
  forma de guardar la sesión, no toca las pantallas.
- **Dependencias**: `presentation → domain ← data`. `domain` define contratos (repositorios) y
  `data` los implementa. Las pantallas nunca llaman a la API directamente.
- **Errores**: `data` lanza `AppException` (jerarquía sellada) y los repositorios las convierten
  en `Failure` con `Failure.fromException`. Como ambas jerarquías son selladas, el compilador
  obliga a manejar cualquier tipo nuevo de error.
- **Resultado**: los casos de uso devuelven `Result<T>` (`Success` o `ErrorResult`), así la
  pantalla siempre recibe un mensaje listo para mostrar y nunca una traza.

## 2. BLoC / Cubit para el estado

- Separa por completo la interfaz de la lógica: el widget emite intenciones y pinta estados.
- Los estados son clases inmutables (`equatable`), con casos explícitos de carga, éxito y error.
- `bloc_test` permite probar cada transición de estado sin construir widgets.
- Un Cubit puede ignorar una acción mientras otra está en curso; esto, junto con `AppButton`
  (que se bloquea mientras su acción no termina), evita peticiones duplicadas por doble clic.

## 3. Dio con interceptores

Todas las peticiones pasan por `ApiClient`, construido en `dio_factory.dart`:

| Interceptor          | Responsabilidad                                                        |
| -------------------- | ---------------------------------------------------------------------- |
| `LoggingInterceptor` | Solo en dev: método, ruta, estatus y duración. Nunca headers ni cuerpos. |
| `AuthInterceptor`    | Móvil: agrega `Authorization: Bearer`. En web no hace nada.            |
| `CsrfInterceptor`    | Web: copia la cookie `XSRF-TOKEN` al header `X-XSRF-TOKEN`.            |
| `SessionInterceptor` | Un 401 en ruta protegida cierra la sesión local y lleva al login.      |
| `ErrorInterceptor`   | Convierte cada error de red o código HTTP en una `AppException`.       |

- **Tiempos de espera**: conexión 10 s, envío 15 s, respuesta 30 s.
- **Validación del contrato**: toda respuesta exitosa debe traer el sobre
  `{ "codigo": 0, "mensaje": ... }`; si no, se lanza `InvalidResponseException`. Se conserva el
  código HTTP porque distingue casos como 201 (compra aprobada) y 202 (compra pendiente).
- **Mensajes**: para errores 4xx se muestra el `mensaje` de la API, que ya viene redactado para
  el usuario. Para 5xx se usa siempre un mensaje genérico, para no exponer textos de servicios
  externos.

## 4. Almacenamiento seguro en móvil

- El token y los datos de sesión se guardan con `flutter_secure_storage`: Keystore con AES-GCM
  en Android y Keychain (`first_unlock_this_device`) en iOS. El dato no viaja en respaldos.
- `android:allowBackup="false"` evita que los datos de la app se copien a respaldos.
- Nunca se guardan contraseñas. `SharedPreferences` no se usa para nada sensible.
- No hay secretos en el código: la URL de la API llega por `--dart-define-from-file` y los
  archivos reales de configuración están en `.gitignore`.

## 5. Sesión en web vs. móvil

|                         | Móvil                                   | Web                                          |
| ----------------------- | --------------------------------------- | -------------------------------------------- |
| Dónde vive el token     | `flutter_secure_storage`                | Cookie `HttpOnly; Secure; SameSite=Strict`   |
| Cómo se envía           | Header `Authorization: Bearer`          | El navegador envía la cookie solo            |
| Qué guarda la app       | Token + datos de sesión (cifrados)      | Solo datos no sensibles, en memoria          |
| Al reabrir / recargar   | Lee el almacenamiento y revisa expiración | `GET /auth/sesion`                         |

- **Por qué cookie HttpOnly en web**: en el navegador, `localStorage`, `sessionStorage` (y por
  lo tanto `flutter_secure_storage` en web) son legibles por cualquier script de la página. Si
  un ataque XSS lograra ejecutar código, podría robar el JWT. Una cookie `HttpOnly` no es
  accesible desde JavaScript.
- **Por qué hace falta el token CSRF**: como el navegador envía la cookie automáticamente,
  otro sitio podría provocar peticiones en nombre del usuario. Para evitarlo, el servidor
  entrega un token en la cookie legible `XSRF-TOKEN` y exige que cada `POST/PUT/PATCH/DELETE`
  lo repita en el header `X-XSRF-TOKEN`. Un sitio externo no puede leer esa cookie, así que no
  puede construir el header. `SameSite=Strict` agrega una segunda barrera.
- **Por qué móvil usa Bearer**: en una app nativa no hay otros sitios ni scripts ajenos
  ejecutándose en el mismo contexto, y el almacenamiento seguro del sistema protege el token.
- **XSS en Flutter Web**: la interfaz se dibuja con widgets (no con HTML), todo texto del
  servidor se muestra con `Text` y no se usa `HtmlElementView`, así que no se inyecta HTML.

## 6. Inicio de sesión con doble factor y sesión única

**Flujo:** correo y contraseña (`LoginCubit`) → código de 6 dígitos enviado al correo
(`VerificacionCubit`) → sesión abierta. Si la cuenta ya tiene una sesión en otro dispositivo, el
servidor responde 409 y la app pregunta, con la plataforma y la hora, si se debe cerrar esa
sesión; solo al confirmar repite el login con `cerrarSesionAnterior`.

**Por qué el segundo factor se valida en el servidor y no en la app:** si la app conociera el
código o decidiera si es correcto, un atacante con la contraseña podría modificarla o llamar
directamente a la API para saltarse el paso. Por eso el código solo existe en el correo del usuario
y como hash BCrypt en la base de datos; la app únicamente lo envía. El servidor controla que venza,
que sea de un solo uso, el número de intentos y los reenvíos, y la sesión (el JWT) solo se emite
después de validarlo.

**Por qué la sesión única vive en el servidor:** una variable en el dispositivo no puede impedir que
otro dispositivo use la cuenta. Cada JWT lleva el id de una sesión de la tabla `sesiones`, y el
servidor rechaza cualquier token cuya sesión ya se cerró. Cuando el usuario entra desde la web y
cierra la sesión del móvil, la siguiente petición del móvil recibe 401 con el motivo ("iniciaste
sesión en otro dispositivo"), y la app lo muestra en el login.

**Controles en la interfaz:** el botón de envío se bloquea mientras hay una petición en curso (los
Cubits ignoran un segundo envío), la contraseña nunca se guarda (solo vive en memoria mientras el
usuario decide sobre la sesión activa), el código se escribe con teclado numérico y autocompletado
de un solo uso, y hay cuentas regresivas para el vencimiento y el reenvío. Un 410 (código usado) o
un 429 (sin intentos) llevan directo a "Iniciar sesión de nuevo".

## 7. Navegación protegida

- `go_router` con un `redirect` global que depende solo del estado de `SessionManager`
  (`verificando`, `autenticada`, `noAutenticada`); se re-evalúa cada vez que cambia.
- Mientras se verifica la sesión (al abrir la app o al recargar en web), todo pasa por
  `/cargando`: nunca se dibuja una pantalla protegida antes de confirmar la sesión.
- El destino original se recuerda (`/cargando?desde=/historial`). Solo se aceptan rutas
  internas y protegidas, para evitar redirecciones abiertas hacia otros sitios.
- La expiración se controla en dos niveles: un temporizador local con la vigencia del token y
  el servidor, que responde 401 (por ejemplo, si la sesión se cerró desde otro dispositivo).

## 8. Diseño y accesibilidad

- Material 3 desde `material_ui` (en Flutter 3.47+ Material se separó del SDK), temas claro y
  oscuro derivados de un color de marca, y tokens de espaciado, radios y tamaños.
- Responsivo: barra inferior en pantallas compactas (< 600 px) y `NavigationRail` en
  pantallas anchas; el contenido se limita a un ancho máximo y siempre puede desplazarse.
- Accesibilidad: área táctil mínima de 48 px, etiquetas `Semantics`, anuncios de carga y
  error (`liveRegion`) y soporte para escalar el texto.
