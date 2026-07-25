import 'package:flutter/material.dart';
import '../../../elementos_compartidos/botones_aplicacion/boton_primario.dart';

class BotonContinuarPedido extends StatelessWidget {
  const BotonContinuarPedido({
    required this.habilitado,
    required this.alPresionar,
    super.key,
  });
  final bool habilitado;
  final VoidCallback alPresionar;
  @override
  Widget build(BuildContext context) => BotonPrimario(
    texto: 'Continuar con el pedido',
    icono: Icons.arrow_forward_rounded,
    alPresionar: habilitado ? alPresionar : null,
  );
}
