import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';

/// Que la cuenta esta verificada con el correo de la UPSA.
///
/// Es un ESTADO, no una opcion: no hay nada que abrir ni que cambiar. Antes
/// llevaba la flecha de las filas que llevan a otra pantalla, y tocarla no
/// hacia nada, que es peor que no tener flecha: parece roto. Ahora lleva la
/// marca de verificado y no responde al toque, como corresponde a algo que
/// solo informa.
class OpcionCuentaInstitucional extends StatelessWidget {
  const OpcionCuentaInstitucional({super.key});

  @override
  Widget build(BuildContext context) => const ListTile(
    leading: Icon(Icons.school_outlined),
    title: Text('Cuenta institucional'),
    subtitle: Text('Correo UPSA verificado'),
    trailing: Icon(
      Icons.verified_rounded,
      color: ConfiguracionTema.interruptorActivo,
      semanticLabel: 'Verificada',
    ),
  );
}
