import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// `notifyListeners` que nunca cae dentro de una construccion en curso.
///
/// POR QUE: los controladores arrancan su carga desde `initState` o desde el
/// propio `build` del porton de autenticacion, o sea EN MEDIO de la fase de
/// construccion. Y casi todos avisan antes de su primer `await`, para marcar
/// "cargando". Ese aviso llega mientras Flutter esta construyendo, los
/// `AnimatedBuilder` que escuchan llaman a `setState` en ese momento, y el
/// framework lo rechaza:
///
///   setState() or markNeedsBuild() called during build.
///
/// Apareció en un Samsung A15 la primera vez que se ejecuto la aplicacion en
/// un telefono de verdad. Ni el analizador ni las pruebas lo ven, porque no
/// es un error de tipos ni de una pantalla suelta: hace falta que coincidan
/// un controlador avisando y alguien escuchandolo dentro del mismo frame.
///
/// Lo que se pierde al aplazar: nada visible. El aviso llega al terminar el
/// frame en curso, o sea unos milisegundos despues, y ese aviso solo dice
/// "empece a cargar".
mixin AvisoSeguro on ChangeNotifier {
  void avisar() {
    final fase = SchedulerBinding.instance.schedulerPhase;
    final construyendo =
        fase == SchedulerPhase.persistentCallbacks ||
        fase == SchedulerPhase.midFrameMicrotasks;

    if (!construyendo) {
      notifyListeners();
      return;
    }

    // Se avisa en cuanto el frame termine. Un microtask no serviria: se
    // ejecutaria todavia dentro de la misma construccion.
    SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }
}
