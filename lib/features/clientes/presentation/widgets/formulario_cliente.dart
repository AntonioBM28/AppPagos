import 'dart:async';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formateadores.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/entities/datos_cliente.dart';
import '../../domain/validaciones_cliente.dart';

/// Formulario de cliente para el alta (autoregistro o ejecutivo) y la edicion.
///
/// Cada campo se valida al momento con las reglas de [ValidacionesCliente] y los
/// formateadores impiden escribir caracteres invalidos (por ejemplo, numeros en un
/// nombre o letras en un telefono). En la edicion la CURP y el RFC se muestran pero no
/// se pueden cambiar.
class FormularioCliente extends StatefulWidget {
  const FormularioCliente({
    required this.consultarCodigoPostal,
    required this.onGuardar,
    required this.textoBoton,
    this.inicial,
    this.esEdicion = false,
    this.guardando = false,
    super.key,
  });

  final Future<Result<InfoCodigoPostal>> Function(String codigoPostal) consultarCodigoPostal;

  /// En el alta [password] trae la contrasena; en la edicion es null.
  final Future<void> Function(DatosCliente datos, String? password) onGuardar;
  final String textoBoton;
  final DatosCliente? inicial;
  final bool esEdicion;
  final bool guardando;

  @override
  State<FormularioCliente> createState() => _FormularioClienteState();
}

class _FormularioClienteState extends State<FormularioCliente> {
  final _formulario = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;

  DateTime? _fechaNacimiento;
  Sexo? _sexo;
  EstadoCivil? _estadoCivil;
  String? _colonia;
  Ocupacion? _ocupacion;
  RangoIngreso? _rangoIngreso;

  /// Limite de la calle (el mismo que valida el servidor).
  static const maximoCalle = 60;

  InfoCodigoPostal? _infoCp;
  bool _consultandoCp = false;
  String? _errorCp;

  static const _campos = [
    'nombre', 'segundoNombre', 'apellidoPaterno', 'apellidoMaterno', 'curp', 'rfc', 'nacionalidad',
    'correo', 'telefonoMovil', 'telefonoAlternativo', 'calle', 'numeroExterior', 'numeroInterior',
    'codigoPostal', 'empresa', 'password', 'confirmarPassword', 'fecha',
  ];

  @override
  void initState() {
    super.initState();
    _c = {for (final campo in _campos) campo: TextEditingController()};
    final d = widget.inicial;
    _c['nacionalidad']!.text = 'MEX';
    if (d != null) {
      _c['nombre']!.text = d.nombre;
      _c['segundoNombre']!.text = d.segundoNombre ?? '';
      _c['apellidoPaterno']!.text = d.apellidoPaterno;
      _c['apellidoMaterno']!.text = d.apellidoMaterno;
      _c['curp']!.text = d.curp;
      _c['rfc']!.text = d.rfc;
      _c['nacionalidad']!.text = d.nacionalidad;
      _c['correo']!.text = d.correo;
      _c['telefonoMovil']!.text = d.telefonoMovil;
      _c['telefonoAlternativo']!.text = d.telefonoAlternativo ?? '';
      _c['calle']!.text = d.calle;
      _c['numeroExterior']!.text = d.numeroExterior;
      _c['numeroInterior']!.text = d.numeroInterior ?? '';
      _c['codigoPostal']!.text = d.codigoPostal;
      _ocupacion = d.ocupacion;
      _c['empresa']!.text = d.empresa ?? '';
      _rangoIngreso = d.rangoIngresoMensual;
      _fechaNacimiento = d.fechaNacimiento;
      _c['fecha']!.text = _formatoFecha(d.fechaNacimiento);
      _sexo = d.sexo;
      _estadoCivil = d.estadoCivil;
      _colonia = d.colonia;
      unawaited(_consultarCp(d.codigoPostal));
    }
  }

