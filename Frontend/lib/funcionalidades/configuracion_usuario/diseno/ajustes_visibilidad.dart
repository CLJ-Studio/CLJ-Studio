import 'package:flutter/material.dart';

import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../datos/repositorio_configuracion.dart';
import '../modelos/usuario_upsa.dart';

/// Qué partes del perfil ve el resto de la comunidad.
///
/// Vive dentro de Privacidad, junto al texto que explica qué se guarda: es
/// donde alguien va a buscarlo cuando se pregunte quién ve qué.
class AjustesVisibilidad extends StatefulWidget {
  const AjustesVisibilidad({super.key});

  @override
  State<AjustesVisibilidad> createState() => _AjustesVisibilidadState();
}

class _AjustesVisibilidadState extends State<AjustesVisibilidad> {
  static const _repositorio = RepositorioConfiguracion();

  bool? _vistas;
  bool? _favoritos;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    await SesionUsuario.instancia.cargar();
    if (!mounted) return;
    if (SesionUsuario.instancia.perfil case final UsuarioUpsa perfil) {
      setState(() {
        _vistas = perfil.muestraVistas;
        _favoritos = perfil.muestraFavoritos;
      });
    }
  }

  /// Se pinta el cambio antes de que responda el servidor y se revierte si
  /// falla: un interruptor que tarda en moverse se siente roto.
  Future<void> _guardar({bool? vistas, bool? favoritos}) async {
    final anteriorVistas = _vistas;
    final anteriorFavoritos = _favoritos;

    setState(() {
      _vistas = vistas ?? _vistas;
      _favoritos = favoritos ?? _favoritos;
      _guardando = true;
    });

    try {
      await _repositorio.guardarPrivacidad(
        muestraVistas: _vistas ?? true,
        muestraFavoritos: _favoritos ?? false,
      );
      await SesionUsuario.instancia.cargar(forzar: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _vistas = anteriorVistas;
        _favoritos = anteriorFavoritos;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el cambio.')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Qué ve el resto de tu perfil',
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SwitchListTile(
            value: _vistas ?? true,
            onChanged: _vistas == null || _guardando
                ? null
                : (valor) => _guardar(vistas: valor),
            title: const Text(
              'Vistas de mis publicaciones',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Cuánta gente ha visto lo que publicas. Se sigue contando '
              'aunque lo apagues: solo deja de mostrarse.',
            ),
          ),
          SwitchListTile(
            value: _favoritos ?? false,
            onChanged: _favoritos == null || _guardando
                ? null
                : (valor) => _guardar(favoritos: valor),
            title: const Text(
              'Mis favoritos',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Lo que guardas con el corazón. Apagado, solo lo ves tú.',
            ),
          ),
        ],
      ),
    );
  }
}
