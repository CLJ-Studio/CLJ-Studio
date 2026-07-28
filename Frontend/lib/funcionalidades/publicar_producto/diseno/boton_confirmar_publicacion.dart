import 'package:flutter/material.dart';

/// Envía la publicación. Se deshabilita pasando `null` mientras se guarda.
class BotonConfirmarPublicacion extends StatelessWidget {
  const BotonConfirmarPublicacion({required this.alPresionar, super.key});
  final VoidCallback? alPresionar;
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    duration: const Duration(milliseconds: 200),
    opacity: alPresionar == null ? .65 : 1,
    child: SizedBox(
      width: double.infinity,
      height: 64,
      child: FilledButton(
        onPressed: alPresionar,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF5F9368),
          disabledBackgroundColor: const Color(0xFFD5D8D5),
          disabledForegroundColor: const Color(0xFF777C79),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          elevation: 5,
          shadowColor: const Color(0x665F9368),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Text(
                'Publicar ahora',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
            Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    ),
  );
}
