import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../datos/repositorio_configuracion.dart';
import '../modelos/usuario_upsa.dart';

/// "Soy egresado". Los egresados conservan su correo de estudiante y entran
/// igual que siempre, asi que la unica forma de saberlo es que lo digan. Y
/// como decirlo no basta (cualquiera podria), lo piden y un admin lo
/// verifica antes de que la UPSA lo vea en el directorio.
class OpcionEgresado extends StatefulWidget {
  const OpcionEgresado({super.key});

  @override
  State<OpcionEgresado> createState() => _OpcionEgresadoState();
}

class _OpcionEgresadoState extends State<OpcionEgresado> {
  static const _repositorio = RepositorioConfiguracion();
  bool _enviando = false;

  Future<void> _pedir() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Ya te graduaste?'),
        content: const Text(
          'Un admin de U market lo va a verificar. Cuando lo apruebe, la '
          'UPSA te verá como egresado en el directorio de proveedores.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: const Text('Sí, pedirlo'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _enviando = true);
    try {
      await _repositorio.solicitarEgresado();
      await SesionUsuario.instancia.cargar(forzar: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: SesionUsuario.instancia,
    builder: (context, _) {
      final estado = SesionUsuario.instancia.perfil?.estadoEgresado;
      final (titulo, detalle) = switch (estado) {
        EstadoEgresado.verificado => (
          'Egresado verificado',
          'Así te ve la UPSA en el directorio',
        ),
        EstadoEgresado.enRevision => (
          'Soy egresado',
          'En revisión: un admin la está verificando',
        ),
        EstadoEgresado.rechazado => (
          'Soy egresado',
          'No se pudo verificar. Si ya te graduaste, pídela de nuevo',
        ),
        _ => ('Soy egresado', 'Pide la marca: un admin la verifica'),
      };
      final puedePedir =
          estado == EstadoEgresado.sinPedir ||
          estado == EstadoEgresado.rechazado;

      return ListTile(
        leading: const Icon(Icons.workspace_premium_outlined),
        title: Text(titulo),
        subtitle: Text(detalle),
        trailing: switch (estado) {
          EstadoEgresado.verificado => const Icon(
            Icons.verified_rounded,
            color: ConfiguracionTema.interruptorActivo,
            semanticLabel: 'Verificado',
          ),
          EstadoEgresado.enRevision => const Icon(
            Icons.hourglass_top_rounded,
            semanticLabel: 'En revisión',
          ),
          _ => TextButton(
            onPressed: _enviando || !puedePedir ? null : _pedir,
            child: Text(
              estado == EstadoEgresado.rechazado ? 'Pedir de nuevo' : 'Pedir',
            ),
          ),
        },
      );
    },
  );
}
