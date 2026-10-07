import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../modelos/mensaje_macias.dart';
import 'cerebro_macias.dart';
import 'memoria_macias.dart';

/// Cuanto tarda MacIAs en "escribir" cada burbuja.
///
/// Las respuestas estan listas al instante, pero soltarlas todas de golpe se
/// lee como un muro de texto: con una pausa corta, proporcional a lo que hay
/// que leer, cada burbuja llega cuando ya se termino de mirar la anterior.
class RitmoMacias {
  const RitmoMacias({this.inmediato = false});

  /// Sin pausas. Para quien pidio reducir el movimiento en su telefono, y
  /// para las pruebas.
  final bool inmediato;

  Duration para(String texto) {
    if (inmediato) return Duration.zero;
    final milisegundos = (420 + texto.length * 5).clamp(600, 1400);
    return Duration(milliseconds: milisegundos);
  }
}

/// La conversacion con MacIAs.
///
/// Se guarda en el telefono (ver `AlmacenMacias`) para que al volver siga
/// donde quedo y MacIAs se acuerde de la persona. Nada de esto viaja a un
/// servidor.
class ControladorChatMacias extends ChangeNotifier {
  ControladorChatMacias({
    required this.cerebro,
    required this.almacen,
    this.ritmo = const RitmoMacias(),
  });

  final CerebroMacias cerebro;
  final AlmacenMacias almacen;
  final RitmoMacias ritmo;

  final List<MensajeMacias> _mensajes = [];
  List<MensajeMacias> get mensajes => List.unmodifiable(_mensajes);

  /// Atajos sobre el campo de escribir. Se esconden mientras MacIAs escribe:
  /// tocarlos en ese momento cortaria la respuesta a la mitad.
  List<OpcionMacias> sugerencias = const [];

  bool escribiendo = false;

  /// Mientras se lee lo guardado. La pantalla muestra a MacIAs escribiendo.
  bool cargando = true;

  /// Cuantos mensajes vinieron de una visita anterior: esos no se animan.
  int restaurados = 0;

  final _pendientes = Queue<BurbujaMacias>();
  List<OpcionMacias> _sugerenciasPendientes = const [];
  Timer? _temporizador;
  Timer? _guardado;
  int _siguienteId = 0;
  bool _desechado = false;

  /// Lee lo guardado y sigue donde quedo, o saluda si es la primera vez.
  Future<void> iniciar() async {
    final guardado = await almacen.cargar();
    if (_desechado) return;
    cerebro.memoria.copiarDe(guardado.memoria);

    cargando = false;
    if (guardado.mensajes.isEmpty) {
      _encolar(cerebro.bienvenida());
      return;
    }
    _mensajes.addAll(guardado.mensajes);
    restaurados = _mensajes.length;
    _siguienteId =
        _mensajes.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;
    // Los numeros vuelven a referirse a la ultima lista que se ve.
    final ultimaLista = _mensajes.reversed
        .firstWhere(
          (m) => m.esDeMacias && m.opciones.isNotEmpty,
          orElse: () => _mensajes.last,
        )
        .opciones;
    cerebro.retomar(ultimaLista);
    // Si hay algo que decir (un examen, un cumpleaños, un recordatorio),
    // MacIAs lo dice apenas se vuelve.
    final novedad = cerebro.alVolver();
    if (novedad != null) {
      notifyListeners();
      _encolar(novedad);
      return;
    }
    sugerencias = const [
      CerebroMacias.chipMenu,
      CerebroMacias.chipMaterias,
      CerebroMacias.chipPersona,
    ];
    notifyListeners();
  }

  void escribir(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty || _desechado || cargando) return;
    _decirTodoYa();
    _agregar(AutorMensaje.persona, limpio);
    _encolar(cerebro.escribir(limpio));
  }

  void elegir(OpcionMacias opcion) {
    if (_desechado || cargando) return;
    _decirTodoYa();
    _agregar(AutorMensaje.persona, opcion.texto);
    _encolar(cerebro.elegir(opcion));
  }

  /// Borra la conversacion (no lo que sabe de la persona) y vuelve a saludar.
  void borrarConversacion() {
    _temporizador?.cancel();
    _pendientes.clear();
    _mensajes.clear();
    restaurados = 0;
    sugerencias = const [];
    escribiendo = false;
    _encolar(cerebro.bienvenida());
  }

  /// Olvida lo que la persona le conto. La conversacion queda.
  void olvidarLoQueSabe() => elegirComoOrden('Olvida lo que sabes de mí');

  /// Lo que se pide desde el menu de la pantalla entra como si la persona
  /// lo hubiera escrito: asi queda en la conversacion y MacIAs lo confirma.
  void elegirComoOrden(String texto) => escribir(texto);

  void _encolar(RespuestaMacias respuesta) {
    _pendientes.addAll(respuesta.burbujas);
    _sugerenciasPendientes = respuesta.sugerencias;
    sugerencias = const [];
    _siguiente();
  }

  void _siguiente() {
    if (_desechado) return;
    if (_pendientes.isEmpty) {
      escribiendo = false;
      sugerencias = _sugerenciasPendientes;
      notifyListeners();
      _guardarPronto();
      return;
    }
    escribiendo = true;
    notifyListeners();
    final burbuja = _pendientes.first;
    _temporizador = Timer(ritmo.para(burbuja.texto), () {
      if (_pendientes.isEmpty) return;
      _pendientes.removeFirst();
      _agregarBurbuja(burbuja);
      _siguiente();
    });
  }

  /// Si llega un mensaje mientras MacIAs todavia escribe, lo que faltaba se
  /// dice de una vez: la respuesta nueva no puede quedar antes que la vieja.
  void _decirTodoYa() {
    _temporizador?.cancel();
    while (_pendientes.isNotEmpty) {
      _agregarBurbuja(_pendientes.removeFirst());
    }
    escribiendo = false;
  }

  void _agregarBurbuja(BurbujaMacias burbuja) => _mensajes.add(
    MensajeMacias(
      id: _siguienteId++,
      autor: AutorMensaje.macias,
      texto: burbuja.texto,
      opciones: burbuja.opciones,
      acciones: burbuja.acciones,
    ),
  );

  void _agregar(AutorMensaje autor, String texto) {
    _mensajes.add(
      MensajeMacias(id: _siguienteId++, autor: autor, texto: texto),
    );
    notifyListeners();
  }

  /// Se guarda un momento despues de terminar de responder, no en cada
  /// burbuja: una respuesta de tres burbujas es una sola escritura.
  void _guardarPronto() {
    _guardado?.cancel();
    _guardado = Timer(const Duration(milliseconds: 300), guardar);
  }

  Future<void> guardar() => almacen.guardar(_mensajes, cerebro.memoria);

  @override
  void dispose() {
    _desechado = true;
    _temporizador?.cancel();
    if (_guardado?.isActive ?? false) {
      _guardado!.cancel();
      // Lo ultimo tambien se guarda aunque se salga justo despues.
      unawaited(guardar());
    }
    super.dispose();
  }
}
