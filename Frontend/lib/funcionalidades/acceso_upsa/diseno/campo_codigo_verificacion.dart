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
    const verde = Color(0xFF2E7D32);
    const grafito = Color(0xFF474646);
    const gris = Color(0xFFBBBCA7);
    final tema = Theme.of(context);
    final digitos = _controlador.text;
    final casillaActiva = digitos.length.clamp(
      0,
      CampoCodigoVerificacion.largo - 1,
    );

    return AutofillGroup(
      child: SizedBox(
        height: 64,
        child: Stack(
          children: [
            // El campo real permanece renderizado, enfocado y ocupando toda
            // el área. Ocultarlo con Opacity(0) hacía que iOS pudiera dejarlo
            // fuera de los candidatos de QuickType aunque tuviera oneTimeCode.
            // Las casillas de abajo son únicamente la presentación visual.
            Positioned.fill(
              child: TextField(
                controller: _controlador,
                focusNode: _foco,
                onChanged: _alCambiar,
                onSubmitted: (_) => widget.alEnviar(),
                autofocus: true,
                autocorrect: false,
                enableSuggestions: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(
                    CampoCodigoVerificacion.largo,
                  ),
                ],
                maxLength: CampoCodigoVerificacion.largo,
                style: const TextStyle(color: Colors.transparent, fontSize: 24),
                cursorColor: Colors.transparent,
                showCursor: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
              ),
            ),
            IgnorePointer(
              child: Row(
                children: List.generate(CampoCodigoVerificacion.largo, (
                  indice,
                ) {
                  final activa = _foco.hasFocus && indice == casillaActiva;
                  final llena = indice < digitos.length;
                  final colorBorde = widget.hayError
                      ? tema.colorScheme.error
                      : llena
                      ? verde
                      : activa
                      ? grafito
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
                          color: widget.hayError
                              ? tema.colorScheme.error.withValues(alpha: .08)
                              : llena
                              ? verde
                              : activa
                              ? grafito.withValues(alpha: .08)
                              : tema.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorBorde,
                            width: llena || activa ? 2.4 : 1.4,
                          ),
                          boxShadow: activa
                              ? [
                                  BoxShadow(
                                    color: (llena ? verde : grafito).withValues(
                                      alpha: .18,
                                    ),
                                    blurRadius: 0,
                                    spreadRadius: 3,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          indice < digitos.length ? digitos[indice] : '',
                          style: TextStyle(
                            color: widget.hayError
                                ? tema.colorScheme.error
                                : llena
                                ? Colors.white
                                : grafito,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
