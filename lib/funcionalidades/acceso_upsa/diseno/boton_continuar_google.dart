import 'package:flutter/material.dart';

/// Botón visual de Google; ejecuta una simulación local por ahora.
class BotonContinuarGoogle extends StatelessWidget {
  const BotonContinuarGoogle({
    required this.habilitado,
    required this.alPresionar,
    super.key,
  });
  final bool habilitado;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1D1D1D),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD9D9D9),
          shape: const StadiumBorder(),
        ),
        onPressed: habilitado ? alPresionar : null,
        icon: const Text(
          'G',
          style: TextStyle(
            color: Color(0xFF86A989),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        label: const Text('Continuar con Google'),
      ),
    );
  }
}
