import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/controlador_tema.dart';

/// Cambia entre tema claro y oscuro. La preferencia se recuerda.
class OpcionTemaAplicacion extends StatelessWidget {
  const OpcionTemaAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = ControladorTema.instancia;

    return AnimatedBuilder(
      animation: tema,
      builder: (context, _) => SwitchListTile(
        secondary: Icon(
          tema.esOscuro ? Icons.dark_mode_rounded : Icons.light_mode_outlined,
        ),
        title: const Text('Tema oscuro'),
        subtitle: Text(tema.esOscuro ? 'Activado' : 'Más cómodo de noche'),
        value: tema.esOscuro,
        onChanged: (valor) => tema.cambiar(oscuro: valor),
      ),
    );
  }
}
