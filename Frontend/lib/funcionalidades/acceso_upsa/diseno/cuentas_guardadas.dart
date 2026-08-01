import 'package:flutter/material.dart';

import '../datos/cuentas_recordadas.dart';

/// Cuentas que ya entraron en este dispositivo.
///
/// Existe para no volver a teclear diez dígitos cada vez que se cierra
/// sesión. Elegir una no salta ninguna comprobación: el código llega igual
/// al correo, solo se ahorra escribirlo.
class CuentasGuardadas extends StatelessWidget {
  const CuentasGuardadas({
    required this.cuentas,
    required this.alElegir,
    required this.alOlvidar,
    super.key,
  });

  final List<String> cuentas;
  final ValueChanged<String> alElegir;
  final ValueChanged<String> alOlvidar;

  @override
  Widget build(BuildContext context) {
    if (cuentas.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 16,
          children: [
            for (final cuenta in cuentas)
              _CuentaCircular(
                cuenta: cuenta,
                alElegir: () => alElegir(cuenta),
                alOlvidar: () => alOlvidar(cuenta),
              ),
          ],
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}

class _CuentaCircular extends StatelessWidget {
  const _CuentaCircular({
    required this.cuenta,
    required this.alElegir,
    required this.alOlvidar,
  });

  final String cuenta;
  final VoidCallback alElegir;
  final VoidCallback alOlvidar;

  String get _registro {
    final inicio = cuenta.split('@').first;
    return inicio.startsWith('a') ? inicio.substring(1) : inicio;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 88,
    child: Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              shape: const CircleBorder(),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: alElegir,
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: FutureBuilder<String?>(
                    future: CuentasRecordadas.leerAvatar(cuenta),
                    builder: (context, foto) {
                      final avatarUrl = foto.data;
                      if (avatarUrl != null && avatarUrl.isNotEmpty) {
                        return Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _AvatarSinFoto(
                            inicial: _registro.substring(0, 1).toUpperCase(),
                          ),
                        );
                      }
                      return _AvatarSinFoto(
                        inicial: _registro.substring(0, 1).toUpperCase(),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              right: -5,
              top: -5,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: alOlvidar,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _registro,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _AvatarSinFoto extends StatelessWidget {
  const _AvatarSinFoto({required this.inicial});

  final String inicial;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Center(
      child: Text(
        inicial,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}
