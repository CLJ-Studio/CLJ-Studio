import 'package:flutter/material.dart';
// SystemUiOverlayStyle vive aqui, no en material.
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

/// Identidad visual terrosa y editorial de la aplicación.
///
/// La interfaz deriva de crema, gris cálido, salvia, salvia clara, grafito y
/// terracota. El azul noche identifica la cabecera, el amarillo dorado los
/// banners de búhos y el naranja coral la navegación seleccionada.
abstract final class ConfiguracionTema {
  // Paleta base
  static const Color crema = Color(0xFFE6E1D5);
  static const Color cremaSuperficie = Color(0xFFF5F4F0);
  static const Color grisCalido = Color(0xFF848381);
  static const Color salvia = Color(0xFF969A82);
  static const Color salviaClara = Color(0xFFBBBCA7);
  static const Color grafito = Color(0xFF474646);
  static const Color terracota = Color(0xFFAE7960);
  static const Color azulNoche = Color.fromARGB(255, 34, 39, 91);
  static const Color amarilloDorado = Color.fromARGB(255, 246, 182, 72);
  static const Color naranjaCoral = Color(0xFFFF724C);
  static const Color blancoSuave = Color(0xFFF4F4F8);
  static const Color moradoPromocional = Color(0xFF4A08A1);

  // Roles de marca
  static const Color primario = grafito;
  static const Color secundario = salvia;
  static const Color acento = terracota;

  // Tema claro
  static const Color texto = grafito;
  static const Color textoSecundario = grisCalido;
  static const Color superficieClara = cremaSuperficie;
  static const Color fondo = Color(0xFFFFFFFF);

  // Tema oscuro
  static const Color fondoOscuro = grafito;
  static const Color superficieOscura = grafito;
  static const Color superficieOscuraAlta = grisCalido;
  static const Color textoOscuro = crema;
  static const Color textoSecundarioOscuro = salviaClara;

  static ThemeData get temaClaro => _construir(
    brillo: Brightness.light,
    fondoBase: fondo,
    superficie: superficieClara,
    superficieAlta: cremaSuperficie,
    colorTexto: texto,
    colorTextoSecundario: textoSecundario,
    borde: grisCalido,
    divisor: salvia,
    relleno: cremaSuperficie,
  );

  static ThemeData get temaOscuro => _construir(
    brillo: Brightness.dark,
    fondoBase: fondoOscuro,
    superficie: superficieOscura,
    superficieAlta: superficieOscuraAlta,
    colorTexto: textoOscuro,
    colorTextoSecundario: textoSecundarioOscuro,
    borde: salvia,
    divisor: grisCalido,
    relleno: superficieOscuraAlta,
  );

  /// Una sola definicion para ambos temas: mantenerlos separados terminaba
  /// con estilos que solo se corregian en uno de los dos.
  static ThemeData _construir({
    required Brightness brillo,
    required Color fondoBase,
    required Color superficie,
    required Color superficieAlta,
    required Color colorTexto,
    required Color colorTextoSecundario,
    required Color borde,
    required Color divisor,
    required Color relleno,
  }) {
    final esOscuro = brillo == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brillo,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: fondoBase,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primario,
        brightness: brillo,
        primary: esOscuro ? salviaClara : primario,
        secondary: acento,
        tertiary: secundario,
        surface: superficie,
        onPrimary: esOscuro ? grafito : crema,
        onSecondary: grafito,
        onTertiary: grafito,
        onSurface: colorTexto,
        error: terracota,
        onError: grafito,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: colorTexto,
          fontWeight: FontWeight.w900,
        ),
        headlineMedium: TextStyle(
          color: colorTexto,
          fontWeight: FontWeight.w900,
        ),
        headlineSmall: TextStyle(
          color: colorTexto,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(color: colorTexto, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: colorTexto, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: colorTexto, height: 1.35),
        bodyMedium: TextStyle(color: colorTextoSecundario, height: 1.35),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: relleno,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: TextStyle(color: colorTextoSecundario),
        labelStyle: TextStyle(color: colorTextoSecundario),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(
            color: esOscuro ? salviaClara : primario,
            width: 2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: superficie,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: borde),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: esOscuro ? salviaClara : primario,
          foregroundColor: esOscuro ? grafito : crema,
          disabledBackgroundColor: grisCalido,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: superficieAlta,
        selectedColor: esOscuro ? salvia : salviaClara,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(color: colorTexto, fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: superficie,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: superficie,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: grafito,
        contentTextStyle: const TextStyle(color: crema),
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: fondoBase,
        foregroundColor: colorTexto,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        // Sin esto la barra de estado hereda el color del sistema y se veia
        // negra en unos telefonos y verde en otros. Los iconos se invierten
        // segun el tema para que siempre contrasten con el fondo.
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: esOscuro
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: esOscuro ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: fondoBase,
          systemNavigationBarIconBrightness: esOscuro
              ? Brightness.light
              : Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: colorTexto,
          fontFamily: 'Nunito',
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: colorTexto,
        iconColor: esOscuro ? salviaClara : acento,
        subtitleTextStyle: TextStyle(color: colorTextoSecundario, fontSize: 13),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((estados) => crema),
        trackColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? (esOscuro ? salviaClara : secundario)
              : grisCalido,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: esOscuro ? salviaClara : primario,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: esOscuro ? salviaClara : primario,
        foregroundColor: esOscuro ? grafito : crema,
        shape: const CircleBorder(),
      ),
      dividerColor: divisor,
      dividerTheme: DividerThemeData(color: divisor),
    );
  }
}
