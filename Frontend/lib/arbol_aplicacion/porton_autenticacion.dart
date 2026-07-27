import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../elementos_compartidos/sesion/sesion_usuario.dart';
import '../funcionalidades/acceso_upsa/arbol/arbol_acceso_upsa.dart';
import '../funcionalidades/carrito_compras/logica/controlador_carrito_compras.dart';
import '../funcionalidades/favoritos/logica/controlador_favoritos.dart';
import '../funcionalidades/notificaciones/datos/servicio_push.dart';
import '../funcionalidades/notificaciones/logica/controlador_notificaciones.dart';
import '../funcionalidades/navegacion_principal/arbol/arbol_navegacion_principal.dart';
import '../funcionalidades/onboarding_usuario/arbol/arbol_onboarding.dart';

/// Situacion del perfil del usuario autenticado.
enum _EstadoPerfil {
  /// Hay sesion pero no existe fila en `profiles` (usuario borrado).
  inexistente,

  /// Falta completar nombre, carrera y WhatsApp.
  pendiente,

  /// Listo para usar la aplicacion.
  completo,
}

/// Decide que pantalla mostrar segun la sesion real de Supabase:
/// sin sesion -> acceso; sesion sin onboarding -> onboarding; completo -> app.
///
/// Reemplaza la navegacion manual (Navigator.pushReplacementNamed) porque
/// en Flutter Web el login redirige la pestana entera: al volver, la app
/// arranca de cero y necesita leer el estado real, no recordar un push previo.
class PortonAutenticacion extends StatefulWidget {
  const PortonAutenticacion({super.key});

  @override
  State<PortonAutenticacion> createState() => _PortonAutenticacionState();
}

class _PortonAutenticacionState extends State<PortonAutenticacion> {
  StreamSubscription<AuthState>? _suscripcion;

  @override
  void initState() {
    super.initState();
    _suscripcion = Supabase.instance.client.auth.onAuthStateChange.listen((
      evento,
    ) {
      // Todo lo cacheado pertenece a la sesion anterior: se descarta para
      // que el siguiente usuario no vea datos que no son suyos.
      if (evento.event == AuthChangeEvent.signedOut) {
        SesionUsuario.instancia.limpiar();
        ControladorFavoritos.instancia.limpiar();
        ControladorCarritoCompras.instancia.vaciar();
        ControladorNotificaciones.instancia.limpiar();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  Future<_EstadoPerfil> _leerEstadoPerfil(String userId) async {
    final fila = await Supabase.instance.client
        .from('profiles')
        .select('onboarding_completed')
        .eq('id', userId)
        .maybeSingle();

    if (fila == null) return _EstadoPerfil.inexistente;

    return (fila['onboarding_completed'] as bool? ?? false)
        ? _EstadoPerfil.completo
        : _EstadoPerfil.pendiente;
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Supabase.instance.client.auth.currentUser;
    if (usuario == null) return const ArbolAccesoUpsa();

    return FutureBuilder<_EstadoPerfil>(
      // La key reinicia el Future si cambia el usuario (p. ej. tras logout+login).
      key: ValueKey(usuario.id),
      future: _leerEstadoPerfil(usuario.id),
      builder: (context, snapshot) {
        // Un fallo aqui (red caida, permisos) dejaba la pantalla en blanco
        // para siempre. Ahora se explica y se ofrece salida.
        if (snapshot.hasError) {
          return _PantallaErrorSesion(
            detalle: snapshot.error.toString(),
            alReintentar: () => setState(() {}),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Hay sesion pero el perfil no existe: el usuario fue borrado en el
        // servidor mientras el JWT seguia vigente. Sin esto, el onboarding
        // actualizaria cero filas y el usuario quedaria en un bucle.
        if (snapshot.data == _EstadoPerfil.inexistente) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Supabase.instance.client.auth.signOut();
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == _EstadoPerfil.completo) {
          // Precarga lo que varias pantallas comparten: el perfil (saludo y
          // configuracion) y los favoritos (corazones del catalogo).
          SesionUsuario.instancia.cargar();
          ControladorFavoritos.instancia.cargar();
          ControladorNotificaciones.instancia.cargar();
          // Solo si el dispositivo YA esta suscrito: refresca la fila por si
          // el endpoint roto. Comprobar unicamente el permiso reactivaria
          // los avisos de quien los apago a proposito.
          ServicioPush.estaActivo().then((activo) {
            if (activo) ServicioPush.activar();
          });
          return const ArbolNavegacionPrincipal();
        }
        return ArbolOnboarding(
          alCompletar: () {
            // El onboarding acaba de escribir el perfil: se refresca.
            SesionUsuario.instancia.cargar(forzar: true);
            setState(() {});
          },
        );
      },
    );
  }
}

/// Salida visible cuando no se puede leer el perfil del usuario autenticado.
class _PantallaErrorSesion extends StatelessWidget {
  const _PantallaErrorSesion({
    required this.detalle,
    required this.alReintentar,
  });

  final String detalle;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 54),
              const SizedBox(height: 18),
              Text(
                'No pudimos cargar tu perfil',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                detalle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF858585), fontSize: 12),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: alReintentar,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Reintentar'),
              ),
              TextButton(
                onPressed: () => Supabase.instance.client.auth.signOut(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
