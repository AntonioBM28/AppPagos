# PagosApp

Cliente de comercio digital que consume la API REST del proyecto (Spring Boot) integrada con
GestoPago. Un solo código fuente se compila como **app móvil** (Android e iOS) y como
**aplicación web** (Flutter Web), con las mismas funciones y el mismo diseño.

> Estado: **Parte 1 – base del proyecto**. Están listas la arquitectura, la capa de red, el
> manejo de errores, la sesión segura, la navegación protegida y el sistema de diseño. Login,
> doble factor, catálogo, compras e historial se agregan en las siguientes partes.

## Requisitos

- Flutter **3.50.1** (canal stable) y Dart 3.14.
- Android: emulador o dispositivo con Android 6.0 (API 23) o superior.
- Web: Chrome o Edge.
- En Windows, activa el **Modo de desarrollador** (`start ms-settings:developers`): Flutter lo
  necesita para compilar plugins.

## Configuración por ambiente

La URL de la API y el ambiente se definen en tiempo de compilación. Los archivos reales no se
suben a Git; copia los de ejemplo:

```bash
cp config/dev.example.json config/dev.json
cp config/prod.example.json config/prod.json
```

| Variable       | Descripción                                                                 |
| -------------- | --------------------------------------------------------------------------- |
| `API_BASE_URL` | URL de la API. En prod debe ser `https`. En web puede ir vacía (mismo dominio). |
| `APP_ENV`      | `dev` (registra peticiones en consola, sin datos sensibles) o `prod`.        |

Si falta una variable o es inválida, la app muestra el error en pantalla en lugar de arrancar.

Para el **emulador de Android** con el backend local, usa `http://10.0.2.2:8080`
(`localhost` dentro del emulador es el propio emulador). El tráfico `http` solo está permitido
en builds de debug.

## Ejecutar

```bash
flutter pub get
flutter run --dart-define-from-file=config/dev.json            # móvil
flutter run -d chrome --dart-define-from-file=config/dev.json  # web
```

## Compilar

```bash
flutter build apk --release --dart-define-from-file=config/prod.json
flutter build web --release --dart-define-from-file=config/prod.json
```

El build web (`build/web`) se publica en el mismo dominio que la API. Usa URLs limpias
(`/historial`), así que el servidor debe responder `index.html` en cualquier ruta de la app.

## Calidad

```bash
flutter analyze   # análisis estático (reglas en analysis_options.yaml)
flutter test      # pruebas unitarias y de widgets; ninguna llama a la API real
```

## Estructura

```
lib/
  core/
    config/      AppConfig: ambiente y URL de la API
    error/       excepciones de la capa data y Failures de domain
    network/     ApiClient, endpoints, interceptores y fábrica de Dio
    result/      Result<T> (Success | ErrorResult)
    router/      rutas, regla de redirección y shell de navegación
    security/    sesión (móvil / web), SessionManager e id de dispositivo
    theme/       tema claro/oscuro y tokens de diseño
    utils/       breakpoints responsivos
    widgets/     componentes reutilizables (botón, campos, estados, avisos)
  features/
    <feature>/
      data/          DTOs, fuentes remotas, repositorios
      domain/        entidades, contratos, casos de uso
      presentation/  páginas, widgets y cubits
  app.dart, injection.dart, main.dart
test/            espejo de lib/ con helpers en test/helpers
docs/            decisiones técnicas
```

### Capas

- **presentation**: pantallas y widgets. Solo muestran estado y envían eventos a un Cubit; no
  hacen llamadas HTTP ni contienen reglas de negocio.
- **domain**: entidades y casos de uso en Dart puro (sin Flutter ni Dio). Devuelve `Result<T>`.
- **data**: habla con la API por medio de `ApiClient` y convierte excepciones en `Failure`.
- **core**: lo que comparten todas las funcionalidades.

Las decisiones de arquitectura y seguridad están en
[docs/decisiones-tecnicas.md](docs/decisiones-tecnicas.md).
