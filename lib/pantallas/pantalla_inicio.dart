import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../logica/glosario.dart';
import '../logica/notificadores.dart';
import '../logica/termino.dart';
import '../main.dart' show modoTema, guardarModoTema;
import '../provider/dispositivo_provider.dart';
import '../services/auth_service.dart';
import 'pantalla_admin.dart';
import 'pantalla_onboarding.dart';
import 'pantalla_principal.dart';
import 'pantalla_resultado.dart';
import 'pantalla_sugerir.dart';
import 'widgets/chip_categoria.dart';
import 'widgets/indicador_carga_skeleton.dart';
import 'widgets/widget_error_red.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  Termino? _terminoDelDia;
  List<Termino> _masConsultados = const [];
  int _totalVistos = 0;
  int _totalFavoritos = 0;
  bool _cargando = true;
  bool _datosListos = false;
  String? _mensajeError;
  bool _iniciandoSesion = false;

  @override
  void initState() {
    super.initState();
    FavoritosNotificador.notificador.addListener(_alCambiarDatos);
    HistorialNotificador.notificador.addListener(_alCambiarDatos);
  }

  @override
  void dispose() {
    FavoritosNotificador.notificador.removeListener(_alCambiarDatos);
    HistorialNotificador.notificador.removeListener(_alCambiarDatos);
    super.dispose();
  }

  void _alCambiarDatos() {
    if (mounted) _cargarDatos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_datosListos) {
      _datosListos = true;
      _cargarDatos();
    }
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });
    final dispositivo = ProveedorDispositivo.of(context);

    try {
      final resultados = await Future.wait([
        Glosario.obtenerTerminoDelDia(),
        Glosario.obtenerMasConsultados(limite: 5),
        Glosario.contarHistorial(dispositivo.id),
        Glosario.contarFavoritos(dispositivo.id),
      ]);

      if (!mounted) return;
      setState(() {
        _terminoDelDia = resultados[0] as Termino?;
        _masConsultados = resultados[1] as List<Termino>;
        _totalVistos = resultados[2] as int;
        _totalFavoritos = resultados[3] as int;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError = 'No se pudo cargar la información principal.';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirTermino(Termino t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaResultado(nombreTermino: t.nombreTermino),
      ),
    );
    _cargarDatos();
  }

  Future<void> _iniciarSesionGoogle() async {
    setState(() => _iniciandoSesion = true);
    try {
      await AuthService.iniciarSesionConGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo iniciar sesión. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _iniciandoSesion = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await AuthService.cerrarSesion();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada')),
    );
  }

  void _toggleTema() {
    final nuevo = modoTema.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    modoTema.value = nuevo;
    guardarModoTema(nuevo);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = isDark ? const Color(0xFF212121) : Colors.white;
    final colorBorde = isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB);
    final colorTexto = cs.onSurface;
    final colorTextoSec = isDark ? const Color(0xFFAAAAAA) : Colors.grey.shade600;

    return Scaffold(
      body: SafeArea(
        child: _mensajeError != null
            ? WidgetErrorRed(
                mensaje: _mensajeError!,
                onReintentar: _cargarDatos,
              )
            : RefreshIndicator(
                onRefresh: _cargarDatos,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    // Encabezado con toggle de tema
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DICCING',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: colorTexto,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Mostrar tutorial',
                          icon: Icon(Icons.help_outline_rounded, color: colorTextoSec, size: 22),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PantallaOnboarding()),
                            );
                          },
                        ),
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: modoTema,
                          builder: (_, modo, __) => IconButton(
                            tooltip: modo == ThemeMode.dark
                                ? 'Cambiar a modo claro'
                                : 'Cambiar a modo oscuro',
                            icon: Icon(
                              modo == ThemeMode.dark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              color: colorTextoSec,
                              size: 22,
                            ),
                            onPressed: _toggleTema,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sección usuario / Google Sign-In
                    ValueListenableBuilder<User?>(
                      valueListenable: AuthService.usuario,
                      builder: (_, user, __) {
                        if (user != null) {
                          return _tarjetaUsuario(
                            user,
                            colorFondo,
                            colorBorde,
                            colorTexto,
                            colorTextoSec,
                          );
                        }
                        return _botonGoogleSignIn(
                          colorFondo,
                          colorBorde,
                          colorTextoSec,
                        );
                      },
                    ),
                    const SizedBox(height: 20),



                    // Estadísticas
                    Row(
                      children: [
                        Expanded(
                          child: _BotonAnimadoBounce(
                            onDoubleTap: () => PantallaPrincipal.irATab(3),
                            child: _tarjetaStat(
                              icono: Icons.visibility_outlined,
                              valor: _totalVistos.toString(),
                              label: 'Vistos',
                              colorFondo: colorFondo,
                              colorBorde: colorBorde,
                              colorTexto: colorTexto,
                              colorTextoSec: colorTextoSec,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BotonAnimadoBounce(
                            onDoubleTap: () => PantallaPrincipal.irATab(2),
                            child: _tarjetaStat(
                              icono: Icons.bookmark_outline,
                              valor: _totalFavoritos.toString(),
                              label: 'Guardados',
                              colorFondo: colorFondo,
                              colorBorde: colorBorde,
                              colorTexto: colorTexto,
                              colorTextoSec: colorTextoSec,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Término del día
                    _seccionTitulo('Término del día', colorTexto),
                    const SizedBox(height: 10),
                    _cargando
                        ? const ListaSkeleton(itemCount: 1, height: 170)
                        : (_terminoDelDia == null
                            ? _emptyCard(
                                'No se pudo cargar el término del día',
                                colorFondo, colorBorde, colorTextoSec)
                            : _WidgetBrilloAnimado(
                                isDark: isDark,
                                child: _cardTerminoDelDia(
                                  _terminoDelDia!,
                                  colorFondo,
                                  colorBorde,
                                  colorTexto,
                                  colorTextoSec,
                                ),
                              )),
                    const SizedBox(height: 28),

                    // Más consultados
                    _seccionTitulo('Términos más consultados', colorTexto),
                    const SizedBox(height: 10),
                    _cargando
                        ? const ListaSkeleton(itemCount: 5, height: 50)
                        : (_masConsultados.isEmpty
                            ? _emptyCard(
                                'Aún no hay términos consultados',
                                colorFondo, colorBorde, colorTextoSec)
                            : _listaMasConsultados(
                                colorFondo, colorBorde, colorTexto, colorTextoSec)),
                    const SizedBox(height: 24),

                    // Sugerir
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PantallaSugerir()),
                          );
                        },
                        icon: const Icon(CupertinoIcons.lightbulb, size: 18),
                        label: const Text('Sugerir término'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _tarjetaUsuario(
    dynamic user,
    Color colorFondo,
    Color colorBorde,
    Color colorTexto,
    Color colorTextoSec,
  ) {
    final nombre = AuthService.nombreUsuario ?? 'Usuario';
    final email = AuthService.emailUsuario ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorBorde),
      ),
      child: Row(
        children: [
          if (AuthService.esAdmin)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaAdmin()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.admin_panel_settings_outlined,
                        color: Color(0xFF6366F1), size: 14),
                    SizedBox(width: 5),
                    Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colorTexto,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: colorTextoSec),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _cerrarSesion,
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text(
              'Salir',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonGoogleSignIn(
    Color colorFondo,
    Color colorBorde,
    Color colorTextoSec,
  ) {
    return OutlinedButton(
      onPressed: _iniciandoSesion ? null : _iniciarSesionGoogle,
      style: OutlinedButton.styleFrom(
        backgroundColor: colorFondo,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: colorBorde),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: _iniciandoSesion
          ? SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorTextoSec,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle_outlined,
                    size: 18, color: colorTextoSec),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Iniciar sesión con Google',
                    style: TextStyle(
                      color: colorTextoSec,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _seccionTitulo(String texto, Color color) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _tarjetaStat({
    required IconData icono,
    required String valor,
    required String label,
    required Color colorFondo,
    required Color colorBorde,
    required Color colorTexto,
    required Color colorTextoSec,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: colorTextoSec, size: 20),
          const SizedBox(height: 10),
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorTexto,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: colorTextoSec)),
        ],
      ),
    );
  }

  Widget _cardTerminoDelDia(
    Termino t,
    Color colorFondo,
    Color colorBorde,
    Color colorTexto,
    Color colorTextoSec,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorFondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorBorde),
      ),
      child: InkWell(
        onTap: () => _abrirTermino(t),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (t.categoria != null) ...[
                ChipCategoria(categoria: t.categoria!),
                const SizedBox(height: 12),
              ],
              Text(
                t.nombreTermino,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorTexto,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.definicion,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorTextoSec,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Leer más',
                    style: TextStyle(
                      color: colorTexto,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: colorTexto, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listaMasConsultados(
    Color colorFondo,
    Color colorBorde,
    Color colorTexto,
    Color colorTextoSec,
  ) {
    final separador =
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF212121)
            : const Color(0xFFF3F4F6);
    return Container(
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorBorde),
      ),
      child: Column(
        children: List.generate(_masConsultados.length, (i) {
          final t = _masConsultados[i];
          final esUltimo = i == _masConsultados.length - 1;
          return InkWell(
            onTap: () => _abrirTermino(t),
            borderRadius: BorderRadius.vertical(
              top: i == 0 ? const Radius.circular(24) : Radius.zero,
              bottom: esUltimo ? const Radius.circular(24) : Radius.zero,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: esUltimo
                      ? BorderSide.none
                      : BorderSide(color: separador),
                ),
              ),
              child: Row(
                children: [
                  Builder(builder: (ctx) {
                    final isDark = Theme.of(ctx).brightness == Brightness.dark;
                    if (i == 0) {
                      return Container(
                        alignment: Alignment.center,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF854D0E) : const Color(0xFFFEF3C7), shape: BoxShape.circle), // mustard dark / amber-100
                        child: Text('1', style: TextStyle(color: isDark ? const Color(0xFFFEF08A) : const Color(0xFF92400E), fontWeight: FontWeight.w800, fontSize: 12)), // light yellow / amber-900
                      );
                    } else if (i == 1) {
                      return Container(
                        alignment: Alignment.center,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF1F1F1), shape: BoxShape.circle), // slate-700 / slate-100
                        child: Text('2', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF717171), fontWeight: FontWeight.w800, fontSize: 12)), // slate-200 / slate-700
                      );
                    } else if (i == 2) {
                      return Container(
                        alignment: Alignment.center,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5), shape: BoxShape.circle), // orange-900 / orange-100
                        child: Text('3', style: TextStyle(color: isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412), fontWeight: FontWeight.w800, fontSize: 12)), // orange-300 / orange-900
                      );
                    }
                    return Container(
                      alignment: Alignment.center,
                      width: 24,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorTextoSec,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.nombreTermino,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorTexto,
                      ),
                    ),
                  ),
                  Text(
                    '${t.vistas}',
                    style: TextStyle(fontSize: 12, color: colorTextoSec),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.visibility_outlined,
                      size: 14, color: colorTextoSec),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _emptyCard(
    String mensaje,
    Color colorFondo,
    Color colorBorde,
    Color colorTextoSec,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorBorde),
      ),
      child: Center(
        child: Text(
          mensaje,
          style: TextStyle(color: colorTextoSec, fontSize: 13),
        ),
      ),
    );
  }
}

class _BotonAnimadoBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDoubleTap;
  const _BotonAnimadoBounce({required this.child, this.onDoubleTap});

  @override
  State<_BotonAnimadoBounce> createState() => _BotonAnimadoBounceState();
}

class _BotonAnimadoBounceState extends State<_BotonAnimadoBounce> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _presionado = true),
      onTapUp: (_) => setState(() => _presionado = false),
      onTapCancel: () => setState(() => _presionado = false),
      onDoubleTap: widget.onDoubleTap,
      child: AnimatedScale(
        scale: _presionado ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _WidgetBrilloAnimado extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const _WidgetBrilloAnimado({required this.child, required this.isDark});

  @override
  State<_WidgetBrilloAnimado> createState() => _WidgetBrilloAnimadoState();
}

class _WidgetBrilloAnimadoState extends State<_WidgetBrilloAnimado>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shadowColor = widget.isDark
            ? const Color(0xFF6366F1).withAlpha((255 * (0.35 * _animation.value)).round())
            : const Color(0xFF6366F1).withAlpha((255 * (0.25 * _animation.value)).round());
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 20 * _animation.value,
                spreadRadius: 2 * _animation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

