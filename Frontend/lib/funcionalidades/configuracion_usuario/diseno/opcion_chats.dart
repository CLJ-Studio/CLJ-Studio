import 'package:flutter/material.dart';

import '../../pedidos/pantalla/pantalla_chats.dart';

/// Segunda puerta a las conversaciones, desde Configuracion.
///
/// La primera es el boton del encabezado. Se pone tambien aqui porque el
/// encabezado se encoge al desplazarse y no esta en todas las pantallas, y
/// quien busca algo termina mirando en Configuracion.
class OpcionChats extends StatelessWidget {
  const OpcionChats({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PantallaChats())),
    leading: const Icon(Icons.forum_outlined, color: Colors.black),
    title: const Text('Chats'),
    subtitle: const Text('Conversaciones de tus pedidos'),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
