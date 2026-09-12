import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/publicidad.dart';

/// Una fila como la devuelve `advertisements`, con lo mínimo para construir
/// un aviso. Las pruebas cambian solo el campo que están mirando.
Map<String, dynamic> fila({
  String? placement = 'main_banner',
  String? imagePath = 'empresa-x/banner.jpg',
  String? linkUrl,
  String? updatedAt,
}) => {
  'id': 'aviso-1',
  'title': 'Campaña X',
  'image_path': imagePath,
  'placement': placement,
  'link_url': linkUrl,
  'updated_at': updatedAt,
};

void main() {
  test('lee una fila completa', () {
    final aviso = Publicidad.desdeMapa(
      fila(linkUrl: 'https://ejemplo.com', updatedAt: '2026-09-12T10:00:00Z'),
    );

    expect(aviso, isNotNull);
    expect(aviso!.titulo, 'Campaña X');
    expect(aviso.ubicacion, UbicacionPublicidad.bannerPrincipal);
    expect(aviso.tieneEnlace, isTrue);
  });

  test('distingue las dos ubicaciones por su literal de Postgres', () {
    expect(
      Publicidad.desdeMapa(fila(placement: 'company_carousel'))?.ubicacion,
      UbicacionPublicidad.carruselEmpresas,
    );
    expect(
      UbicacionPublicidad.bannerPrincipal.valor,
      'main_banner',
    );
    expect(
      UbicacionPublicidad.carruselEmpresas.valor,
      'company_carousel',
    );
  });

  test('ignora una ubicación que esta versión no conoce', () {
    // Si mañana se agrega un espacio nuevo en la base, las apps viejas deben
    // saltárselo, no romper el inicio entero.
    expect(Publicidad.desdeMapa(fila(placement: 'pantalla_nueva')), isNull);
    expect(Publicidad.desdeMapa(fila(placement: null)), isNull);
  });

  test('descarta un aviso sin imagen', () {
    expect(Publicidad.desdeMapa(fila(imagePath: '')), isNull);
    expect(Publicidad.desdeMapa(fila(imagePath: '   ')), isNull);
    expect(Publicidad.desdeMapa(fila(imagePath: null)), isNull);
  });

  test('sin enlace no es navegable', () {
    expect(Publicidad.desdeMapa(fila())?.tieneEnlace, isFalse);
    expect(Publicidad.desdeMapa(fila(linkUrl: ''))?.tieneEnlace, isFalse);
  });

  test('una URL completa se usa tal cual, sin pasar por Storage', () {
    // Es el caso del modo local de desarrollo: sin este atajo habría que
    // tener Supabase inicializado solo para pintar un banner de prueba.
    final aviso = Publicidad.desdeMapa(
      fila(imagePath: 'https://cdn.ejemplo.com/banner.jpg'),
    );

    expect(aviso!.urlImagen, 'https://cdn.ejemplo.com/banner.jpg');
  });

  test('las proporciones son las que esperan los anunciantes', () {
    // 1680x1000 y 1620x624, las medidas que se les pide preparar.
    expect(UbicacionPublicidad.bannerPrincipal.proporcion, closeTo(1.68, 0.001));
    expect(
      UbicacionPublicidad.carruselEmpresas.proporcion,
      closeTo(2.596, 0.001),
    );
  });
}