  @override
  void dispose() {
    for (final controller in _c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  static String _formatoFecha(DateTime fecha) => DateFormat('dd/MM/yyyy').format(fecha);

  String _t(String campo) => ValidacionesCliente.limpiar(_c[campo]!.text);

  // ------------------------------------------------------------------ Codigo postal

  Future<void> _consultarCp(String codigo) async {
    if (codigo.length != 5) {
      setState(() {
        _infoCp = null;
        _errorCp = null;
      });
      return;
    }
    setState(() {
      _consultandoCp = true;
      _errorCp = null;
    });
    final resultado = await widget.consultarCodigoPostal(codigo);
    if (!mounted || _c['codigoPostal']!.text != codigo) return;
    setState(() {
      _consultandoCp = false;
      resultado.fold(
        (info) {
          _infoCp = info;
          // Si la colonia elegida no existe en el nuevo codigo postal, hay que elegir otra
          if (_colonia != null && !info.colonias.contains(_colonia)) _colonia = null;
          if (info.colonias.length == 1) _colonia = info.colonias.first;
        },
        (falla) {
          _infoCp = null;
          _colonia = null;
          _errorCp = falla.message;
        },
      );
    });
  }

  // ------------------------------------------------------------------ Guardar

  Future<void> _guardar() async {
    final valido = _formulario.currentState?.validate() ?? false;
    if (!valido) {
      _avisarErrores();
      return;
    }
    TextInput.finishAutofillContext();
    final datos = DatosCliente(
      nombre: _t('nombre'),
      segundoNombre: _t('segundoNombre').isEmpty ? null : _t('segundoNombre'),
      apellidoPaterno: _t('apellidoPaterno'),
      apellidoMaterno: _t('apellidoMaterno'),
      fechaNacimiento: _fechaNacimiento!,
      curp: _t('curp').toUpperCase(),
      rfc: _t('rfc').toUpperCase(),
      sexo: _sexo!,
      nacionalidad: _t('nacionalidad').toUpperCase(),
      estadoCivil: _estadoCivil!,
      correo: _t('correo').toLowerCase(),
      telefonoMovil: _t('telefonoMovil'),
      telefonoAlternativo: _t('telefonoAlternativo').isEmpty ? null : _t('telefonoAlternativo'),
      calle: _t('calle'),
      numeroExterior: _t('numeroExterior'),
      numeroInterior: _t('numeroInterior').isEmpty ? null : _t('numeroInterior'),
      colonia: _colonia!,
      codigoPostal: _t('codigoPostal'),
      ocupacion: _ocupacion,
      empresa: _t('empresa').isEmpty ? null : _t('empresa'),
      rangoIngresoMensual: _rangoIngreso,
    );
    await widget.onGuardar(datos, widget.esEdicion ? null : _c['password']!.text);
  }

  void _avisarErrores() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Revisa los campos marcados en rojo')));
  }

  // ------------------------------------------------------------------ Interfaz

  @override
  Widget build(BuildContext context) {
    final bloqueado = widget.guardando;
    return Form(
      key: _formulario,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Seccion(
              titulo: 'Datos personales',
              icono: Icons.badge_outlined,
              children: [
                _texto('nombre', 'Nombre', Icons.person_outline,
                    formatos: Formateadores.soloLetras,
                    validator: (v) => ValidacionesCliente.nombre(v, campo: 'El nombre'),
                    autofill: const [AutofillHints.givenName]),
                _texto('segundoNombre', 'Segundo nombre (opcional)', Icons.person_outline,
                    formatos: Formateadores.soloLetras,
                    validator: (v) => ValidacionesCliente.nombreOpcional(v, campo: 'El segundo nombre'),
                    autofill: const [AutofillHints.middleName]),
                _texto('apellidoPaterno', 'Apellido paterno', Icons.person_outline,
                    formatos: Formateadores.soloLetras,
                    validator: (v) => ValidacionesCliente.nombre(v, campo: 'El apellido paterno'),
                    autofill: const [AutofillHints.familyName]),
                _texto('apellidoMaterno', 'Apellido materno', Icons.person_outline,
                    formatos: Formateadores.soloLetras,
                    validator: (v) => ValidacionesCliente.nombre(v, campo: 'El apellido materno')),
                _campoFecha(bloqueado),
                _desplegable<Sexo>(
                  etiqueta: 'Sexo',
                  icono: Icons.wc_outlined,
                  valor: _sexo,
                  opciones: {for (final s in Sexo.values) s: s.etiqueta},
                  alCambiar: bloqueado ? null : (s) => setState(() => _sexo = s),
                ),
                _texto('curp', 'CURP', Icons.fingerprint,
                    formatos: Formateadores.claveMayusculas(18),
                    habilitado: !widget.esEdicion,
                    ayuda: widget.esEdicion ? 'La CURP no se puede modificar' : '18 caracteres',
                    validator: widget.esEdicion
                        ? null
                        : (v) => ValidacionesCliente.curp(v, fechaNacimiento: _fechaNacimiento, sexo: _sexo)),
                _texto('rfc', 'RFC', Icons.receipt_outlined,
                    formatos: Formateadores.claveMayusculas(13),
                    habilitado: !widget.esEdicion,
                    ayuda: widget.esEdicion ? 'El RFC no se puede modificar' : '13 caracteres, con homoclave',
                    validator: widget.esEdicion ? null : (v) => ValidacionesCliente.rfc(v, curp: _c['curp']!.text)),
                _texto('nacionalidad', 'Nacionalidad', Icons.flag_outlined,
                    formatos: Formateadores.claveMayusculas(3, permitirNumeros: false),
                    ayuda: 'Código de 3 letras, por ejemplo MEX',
                    validator: ValidacionesCliente.nacionalidad),
                _desplegable<EstadoCivil>(
                  etiqueta: 'Estado civil',
                  icono: Icons.favorite_border,
                  valor: _estadoCivil,
                  opciones: {for (final e in EstadoCivil.values) e: e.etiqueta},
                  alCambiar: bloqueado ? null : (e) => setState(() => _estadoCivil = e),
                ),
              ],
            ),
            _Seccion(
              titulo: 'Contacto',
              icono: Icons.contact_phone_outlined,
              children: [
                _texto('correo', 'Correo electrónico', Icons.alternate_email,
                    teclado: TextInputType.emailAddress,
                    formatos: Formateadores.correo,
                    ayuda: widget.esEdicion ? 'Si lo cambias, también cambia tu usuario para iniciar sesión' : null,
                    validator: ValidacionesCliente.correo,
                    autofill: const [AutofillHints.email]),
                _texto('telefonoMovil', 'Teléfono móvil', Icons.smartphone,
                    teclado: TextInputType.phone,
                    formatos: Formateadores.soloDigitos(10),
                    ayuda: '10 dígitos',
                    validator: (v) => ValidacionesCliente.telefono(v, campo: 'El teléfono móvil'),
                    autofill: const [AutofillHints.telephoneNumberNational]),
                _texto('telefonoAlternativo', 'Teléfono alternativo (opcional)', Icons.phone_outlined,
                    teclado: TextInputType.phone,
                    formatos: Formateadores.soloDigitos(10),
                    validator: (v) => ValidacionesCliente.telefonoOpcional(v, campo: 'El teléfono alternativo')),
              ],
            ),
            _Seccion(
              titulo: 'Domicilio',
              icono: Icons.home_outlined,
              children: [
                _texto('codigoPostal', 'Código postal', Icons.markunread_mailbox_outlined,
                    teclado: TextInputType.number,
                    formatos: Formateadores.soloDigitos(5),
                    ayuda: _consultandoCp
                        ? 'Buscando colonias...'
                        : _infoCp == null
                            ? '5 dígitos'
                            : '${_infoCp!.municipio}, ${_infoCp!.estado}',
                    validator: (v) => ValidacionesCliente.codigoPostal(v) ?? _errorCp,
                    alCambiar: (v) => unawaited(_consultarCp(v)),
                    autofill: const [AutofillHints.postalCode]),
                _campoColonia(bloqueado),
                _texto('calle', 'Calle', Icons.signpost_outlined,
                    formatos: Formateadores.textoSeguro(maximoCalle),
                    longitudMaxima: maximoCalle,
                    validator: (v) => ValidacionesCliente.texto(v, campo: 'La calle', maximo: maximoCalle),
                    autofill: const [AutofillHints.streetAddressLine1]),
                _texto('numeroExterior', 'Número exterior', Icons.tag,
                    formatos: Formateadores.textoSeguro(10),
                    validator: (v) => ValidacionesCliente.texto(v, campo: 'El número exterior', maximo: 10)),
                _texto('numeroInterior', 'Número interior (opcional)', Icons.tag,
                    formatos: Formateadores.textoSeguro(10),
                    validator: (v) =>
                        ValidacionesCliente.texto(v, campo: 'El número interior', maximo: 10, obligatorio: false)),
              ],
            ),
            _Seccion(
              titulo: 'Información laboral (opcional)',
              icono: Icons.work_outline,
              children: [
                _opcional<Ocupacion>(
                  etiqueta: 'Ocupación',
                  icono: Icons.work_outline,
                  valor: _ocupacion,
                  opciones: {for (final o in Ocupacion.values) o: o.etiqueta},
                  alCambiar: (o) => setState(() => _ocupacion = o),
                ),
                _texto('empresa', 'Empresa (opcional)', Icons.business_outlined,
                    formatos: Formateadores.textoSeguro(100),
                    validator: (v) =>
                        ValidacionesCliente.texto(v, campo: 'La empresa', maximo: 100, obligatorio: false)),
                _opcional<RangoIngreso>(
                  etiqueta: 'Ingreso mensual',
                  icono: Icons.payments_outlined,
                  valor: _rangoIngreso,
                  opciones: {for (final r in RangoIngreso.values) r: r.etiqueta},
                  alCambiar: (r) => setState(() => _rangoIngreso = r),
                ),
              ],
            ),
            if (!widget.esEdicion)
              _Seccion(
                titulo: 'Acceso',
                icono: Icons.lock_outline,
                children: [
                  _texto('password', 'Contraseña', Icons.key_outlined,
                      esContrasena: true,
                      ayuda: 'Mínimo 8 caracteres con mayúscula, minúscula, número y carácter especial',
                      validator: ValidacionesCliente.password,
                      autofill: const [AutofillHints.newPassword]),
                  _texto('confirmarPassword', 'Confirmar contraseña', Icons.key_outlined,
                      esContrasena: true,
                      validator: (v) => ValidacionesCliente.confirmarPassword(v, _c['password']!.text)),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              texto: widget.textoBoton,
              icono: Icons.save_outlined,
              expandir: true,
              cargando: widget.guardando,
              onPressed: _guardar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _texto(
    String campo,
    String etiqueta,
    IconData icono, {
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatos,
    TextInputType? teclado,
    String? ayuda,
    bool habilitado = true,
    bool esContrasena = false,
    int? longitudMaxima,
    Iterable<String>? autofill,
    ValueChanged<String>? alCambiar,
  }) =>
      AppTextField(
        longitudMaxima: longitudMaxima,
        mostrarContador: longitudMaxima != null,
        etiqueta: etiqueta,
        controller: _c[campo],
        icono: icono,
        validator: validator,
        formatos: formatos,
        teclado: teclado,
        ayuda: ayuda,
        esContrasena: esContrasena,
        autofill: autofill,
        accion: TextInputAction.next,
        habilitado: habilitado && !widget.guardando,
        onChanged: alCambiar,
      );

  Widget _campoFecha(bool bloqueado) {
    final hoy = DateTime.now();
    final limite = DateTime(hoy.year - ValidacionesCliente.edadMinima, hoy.month, hoy.day);
    return TextFormField(
      controller: _c['fecha'],
      readOnly: true,
      enabled: !bloqueado,
      decoration: const InputDecoration(
        labelText: 'Fecha de nacimiento',
        prefixIcon: Icon(Icons.cake_outlined),
        helperText: 'Debes ser mayor de edad',
      ),
      validator: (_) => ValidacionesCliente.fechaNacimiento(_fechaNacimiento) ?? _coincideConCurpGuardada(),
      onTap: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: _fechaNacimiento ?? limite,
          firstDate: DateTime(hoy.year - ValidacionesCliente.edadMaxima),
          lastDate: limite,
          helpText: 'Fecha de nacimiento',
        );
        if (elegida != null && mounted) {
          setState(() {
            _fechaNacimiento = elegida;
            _c['fecha']!.text = _formatoFecha(elegida);
          });
        }
      },
    );
  }

  Widget _campoColonia(bool bloqueado) {
    final colonias = [...?_infoCp?.colonias];
    if (_colonia != null && !colonias.contains(_colonia)) colonias.insert(0, _colonia!);
    return DropdownButtonFormField<String>(
      key: ValueKey('colonia-${_infoCp?.codigoPostal}'),
      initialValue: _colonia,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Colonia',
        prefixIcon: const Icon(Icons.location_city_outlined),
        helperText: colonias.isEmpty ? 'Escribe primero el código postal' : null,
      ),
      items: [for (final c in colonias) DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))],
      onChanged: bloqueado || colonias.isEmpty ? null : (c) => setState(() => _colonia = c),
      validator: (c) => c == null ? 'Elige la colonia' : null,
    );
  }

