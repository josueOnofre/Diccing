import 'dart:ui';
import 'package:flutter/material.dart';
import '../logica/glosario.dart';
import '../logica/notificadores.dart';
import '../logica/termino.dart';
import '../provider/dispositivo_provider.dart';
import 'pantalla_resultado.dart';
import 'widgets/chip_categoria.dart';
import 'widgets/indicador_carga_skeleton.dart';
import 'widgets/widget_error_red.dart';
import '../widgets/animacion_eliminar.dart';

class PantallaFavoritos extends StatefulWidget {
  const PantallaFavoritos({super.key});

  @override
  State<PantallaFavoritos> createState() => _PantallaFavoritosState();
}

class _PantallaFavoritosState extends State<PantallaFavoritos> {
  List<Termino> _favoritos = const [];
  final Set<int> _eliminandoIds = {};
  bool _cargando = true;
  bool _datosListos = false;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    FavoritosNotificador.notificador.addListener(_alCambiarFavoritos);
  }

  @override
  void dispose() {
    FavoritosNotificador.notificador.removeListener(_alCambiarFavoritos);
    super.dispose();
  }

  void _alCambiarFavoritos() {
    if (mounted) _cargar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_datosListos) {
      _datosListos = true;
      _cargar();
    }
  }

  Future<void> _cargar() async {
    setState(() {
      if (_favoritos.isEmpty) _cargando = true;
      _mensajeError = null;
    });
    try {
      final dispositivo = ProveedorDispositivo.of(context);
      final favs = await Glosario.obtenerFavoritos(dispositivo.id);
      if (!mounted) return;
      setState(() {
        _favoritos = favs;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError = 'No se pudieron cargar tus favoritos.';
        _cargando = false;
      });
    }
  }

  void _iniciarEliminacion(Termino t) {
    setState(() {
      _eliminandoIds.add(t.idTermino);
    });
  }

  Future<void> _completarEliminacion(Termino t) async {
    final dispositivo = ProveedorDispositivo.of(context);
    setState(() {
      _favoritos =
          _favoritos.where((f) => f.idTermino != t.idTermino).toList();
      _eliminandoIds.remove(t.idTermino);
    });
    final ok = await Glosario.eliminarFavorito(t.idTermino, dispositivo.id);
    FavoritosNotificador.notificar();
    if (!mounted) return;
    if (!ok) _cargar();
  }

  Future<void> _eliminarTodos() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF212121).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
          'Eliminar todos los favoritos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827),
          ),
        ),
        content: Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFAAAAAA)
                    : Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return;

    final dispositivo = ProveedorDispositivo.of(context);
    final ok = await Glosario.eliminarTodosLosFavoritos(dispositivo.id);
    if (!mounted) return;

    if (ok) {
      setState(() => _favoritos = const []);
      FavoritosNotificador.notificar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favoritos eliminados')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron eliminar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTitulo =
        isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Favoritos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colorTitulo,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (_favoritos.isNotEmpty)
                    TextButton(
                      onPressed: _eliminarTodos,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      child: const Text(
                        'Eliminar todos',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _buildContenido()),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) return const ListaSkeleton(itemCount: 6, height: 70);
    if (_mensajeError != null) {
      return WidgetErrorRed(mensaje: _mensajeError!, onReintentar: _cargar);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTextoSec =
        isDark ? const Color(0xFFAAAAAA) : Colors.grey.shade600;

    if (_favoritos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_outline,
                size: 48,
                color: isDark ? const Color(0xFF717171) : Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No tienes favoritos guardados',
              style: TextStyle(fontSize: 14, color: colorTextoSec),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        itemCount: _favoritos.length,
        itemBuilder: (_, i) {
          final t = _favoritos[i];
          return AnimacionEliminar(
            key: ValueKey(t.idTermino),
            isDeleted: _eliminandoIds.contains(t.idTermino),
            onAnimationCompleted: () => _completarEliminacion(t),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _cardFavorito(t),
            ),
          );
        },
      ),
    );
  }

  Widget _cardFavorito(Termino t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF212121) : Colors.white;
    final colorBorde =
        isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB);
    final colorTexto =
        isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827);
    final colorIcono =
        isDark ? const Color(0xFF717171) : Colors.grey.shade500;

    return Material(
      color: bgCard,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PantallaResultado(nombreTermino: t.nombreTermino),
            ),
          );
          _cargar();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorBorde),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.nombreTermino,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorTexto,
                      ),
                    ),
                    if (t.categoria != null) ...[
                      const SizedBox(height: 6),
                      ChipCategoria(categoria: t.categoria!),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _iniciarEliminacion(t),
                icon: Icon(Icons.close, color: colorIcono, size: 22),
                tooltip: 'Quitar',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
