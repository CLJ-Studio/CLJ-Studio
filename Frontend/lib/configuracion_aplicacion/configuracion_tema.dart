import 'package:flutter/material.dart';
// SystemUiOverlayStyle vive aqui, no en material.
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

/// Identidad visual de la aplicación, en claro y en oscuro.
///
/// El verde es el color de la marca (el búho) y manda en ambos temas. El
/// oscuro no es el claro con los colores invertidos: usa un gris azulado
/// cálido en vez de negro puro, que a pantalla completa cansa menos la
/// vista y deja respirar a las fotos de los productos.
abstract final class ConfiguracionTema {
  // Marca
  static const Color verde = Color(0xFF5C8A63);
  static const Color verdeClaro = Color(0xFF7FA987);
  static const Color naranja = Color(0xFFFC6011);

  // Tema claro
  static const Color texto = Color(0xFF4A4B4D);
  static const Color textoSecundario = Color(0xFF7C7D7E);
  static const Color grisClaro = Color(0xFFF2F2F2);
  static const Color fondo = Colors.white;

  // Tema oscuro
  static const Color fondoOscuro = Color(0xFF16181A);
  static const Color superficieOscura = Color(0xFF1F2225);
  static const Color superficieOscuraAlta = Color(0xFF272B2F);
  static const Color textoOscuro = Color(0xFFECEFEC);
  static const Color textoSecundarioOscuro = Color(0xFF9BA29D);

  static ThemeData get temaClaro => _construir(
    brillo: Brightness.light,
    fondoBase: fondo,
    superficie: Colors.white,
    superficieAlta: grisClaro,
    colorTexto: texto,
    colorTextoSecundario: textoSecundario,
    borde: const Color(0xFFEEEEEE),
    divisor: const Color(0xFFEDEDED),
    relleno: grisClaro,
  );

  static ThemeData get temaOscuro => _construir(
    brillo: Brightness.dark,
    fondoBase: fondoOscuro,
    superficie: superficieOscura,
    superficieAlta: superficieOscuraAlta,
    colorTexto: textoOscuro,
    colorTextoSecundario: textoSecundarioOscuro,
    borde: const Color(0xFF32373B),
    divisor: const Color(0xFF2C3134),
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
        seedColor: verde,
        brightness: brillo,
        primary: esOscuro ? verdeClaro : verde,
        secondary: naranja,
        surface: superficie,
        onPrimary: Colors.white,
        onSurface: colorTexto,
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
          borderRadius: BorderRadius.all(Radius.circular(28)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          borderSide: BorderSide(
            color: esOscuro ? verdeClaro : verde,
            width: 2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: superficie,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: borde),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: esOscuro ? verdeClaro : verde,
          foregroundColor: esOscuro ? const Color(0xFF11251A) : Colors.white,
          disabledBackgroundColor: esOscuro
              ? const Color(0xFF3A4043)
              : const Color(0xFFB6B7B7),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: superficieAlta,
        selectedColor: esOscuro
            ? const Color(0xFF2E4636)
            : const Color(0xFFE7F2E8),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          color: colorTexto,
          fontWeight: FontWeight.w600,
        ),
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
        backgroundColor: esOscuro ? superficieOscuraAlta : const Color(0xFF2E3330),
        contentTextStyle: const TextStyle(color: Colors.white),
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
        iconColor: esOscuro ? verdeClaro : verde,
        subtitleTextStyle: TextStyle(
          color: colorTextoSecundario,
          fontSize: 13,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (estados) => Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? (esOscuro ? verdeClaro : verde)
              : (esOscuro ? const Color(0xFF3A4043) : const Color(0xFFD2D5D2)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: esOscuro ? verdeClaro : verde,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: esOscuro ? verdeClaro : verde,
        foregroundColor: esOscuro ? const Color(0xFF11251A) : Colors.white,
        shape: const CircleBorder(),
      ),
      dividerColor: divisor,
      dividerTheme: DividerThemeData(color: divisor),
    );
  }
}
