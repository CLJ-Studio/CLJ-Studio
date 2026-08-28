import 'package:flutter/material.dart';
// SystemUiOverlayStyle vive aqui, no en material.
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

/// Identidad visual de la aplicación, en claro y en oscuro.
///
/// La interfaz del marketplace usa una marca vibrante y superficies limpias.
/// El verde se conserva como color auxiliar del búho y de estados positivos.
abstract final class ConfiguracionTema {
  // Marca
  static const Color verde = Color(0xFF168A58);
  static const Color verdeClaro = Color(0xFF66C493);
  static const Color verdeMarca = Color(0xFF138A5B);
  static const Color verdeMarcaOscuro = Color(0xFF0C6843);
  static const Color azulPetroleo = Color(0xFF164A56);
  static const Color tinta = Color(0xFF17231D);

  // Tema claro
  static const Color texto = tinta;
  static const Color textoSecundario = Color(0xFF6D7872);
  static const Color grisClaro = Color(0xFFF1F5F2);
  static const Color fondo = Color(0xFFF9FCFA);

  // Tema oscuro
  static const Color fondoOscuro = Colors.black;
  static const Color superficieOscura = Color(0xFF050805);
  static const Color superficieOscuraAlta = Color(0xFF0B120D);
  static const Color textoOscuro = Colors.white;
  static const Color textoSecundarioOscuro = Color(0xFFC8D0C9);

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
    borde: const Color(0xFF18301E),
    divisor: const Color(0xFF142719),
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
        seedColor: verdeMarca,
        brightness: brillo,
        primary: esOscuro ? const Color(0xFF65D29A) : verdeMarca,
        secondary: esOscuro ? const Color(0xFF72BAC3) : azulPetroleo,
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
            color: esOscuro ? const Color(0xFF65D29A) : verdeMarca,
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
          backgroundColor: esOscuro ? const Color(0xFF65D29A) : verdeMarca,
          foregroundColor: esOscuro ? const Color(0xFF11251A) : Colors.white,
          disabledBackgroundColor: esOscuro
              ? const Color(0xFF142719)
              : const Color(0xFFB6B7B7),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: superficieAlta,
        selectedColor: esOscuro
            ? const Color(0xFF174232)
            : const Color(0xFFE3F3EA),
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
        backgroundColor: esOscuro
            ? superficieOscuraAlta
            : const Color(0xFF2E3330),
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
        subtitleTextStyle: TextStyle(color: colorTextoSecundario, fontSize: 13),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((estados) => Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? (esOscuro ? verdeClaro : verde)
              : (esOscuro ? const Color(0xFF142719) : const Color(0xFFD2D5D2)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: esOscuro ? const Color(0xFF65D29A) : verdeMarca,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: esOscuro ? const Color(0xFF65D29A) : verdeMarca,
        foregroundColor: esOscuro ? const Color(0xFF11251A) : Colors.white,
        shape: const CircleBorder(),
      ),
      dividerColor: divisor,
      dividerTheme: DividerThemeData(color: divisor),
    );
  }
}
