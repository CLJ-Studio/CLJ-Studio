import 'dart:async';

/// Junta en una sola consulta las llamadas que llegan mientras otra igual
/// todavia viaja.
///
/// El inicio pedia la lista de locales tres veces cada vez que cargaba
/// (publicaciones, populares y mas vistos, en paralelo): con esto viaja una.
/// Cuando la consulta termina no queda guardada para [pedir]: la llamada
/// siguiente siempre trae datos frescos, asi que un local que cierra se ve
/// igual que antes. Solo [reciente] devuelve lo ultimo traido, para quien
/// tolera un rato de atraso.
class ConsultaCompartida<T> {
  ConsultaCompartida(this._consultar, {DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now;

  final Future<T> Function() _consultar;
  final DateTime Function() _reloj;
  Future<T>? _enCamino;
  (DateTime, T)? _ultima;

  /// La consulta que esta viajando o, si no hay ninguna, una nueva.
  Future<T> pedir() {
    final enCamino = _enCamino;
    if (enCamino != null) return enCamino;

    final consulta = _consultar();
    _enCamino = consulta;
    unawaited(
      consulta
          .then<void>(
            (valor) => _ultima = (_reloj(), valor),
            // El error lo recibe quien llamo; aqui solo se suelta la consulta.
            onError: (Object _) {},
          )
          .whenComplete(() {
            if (identical(_enCamino, consulta)) _enCamino = null;
          }),
    );
    return consulta;
  }

  /// Lo ultimo traido si tiene menos de [maximo]; si no, [pedir].
  Future<T> reciente(Duration maximo) {
    final ultima = _ultima;
    if (ultima != null && _reloj().difference(ultima.$1) < maximo) {
      return Future.value(ultima.$2);
    }
    return pedir();
  }
}