  Widget _desplegable<T>({
    required String etiqueta,
    required IconData icono,
    required T? valor,
    required Map<T, String> opciones,
    required ValueChanged<T?>? alCambiar,
  }) =>
      DropdownButtonFormField<T>(
        initialValue: valor,
        isExpanded: true,
        decoration: InputDecoration(labelText: etiqueta, prefixIcon: Icon(icono)),
        items: [for (final o in opciones.entries) DropdownMenuItem(value: o.key, child: Text(o.value))],
        onChanged: alCambiar,
        validator: (v) =>
            ValidacionesCliente.obligatorio(v, campo: etiqueta) ?? (v is Sexo ? _coincideConCurpGuardada() : null),
      );

  /// Desplegable de un catalogo opcional: la primera opcion deja el dato sin especificar.
  Widget _opcional<T extends Object>({
    required String etiqueta,
    required IconData icono,
    required T? valor,
    required Map<T, String> opciones,
    required ValueChanged<T?> alCambiar,
  }) =>
      DropdownButtonFormField<T?>(
        initialValue: valor,
        isExpanded: true,
        decoration: InputDecoration(labelText: etiqueta, prefixIcon: Icon(icono)),
        items: [
          const DropdownMenuItem(child: Text('Sin especificar')),
          for (final o in opciones.entries)
            DropdownMenuItem(value: o.key, child: Text(o.value, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: widget.guardando ? null : alCambiar,
      );

  /// En la edicion la CURP no cambia, asi que la fecha y el sexo deben seguir coincidiendo con ella.
  String? _coincideConCurpGuardada() {
    if (!widget.esEdicion) return null;
    final error = ValidacionesCliente.curp(_c['curp']!.text, fechaNacimiento: _fechaNacimiento, sexo: _sexo);
    return error != null && error.contains('no coincide') ? error : null;
  }
}

/// Grupo de campos con titulo. En pantallas anchas acomoda los campos en dos columnas.
class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.icono, required this.children});

  final String titulo;
  final IconData icono;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, color: tema.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Semantics(header: true, child: Text(titulo, style: tema.textTheme.titleMedium)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, restricciones) {
                  final dosColumnas = restricciones.maxWidth >= 560;
                  final ancho = dosColumnas ? (restricciones.maxWidth - AppSpacing.md) / 2 : restricciones.maxWidth;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [for (final c in children) SizedBox(width: ancho, child: c)],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
