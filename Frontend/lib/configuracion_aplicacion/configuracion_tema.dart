import 'package:flutter/material.dart';
// SystemUiOverlayStyle vive aqui, no en material.
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

/// Identidad visual inspirada en la referencia de comida.
abstract final class ConfiguracionTema {
  static const Color naranja = Color(0xFFFC6011);
  static const Color texto = Color(0xFF4A4B4D);
  static const Color textoSecundario = Color(0xFF7C7D7E);
  static const Color grisClaro = Color(0xFFF2F2F2);
  static const Color fondo = Colors.white;

  static ThemeData get temaClaro => ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: fondo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: naranja,
      primary: naranja,
      secondary: texto,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: texto,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: texto, fontWeight: FontWeight.w900),
      headlineMedium: TextStyle(color: texto, fontWeight: FontWeight.w900),
      headlineSmall: TextStyle(color: texto, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: texto, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: texto, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: texto, height: 1.35),
      bodyMedium: TextStyle(color: textoSecundario, height: 1.35),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: grisClaro,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
        borderSide: BorderSide(color: naranja, width: 2),
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: Color(0xFFEEEEEE)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: naranja,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFB6B7B7),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: grisClaro,
      selectedColor: Color(0xFFFFE2D4),
      side: BorderSide.none,
      shape: StadiumBorder(),
      labelStyle: TextStyle(color: texto, fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: texto,
      elevation: 0,
      centerTitle: true,
      // Sin esto, la barra de estado hereda el color del sistema y se veia
      // negra en unos telefonos y verde en otros. Se fija clara con iconos
      // oscuros, que es lo que pide un fondo blanco.
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: texto,
        fontFamily: 'Nunito',
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFFFE2D4),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          color: textoSecundario,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: textoSecundario)),
      height: 76,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: naranja,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    dividerColor: const Color(0xFFEDEDED),
  );
}
