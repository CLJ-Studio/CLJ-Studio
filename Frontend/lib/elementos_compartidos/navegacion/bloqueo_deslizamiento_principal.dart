import 'package:flutter/widgets.dart';

/// Evita que un control horizontal interno cambie también la sección principal.
class BloqueoDeslizamientoPrincipal extends Notification {
  const BloqueoDeslizamientoPrincipal(this.bloqueado);

  final bool bloqueado;
}
