import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../diseno/selector_carrera.dart';
import '../logica/controlador_onboarding.dart';

/// Completa nombre, carrera y WhatsApp antes de publicar o pedir.
class PantallaOnboarding extends StatelessWidget {
  const PantallaOnboarding({
    required this.controlador,
    required this.alCompletar,
    super.key,
  });

  final ControladorOnboarding controlador;
  final VoidCallback alCompletar;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: AnimatedBuilder(
              animation: controlador,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ya casi estás',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Completa tu perfil para poder publicar y pedir dentro '
                    'del campus.',
                    style: TextStyle(color: Color(0xFF858585), height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  _CampoNombre(controlador: controlador),
                  const SizedBox(height: 16),
                  SelectorCarrera(
                    carrerasPorFacultad: controlador.carrerasPorFacultad,
                    carreraId: controlador.borrador.carreraId,
                    alSeleccionar: controlador.actualizarCarrera,
                    cargando: controlador.cargandoCarreras,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: controlador.actualizarWhatsapp,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp',
                      hintText: '70012345',
                      // Bolivia: el backend antepone el 591 al guardar, para
                      // que el enlace wa.me funcione.
                      prefixText: '+591 ',
                      prefixStyle: TextStyle(
                        color: Color(0xFF292A29),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      prefixIcon: Icon(Icons.chat_outlined),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Solo se comparte con la otra parte después de aceptar '
                    'un pedido.',
                    style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
                  ),
                  if (controlador.errorServidor != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      controlador.errorServidor!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: controlador.enviando
                          ? null
                          : () async {
                              if (await controlador.enviar()) alCompletar();
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5C8A63),
                        shape: const StadiumBorder(),
                      ),
                      child: controlador.enviando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Continuar'),
                    ),
                  ),
                  // Aviso de validacion: aparece solo cuando el estudiante ya
                  // empezo a completar, para no regañar al abrir la pantalla
                  // (el nombre llega prellenado desde la cuenta institucional).
                  if ((controlador.borrador.carreraId != null ||
                          controlador.borrador.whatsapp.isNotEmpty) &&
                      controlador.borrador.error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      controlador.borrador.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF9A9A9A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Nombre del estudiante.
///
/// Cuando la cuenta institucional ya lo entrega (caso normal en UPSA) se
/// muestra bloqueado: es la identidad verificada por la universidad y no
/// deberia poder falsearse en un marketplace donde la gente queda en verse.
/// Solo si Google no devolvio nombre se pide escribirlo.
class _CampoNombre extends StatelessWidget {
  const _CampoNombre({required this.controlador});

  final ControladorOnboarding controlador;

  @override
  Widget build(BuildContext context) {
    if (controlador.nombreEsEditable) {
      return TextField(
        onChanged: controlador.actualizarNombre,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Nombre completo',
          prefixIcon: Icon(Icons.badge_outlined),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            prefixIcon: Icon(Icons.badge_outlined),
            suffixIcon: Icon(
              Icons.verified_rounded,
              color: Color(0xFF5C8A63),
              size: 21,
            ),
          ),
          child: Text(
            controlador.borrador.nombreCompleto,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF292A29),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 6),
          child: Text(
            'Tomado de tu cuenta institucional.',
            style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
          ),
        ),
      ],
    );
  }
}
