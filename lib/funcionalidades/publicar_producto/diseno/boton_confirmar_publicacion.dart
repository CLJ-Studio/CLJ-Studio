import 'package:flutter/material.dart';
import '../../../elementos_compartidos/botones_aplicacion/boton_primario.dart';

/// Confirma únicamente la validación local del formulario.
class BotonConfirmarPublicacion extends StatelessWidget {
  const BotonConfirmarPublicacion({required this.alPresionar, super.key});
  final VoidCallback alPresionar;
  @override
  Widget build(BuildContext context) => BotonPrimario(
    texto: 'Publicar',
    icono: Icons.publish_rounded,
    alPresionar: alPresionar,
  );
}
