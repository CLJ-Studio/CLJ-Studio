import 'package:flutter/material.dart';

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
    required this.alAgregar,
    super.key,
  });

  final List<String> cuentas;
  final ValueChanged<String> alElegir;
  final ValueChanged<String> alOlvidar;
  final VoidCallback alAgregar;

  @override
  Widget build(BuildContext context) {
    if (cuentas.isEmpty) return const SizedBox.shrink();
    final tema = Theme.of(context);

    return Column(
      children: [
        Text(
          '¿Quién va a entrar?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tema.textTheme.bodyMedium?.color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
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
            _AgregarCuenta(alPresionar: alAgregar),
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
                child: const SizedBox(
                  width: 72,
                  height: 72,
                  child: Image(
                    image: AssetImage('assets/images/real/user.jpg'),
                    fit: BoxFit.cover,
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

class _AgregarCuenta extends StatelessWidget {
  const _AgregarCuenta({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 88,
    child: Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: alPresionar,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(
                Icons.add_rounded,
                size: 38,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Agregar',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
