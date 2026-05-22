import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../logica/diccionario_personal.dart';
import '../logica/termino_personal.dart';
import '../services/auth_service.dart';
import 'pantalla_crear_termino.dart';
import 'pantalla_detalle_personal.dart';
import 'widgets/indicador_carga_skeleton.dart';
import 'widgets/widget_error_red.dart';
import '../widgets/animacion_eliminar.dart';

class PantallaDiccionarioPersonal extends StatefulWidget {
  const PantallaDiccionarioPersonal({super.key});

  @override
  State<PantallaDiccionarioPersonal> createState() =>
      _PantallaDiccionarioPersonalState();
}

class _PantallaDiccionarioPersonalState
    extends State<PantallaDiccionarioPersonal> {
  List<TerminoPersonal> _terminos = [];
  final Set<int> _eliminandoIds = {};
  bool _cargando = false;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    // Recargar cuando cambie el estado de auth
    AuthService.usuario.addListener(_alCambiarAuth);
    if (AuthService.estaAutenticado) _cargarTerminos();
  }

  @override
  void dispose() {
    AuthService.usuario.removeListener(_alCambiarAuth);
    super.dispose();
  }

  void _alCambiarAuth() {
    if (!mounted) return;
    if (AuthService.estaAutenticado) {
      _cargarTerminos();
    } else {
      setState(() {
        _terminos = [];
        _mensajeError = null;
      });
    }
  }

  Future<void> _cargarTerminos() async {
    final userId = AuthService.usuario.value?.id;
    if (userId == null) return;

    setState(() {
      if (_terminos.isEmpty) _cargando = true;
      _mensajeError = null;
    });

    try {
      final lista = await DiccionarioPersonal.obtenerMios(userId);
      if (!mounted) return;
      setState(() {
        _terminos = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError = 'No se pudieron cargar tus términos.';
        _cargando = false;
      });
    }
  }

  void _iniciarEliminacion(TerminoPersonal t) {
    if (t.id == null) return;
    setState(() {
      _eliminandoIds.add(t.id!);
    });
  }

  Future<void> _completarEliminacion(TerminoPersonal t) async {
    if (t.id == null) return;
    setState(() {
      _terminos = _terminos.where((i) => i.id != t.id).toList();
      _eliminandoIds.remove(t.id!);
    });
    final ok = await DiccionarioPersonal.eliminar(t.id!);
    if (!mounted) return;
    if (!ok) _cargarTerminos();
  }

  Future<void> _abrirCrear() async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PantallaCrearTermino()),
    );
    if (creado == true) _cargarTerminos();
  }

  Future<void> _abrirDetalle(TerminoPersonal t) async {
    final modificado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaDetallePersonal(termino: t)),
    );
    if (modificado == true) _cargarTerminos();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTexto =
        isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827);
    final colorTextoSec =
        isDark ? const Color(0xFFAAAAAA) : Colors.grey.shade600;

    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<User?>(
          valueListenable: AuthService.usuario,
          builder: (_, user, __) {
            if (user == null) {
              return _buildNoAutenticado(colorTexto, colorTextoSec);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mi Diccionario',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: colorTexto,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _abrirCrear,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Añadir'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildContenido(colorTexto, colorTextoSec)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoAutenticado(Color colorTexto, Color colorTextoSec) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.lock_circle,
                size: 56, color: colorTextoSec),
            const SizedBox(height: 16),
            Text(
              'Inicia sesión para acceder\na tu diccionario personal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colorTextoSec,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ve a Inicio y toca "Iniciar sesión con Google".',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorTextoSec,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido(Color colorTexto, Color colorTextoSec) {
    if (_cargando) {
      return const ListaSkeleton(itemCount: 4, height: 80);
    }
    if (_mensajeError != null) {
      return WidgetErrorRed(
        mensaje: _mensajeError!,
        onReintentar: _cargarTerminos,
      );
    }
    if (_terminos.isEmpty) {
      return _buildVacio(colorTextoSec);
    }
    return RefreshIndicator(
      onRefresh: _cargarTerminos,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        itemCount: _terminos.length,
        itemBuilder: (_, i) {
          final t = _terminos[i];
          return AnimacionEliminar(
            key: ValueKey(t.id),
            isDeleted: t.id != null && _eliminandoIds.contains(t.id),
            onAnimationCompleted: () => _completarEliminacion(t),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _cardTerminoPersonal(t),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVacio(Color colorTextoSec) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.book_circle,
              size: 48, color: colorTextoSec),
          const SizedBox(height: 12),
          Text(
            'Tu diccionario está vacío',
            style: TextStyle(fontSize: 14, color: colorTextoSec),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _abrirCrear,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Agregar mi primer término'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTerminoPersonal(TerminoPersonal t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard =
        isDark ? const Color(0xFF1E2A3A) : const Color(0xFFEEF2FF);
    final borderCard =
        isDark ? const Color(0xFF3730A3) : const Color(0xFFC7D2FE);
    final colorNombre =
        isDark ? const Color(0xFFC7D2FE) : const Color(0xFF312E81);
    final colorDef = isDark
        ? const Color(0xFF818CF8).withValues(alpha: 0.8)
        : const Color(0xFF4338CA).withValues(alpha: 0.8);
    final colorChevron = isDark
        ? const Color(0xFF6366F1).withValues(alpha: 0.5)
        : const Color(0xFF6366F1).withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCard, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _abrirDetalle(t),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorNombre,
                        ),
                      ),
                      if (t.categoria != null && t.categoria!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          t.categoria!,
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF6366F1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        t.definicion,
                        style: TextStyle(fontSize: 13, color: colorDef),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _iniciarEliminacion(t),
                  icon: Icon(Icons.close, color: colorChevron, size: 22),
                  tooltip: 'Quitar',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
