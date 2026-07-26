import 'package:flutter/material.dart';
import '../../inicio_marketplace/diseno/tarjeta_local_universitario.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';

/// Alias visual del catálogo que reutiliza la tarjeta principal sin duplicarla.
class TarjetaLocal extends StatelessWidget {
  const TarjetaLocal({required this.local, required this.alAbrir, super.key});
  final LocalUniversitario local;
  final VoidCallback alAbrir;

  @override
  Widget build(BuildContext context) =>
      TarjetaLocalUniversitario(local: local, alAbrir: alAbrir);
}
