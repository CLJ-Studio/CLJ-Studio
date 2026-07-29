import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Seis casillas para escribir o pegar el código que llegó al correo.
class CampoCodigoVerificacion extends StatefulWidget {
  const CampoCodigoVerificacion({
    required this.alCambiar,
    required this.alEnviar,
    required this.esValido,
    this.hayError = false,
    super.key,
  });

  final ValueChanged<String> alCambiar;
  final VoidCallback alEnviar;
  final bool esValido;
  final bool hayError;

  /// Los códigos de Supabase son de seis dígitos.
  static const largo = 6;

  @override
  State<CampoCodigoVerificacion> createState() =>
      _CampoCodigoVerificacionState();
}

class _CampoCodigoVerificacionState extends State<CampoCodigoVerificacion> {
  final _controlador = TextEditingController();
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(_actualizarFoco);
  }

  void _actualizarFoco() => setState(() {});

  @override
  void dispose() {
    _foco
      ..removeListener(_actualizarFoco)
      ..dispose();
    _controlador.dispose();
    super.dispose();
  }

  void _alCambiar(String valor) {
    widget.alCambiar(valor);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF5C8A63);
    const gris = Color(0xFFB8BDB8);
    final tema = Theme.of(context);
    final digitos = _controlador.text;
    final casillaActiva = digitos.length.clamp(
      0,
      CampoCodigoVerificacion.largo - 1,
    );

    return Semantics(
      label: 'Código de verificación de seis dígitos',
      textField: true,
      child: GestureDetector(
        onTap: _foco.requestFocus,
        child: Stack(
          children: [
            Row(
              children: List.generate(CampoCodigoVerificacion.largo, (indice) {
                final activa = _foco.hasFocus && indice == casillaActiva;
                final colorBorde = widget.hayError
                    ? tema.colorScheme.error
                    : activa
                    ? verde
                    : gris;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: indice == CampoCodigoVerificacion.largo - 1
                          ? 0
                          : 8,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: activa
                            ? verde.withValues(alpha: .08)
                            : tema.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorBorde,
                          width: activa ? 2.4 : 1.4,
                        ),
                        boxShadow: activa
                            ? [
                                BoxShadow(
                                  color: verde.withValues(alpha: .18),
                                  blurRadius: 0,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        indice < digitos.length ? digitos[indice] : '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controlador,
                  focusNode: _foco,
                  onChanged: _alCambiar,
                  onSubmitted: (_) => widget.alEnviar(),
                  autofocus: true,
                  autocorrect: false,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      CampoCodigoVerificacion.largo,
                    ),
                  ],
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
