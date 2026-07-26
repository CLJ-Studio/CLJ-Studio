import 'package:flutter/material.dart';

class BotonNavegacionLocales extends StatelessWidget {
  const BotonNavegacionLocales({
    required this.activo,
    required this.alPresionar,
    super.key,
  });
  final bool activo;
  final VoidCallback alPresionar;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Locales',
    onPressed: alPresionar,
    icon: Icon(activo ? Icons.storefront : Icons.storefront_outlined),
  );
}
