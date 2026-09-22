import 'package:flutter/material.dart';

import '../configuracion_aplicacion/configuracion_tema.dart';

/// Lo que se ve cuando no se pudo contactar al servidor al arrancar.
///
/// Existe para que nunca haya un arranque mudo: sin esto, un servidor caido
/// o un telefono sin datos dejaban la pantalla del color del tema para
/// siempre, y parecia que la aplicacion estaba rota.
///
/// El boton vuelve a intentar la conexion sin recargar nada: la aplicacion ya
/// esta en pie, lo unico que falto fue el servidor.
class PantallaSinConexion extends StatelessWidget {
  const PantallaSinConexion({required this.alReintentar, super.key});

  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 52,
                color: ConfiguracionTema.grisCalido,
              ),
              const SizedBox(height: 18),
              const Text(
                'No pudimos conectar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Revisa tu conexión y vuelve a intentarlo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ConfiguracionTema.grisCalido),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: alReintentar,
                style: FilledButton.styleFrom(
                  backgroundColor: ConfiguracionTema.grafito,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 34,
                    vertical: 15,
                  ),
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
