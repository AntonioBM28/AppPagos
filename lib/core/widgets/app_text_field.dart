import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Campo de texto con etiqueta, validacion y soporte para contrasenas.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.etiqueta,
    this.controller,
    this.validator,
    this.ayuda,
    this.icono,
    this.esContrasena = false,
    this.teclado,
    this.accion,
    this.autofill,
    this.formatos,
    this.longitudMaxima,
    this.habilitado = true,
    this.mostrarContador = false,
    this.onSubmitted,
    this.onChanged,
    super.key,
  });

  final String etiqueta;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? ayuda;
  final IconData? icono;
  final bool esContrasena;
  final TextInputType? teclado;
  final TextInputAction? accion;
  final Iterable<String>? autofill;
  final List<TextInputFormatter>? formatos;
  final int? longitudMaxima;
  final bool habilitado;

  /// Muestra "n/max" debajo del campo (requiere [longitudMaxima]).
  final bool mostrarContador;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _oculto = widget.esContrasena;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      enabled: widget.habilitado,
      obscureText: _oculto,
      enableSuggestions: !widget.esContrasena,
      autocorrect: !widget.esContrasena,
      keyboardType: widget.teclado,
      textInputAction: widget.accion,
      autofillHints: widget.autofill,
      inputFormatters: widget.formatos,
      maxLength: widget.longitudMaxima,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        helperText: widget.ayuda,
        helperMaxLines: 2,
        errorMaxLines: 3,
        counterText: widget.mostrarContador ? null : '',
        prefixIcon: widget.icono == null ? null : Icon(widget.icono),
        suffixIcon: widget.esContrasena
            ? IconButton(
                tooltip: _oculto ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: Icon(_oculto ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _oculto = !_oculto),
              )
            : null,
      ),
    );
  }
}
