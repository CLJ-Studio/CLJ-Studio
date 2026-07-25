import 'package:flutter/material.dart';

/// Área visual de imágenes; no abre archivos ni sube contenido todavía.
class SelectorImagenesPublicacion extends StatelessWidget {
  const SelectorImagenesPublicacion({super.key});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Carga de imagenes disponible al conectar el backend.'),
      ),
    ),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 40),
          SizedBox(height: 8),
          Text('Seleccionar imagenes'),
          Text(
            'Vista previa temporal',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}
