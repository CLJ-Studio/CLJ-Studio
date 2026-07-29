import 'package:flutter/material.dart';

/// Botón principal del acceso, con el mismo cuerpo que tenía el de Google.
///
/// La etiqueta cambia según el paso porque el botón es el mismo sitio de la
/// pantalla: primero pide el código y luego lo confirma.
class BotonAccesoCorreo extends StatelessWidget {
  const BotonAccesoCorreo({
    required this.habilitado,
    required this.cargando,
    required this.texto,
    required this.icono,
    required this.alPresionar,
    super.key,
  });

  final bool habilitado;
  final bool cargando;
  final String texto;
  final IconData icono;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1D1D1D),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFD9D9D9),
        shape: const StadiumBorder(),
      ),
      onPressed: habilitado && !cargando ? alPresionar : null,
      // El indicador ocupa el sitio del icono para que el botón no cambie de
      // tamaño al empezar a cargar.
      icon: cargando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icono, size: 20),
      label: Text(texto),
    ),
  );
}
