import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/logica/info_dispositivo.dart';
import 'package:flutter_application/provider/dispositivo_provider.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/services/dispositivos_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'baseDeDatos/conexion.dart';
import 'pantallas/pantalla_principal.dart';
import 'pantallas/pantalla_onboarding.dart';

// ─── Modo de tema global ──────────────────────────────────────
final ValueNotifier<ThemeMode> modoTema = ValueNotifier(ThemeMode.light);

Future<void> _cargarModoTema() async {
  final prefs = await SharedPreferences.getInstance();
  final oscuro = prefs.getBool('modo_oscuro') ?? false;
  modoTema.value = oscuro ? ThemeMode.dark : ThemeMode.light;
}

Future<void> guardarModoTema(ThemeMode modo) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('modo_oscuro', modo == ThemeMode.dark);
}

void _aplicarEstiloSistema(ThemeMode modo) {
  final esDark = modo == ThemeMode.dark;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: esDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: esDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          esDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
}
// ─────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConexion.init();

  AuthService.init();

  final DispositivoService servicioDispositivo =
      DispositivoService(SupabaseConexion.client);
  final InfoDispositivo dispositivo =
      await servicioDispositivo.obtenerORegistrar();

  final prefs = await SharedPreferences.getInstance();
  final yaVioOnboarding = prefs.getBool('ya_vio_onboarding') ?? false;

  await _cargarModoTema();

  // Modo edge-to-edge: el contenido Flutter se dibuja detrás de
  // la barra de estado y la barra de navegación del sistema.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Aplicar estilo inicial y reaccionar a cambios de tema
  _aplicarEstiloSistema(modoTema.value);
  modoTema.addListener(() => _aplicarEstiloSistema(modoTema.value));

  runApp(MiApp(
    dispositivo: dispositivo,
    mostrarOnboarding: !yaVioOnboarding,
  ));
}

class MiApp extends StatelessWidget {
  const MiApp({
    super.key,
    required this.dispositivo,
    required this.mostrarOnboarding,
  });
  final InfoDispositivo dispositivo;
  final bool mostrarOnboarding;

  @override
  Widget build(BuildContext context) {
    return ProveedorDispositivo(
      dispositivo: dispositivo,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: modoTema,
        builder: (_, modo, __) => MaterialApp(
          title: 'DICCING',
          debugShowCheckedModeBanner: false,
          themeMode: modo,
          theme: _temaClaro(),
          darkTheme: _temaOscuro(),
          home: mostrarOnboarding
              ? const PantallaOnboarding()
              : PantallaPrincipal(),
        ),
      ),
    );
  }
}

ThemeData _temaClaro() {
  const Color primario = Color(0xFF1F2937);
  const Color acento = Color(0xFF374151);
  const Color fondo = Color(0xFFF8F9FA);
  const Color superficie = Colors.white;
  const Color textoOscuro = Color(0xFF111827);
  const Color textoMedio = Color(0xFF6B7280);
  const Color borde = Color(0xFFE5E7EB);

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primario,
      secondary: acento,
      surface: superficie,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textoOscuro,
      surfaceContainerHighest: borde,
      outline: borde,
    ),
    scaffoldBackgroundColor: fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textoOscuro,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 17,
        color: textoOscuro,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: borde, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: superficie,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primario, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textoMedio),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primario,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: const BorderSide(color: borde),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      indicatorColor: primario.withValues(alpha: 0.08),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final activo = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
          color: activo ? primario : textoMedio,
          fontFamily: 'Inter',
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final activo = states.contains(WidgetState.selected);
        return IconThemeData(color: activo ? primario : textoMedio);
      }),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textoOscuro, fontSize: 16),
      bodyMedium: TextStyle(color: textoOscuro, fontSize: 14),
      bodySmall: TextStyle(color: textoMedio, fontSize: 12),
    ),
    dividerColor: borde,
  );
}

ThemeData _temaOscuro() {
  const Color primario = Color(0xFF818CF8); // índigo claro (acento mantenido)
  const Color fondo = Color(0xFF0F0F0F);   // youtube bg
  const Color superficie = Color(0xFF212121); // youtube surface
  const Color borde = Color(0xFF3D3D3D);   // youtube border
  const Color textoOscuro = Color(0xFFF1F1F1); // youtube text primary
  const Color textoMedio = Color(0xFFAAAAAA);  // youtube text secondary

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primario,
      secondary: Color(0xFF6B7280),
      surface: superficie,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textoOscuro,
      surfaceContainerHighest: borde,
      outline: borde,
    ),
    scaffoldBackgroundColor: fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: superficie,
      foregroundColor: textoOscuro,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 17,
        color: textoOscuro,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: borde, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: superficie,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primario, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textoMedio),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primario,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: const BorderSide(color: borde),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: superficie,
      surfaceTintColor: superficie,
      indicatorColor: primario.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final activo = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
          color: activo ? primario : textoMedio,
          fontFamily: 'Inter',
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final activo = states.contains(WidgetState.selected);
        return IconThemeData(color: activo ? primario : textoMedio);
      }),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textoOscuro, fontSize: 16),
      bodyMedium: TextStyle(color: textoOscuro, fontSize: 14),
      bodySmall: TextStyle(color: textoMedio, fontSize: 12),
    ),
    dividerColor: borde,
  );
}
