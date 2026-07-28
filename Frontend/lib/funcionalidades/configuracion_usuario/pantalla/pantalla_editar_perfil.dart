import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../onboarding_usuario/datos/repositorio_onboarding.dart';
import '../../onboarding_usuario/diseno/selector_carrera.dart';
import '../../onboarding_usuario/modelos/carrera_upsa.dart';
import '../diseno/editor_negocio.dart';

/// Edición de los datos que el estudiante sí controla.
///
/// Nombre, correo y código no aparecen: los define la cuenta institucional.
class PantallaEditarPerfil extends StatefulWidget {
  const PantallaEditarPerfil({super.key});

  @override
  State<PantallaEditarPerfil> createState() => _PantallaEditarPerfilState();
}

class _PantallaEditarPerfilState extends State<PantallaEditarPerfil> {
  static const _repositorioCarreras = RepositorioOnboarding();

  final _whatsapp = TextEditingController();
  List<CarreraUpsa> _carreras = const [];
  String? _carreraId;
  String? _avatarPath;

  /// Foto ya guardada: sirve para no reescribirla si no cambio.
  String? _avatarOriginal;

  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoFoto = false;
  String? _error;

  Future<void> _elegirFoto() async {
    setState(() => _subiendoFoto = true);
    try {
      final ruta = await ServicioImagenes.elegirYSubir(etiqueta: 'perfil');
      if (ruta != null) setState(() => _avatarPath = ruta);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo subir la foto.');
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _whatsapp.dispose();
    super.dispose();
  }

  Map<String, List<CarreraUpsa>> get _porFacultad {
    final agrupadas = <String, List<CarreraUpsa>>{};
    for (final carrera in _carreras) {
      agrupadas.putIfAbsent(carrera.facultad, () => []).add(carrera);
    }
    return agrupadas;
  }

  Future<void> _cargar() async {
    try {
      _carreras = await _repositorioCarreras.cargarCarreras();

      // Se asegura el perfil antes de leerlo: si no habia cargado, los
      // campos quedaban vacios y al guardar se escribia ese vacio encima.
      // Asi se perdia la foto al reiniciar sesion.
      await SesionUsuario.instancia.cargar();

      final perfil = SesionUsuario.instancia.perfil;
      _avatarPath = perfil?.avatarPath;
      _avatarOriginal = perfil?.avatarPath;
      if (perfil != null) {
        // El WhatsApp se guarda con el 591 delante; el campo muestra solo
        // los 8 digitos locales, igual que en el onboarding.
        final digitos = perfil.whatsapp;
        _whatsapp.text = digitos.startsWith('591') && digitos.length > 8
            ? digitos.substring(3)
            : digitos;

        _carreraId = _carreras
            .where((c) => c.nombre == perfil.carrera)
            .map((c) => c.id)
            .firstOrNull;
      }
    } catch (_) {
      _error = 'No se pudieron cargar tus datos.';
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (_carreraId == null) {
      setState(() => _error = 'Selecciona tu carrera.');
      return;
    }
    if (_whatsapp.text.replaceAll(RegExp(r'\D'), '').length != 8) {
      setState(() => _error = 'El número debe tener 8 dígitos.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.rpc(
        'actualizar_perfil',
        params: {'p_career_id': _carreraId, 'p_whatsapp': _whatsapp.text},
      );

      // La foto es la unica columna del perfil con escritura directa:
      // es una ruta del bucket, sin nada que validar en el servidor.
      // Solo se escribe si cambio: hacerlo siempre arriesga sobrescribir
      // la guardada con un valor a medio cargar.
      if (_avatarPath != _avatarOriginal) {
        await Supabase.instance.client
            .from('profiles')
            .update({'avatar_path': _avatarPath})
            .eq('id', Supabase.instance.client.auth.currentUser!.id);
      }
      // Refresca la copia compartida para que el resto de la app la vea.
      await SesionUsuario.instancia.cargar(forzar: true);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = 'No se pudo guardar. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Editar perfil',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: _cargando
        ? const Center(child: IndicadorCarga())
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SelectorFotoPerfil(
                      fotoUrl: ServicioImagenes.urlPublica(_avatarPath),
                      inicial: SesionUsuario.instancia.perfil?.inicial ?? '?',
                      subiendo: _subiendoFoto,
                      alElegir: _elegirFoto,
                      alQuitar: () => setState(() => _avatarPath = null),
                    ),
                    const SizedBox(height: 26),
                    const _DatosInstitucionales(),
                    const SizedBox(height: 26),
                    SelectorCarrera(
                      carrerasPorFacultad: _porFacultad,
                      carreraId: _carreraId,
                      alSeleccionar: (valor) =>
                          setState(() => _carreraId = valor),
                      cargando: false,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _whatsapp,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: InputDecoration(
                        labelText: 'WhatsApp',
                        hintText: '70012345',
                        prefixText: '+591 ',
                        prefixStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
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
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 22),
                    const _InterruptorCampus(),
                    // Solo se muestra a quien tiene un local formal.
                    const EditorNegocio(),
                    if (_error case final String mensaje) ...[
                      const SizedBox(height: 14),
                      Text(
                        mensaje,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _guardando ? null : _guardar,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5C8A63),
                          shape: const StadiumBorder(),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: IndicadorCarga(tamanio: 22),
                              )
                            : const Text('Guardar cambios'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );
}

/// Datos que vienen de la cuenta institucional y no se editan.
class _DatosInstitucionales extends StatelessWidget {
  const _DatosInstitucionales();

  @override
  Widget build(BuildContext context) {
    final perfil = SesionUsuario.instancia.perfil;
    if (perfil == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 18,
                color: Color(0xFF5C8A63),
              ),
              const SizedBox(width: 8),
              Text(
                perfil.nombre,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            perfil.correo,
            style: const TextStyle(color: Color(0xFF7C827E), fontSize: 13),
          ),
          const SizedBox(height: 10),
          const Text(
            'Estos datos vienen de tu cuenta institucional y no se pueden '
            'cambiar.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Estado "en campus / fuera": se guarda al instante, sin botón.
class _InterruptorCampus extends StatefulWidget {
  const _InterruptorCampus();

  @override
  State<_InterruptorCampus> createState() => _InterruptorCampusState();
}

class _InterruptorCampusState extends State<_InterruptorCampus> {
  late bool _enCampus = SesionUsuario.instancia.perfil?.enCampus ?? false;
  bool _guardando = false;

  Future<void> _cambiar(bool valor) async {
    setState(() {
      _enCampus = valor;
      _guardando = true;
    });
    try {
      // Es la unica columna de `profiles` con permiso de escritura directa:
      // un interruptor sin nada que validar.
      await Supabase.instance.client
          .from('profiles')
          .update({'is_on_campus': valor})
          .eq('id', Supabase.instance.client.auth.currentUser!.id);
      await SesionUsuario.instancia.cargar(forzar: true);
    } catch (_) {
      if (mounted) setState(() => _enCampus = !valor);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: _enCampus,
    onChanged: _guardando ? null : _cambiar,
    contentPadding: EdgeInsets.zero,
    activeThumbColor: const Color(0xFF5C8A63),
    secondary: const Icon(Icons.location_on_outlined, color: Color(0xFF5C8A63)),
    title: const Text(
      'Estoy en el campus',
      style: TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: const Text(
      'Les indica a los compradores que puedes entregar ahora.',
      style: TextStyle(fontSize: 12),
    ),
  );
}

/// Foto de la persona. Opcional: quien no la sube conserva su inicial.
class _SelectorFotoPerfil extends StatelessWidget {
  const _SelectorFotoPerfil({
    required this.fotoUrl,
    required this.inicial,
    required this.subiendo,
    required this.alElegir,
    required this.alQuitar,
  });

  final String? fotoUrl;
  final String inicial;
  final bool subiendo;
  final VoidCallback alElegir;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 104,
            height: 104,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: subiendo
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: IndicadorCarga(tamanio: 28),
                    ),
                  )
                : switch (fotoUrl) {
                    final String url => Image.network(
                      url,
                      width: 104,
                      height: 104,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _InicialGrande(inicial),
                    ),
                    _ => _InicialGrande(inicial),
                  },
          ),
          Material(
            color: const Color(0xFF5C8A63),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: subiendo ? null : alElegir,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.photo_camera_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      if (fotoUrl != null && !subiendo)
        TextButton(
          onPressed: alQuitar,
          child: const Text('Quitar foto', style: TextStyle(fontSize: 12)),
        ),
    ],
  );
}

class _InicialGrande extends StatelessWidget {
  const _InicialGrande(this.inicial);
  final String inicial;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      inicial,
      style: const TextStyle(
        color: Color(0xFF55785A),
        fontSize: 38,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
