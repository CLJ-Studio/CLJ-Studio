import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/diseno/campus_collapsing_header.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/diseno/imagen_publicidad.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/publicidad.dart';

Widget _encabezado({VoidCallback? alAbrirPerfil}) => MaterialApp(
  home: Scaffold(
    body: CampusFixedHeader(
      nombre: 'Juan',
      categorias: const [],
      categoriaId: 'todas',
      alBuscar: (_) {},
      alSeleccionarCategoria: (_) {},
      alAbrirCarrito: () {},
      alAbrirPedidos: () {},
      mostrarCategorias: false,
      alAbrirPerfil: alAbrirPerfil,
    ),
  ),
);

const _aviso = Publicidad(
  id: 'a1',
  titulo: 'Feria de empleo',
  rutaImagen: 'https://ejemplo.supabase.co/storage/v1/object/public/a/1.png',
  ubicacion: UbicacionPublicidad.bannerPrincipal,
  orden: 0,
  activa: true,
);

void main() {
  group('el avatar del encabezado', () {
    testWidgets('lleva al perfil', (tester) async {
      var veces = 0;
      await tester.pumpWidget(_encabezado(alAbrirPerfil: () => veces++));

      await tester.tap(find.bySemanticsLabel('Tu perfil'));
      await tester.pumpAndSettle();

      expect(veces, 1);
    });

    testWidgets('sin a donde ir es solo la foto, no un boton', (tester) async {
      await tester.pumpWidget(_encabezado());

      expect(find.bySemanticsLabel('Tu perfil'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Foto de perfil')), findsOneWidget);
      expect(
        find.descendant(
          of: find.bySemanticsLabel(RegExp('Foto de perfil')),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    testWidgets('sin foto muestra la inicial', (tester) async {
      await tester.pumpWidget(_encabezado(alAbrirPerfil: () {}));
      expect(find.text('J'), findsOneWidget);
    });
  });

  group('la imagen de un aviso', () {
    Future<ImageProvider> pedir(
      WidgetTester tester, {
      double anchoVisible = 400,
      double escala = 2.625,
    }) async {
      late ImageProvider proveedor;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(devicePixelRatio: escala),
          child: Builder(
            builder: (context) {
              proveedor = proveedorImagenPublicidad(
                context,
                _aviso,
                anchoVisible: anchoVisible,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      return proveedor;
    }

    testWidgets('la precarga y el dibujo piden exactamente lo mismo', (
      tester,
    ) async {
      final primera = await pedir(tester);
      final segunda = await pedir(tester);
      expect(primera, segunda);
      expect(primera.hashCode, segunda.hashCode);
    });

    testWidgets('se decodifica al ancho con el que se ve', (tester) async {
      // 400 puntos a 2.625 son 1050 pixeles: se pide 1100, en saltos de 100
      // para que un rebote de un pixel no cree otra copia en memoria.
      final proveedor = await pedir(tester) as ResizeImage;
      expect(proveedor.width, 1100);
      expect(proveedor.allowUpscaling, isFalse);
    });

    testWidgets('en el telefono pasa por la cache en disco', (tester) async {
      final proveedor = await pedir(tester) as ResizeImage;
      expect(proveedor.imageProvider, isA<CachedNetworkImageProvider>());
    });
  });
}
