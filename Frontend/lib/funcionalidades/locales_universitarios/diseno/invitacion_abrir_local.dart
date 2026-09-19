import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';

/// Acceso para crear o administrar el local, presentado como una tarjeta más
/// del catálogo para no interrumpir visualmente la lista.
class InvitacionAbrirLocal extends StatelessWidget {
  const InvitacionAbrirLocal({
    required this.alPresionar,
    required this.yaTieneLocal,
    super.key,
  });

  final VoidCallback alPresionar;
  final bool yaTieneLocal;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: yaTieneLocal ? 'Administrar mi local' : 'Crear mi local',
    child: Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? ConfiguracionTema.grafito
          : Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        // Con local ya abierto lleva a administrarlo; sin él, a crearlo.
        onTap: alPresionar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF303A33)
                    : const Color(0xFFE6E1D5),
                child: SizedBox.expand(
                  child: Image.asset(
                    yaTieneLocal
                        ? 'assets/images/locales/buho-chef-administrar.png'
                        : 'assets/images/locales/buho-chef-comenzar.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          yaTieneLocal
                              ? 'Administra tu local'
                              : 'Crea tu local',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: ConfiguracionTema.primario,
                        size: 19,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        color: ConfiguracionTema.primario,
                        size: 17,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          yaTieneLocal
                              ? 'Inventario, ubicación y marca'
                              : 'Empieza a vender en el campus',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
