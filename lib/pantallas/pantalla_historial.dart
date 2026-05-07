import 'dart:ui';
import 'package:flutter/material.dart';
import '../logica/glosario.dart';
import '../logica/historial.dart';
import '../logica/notificadores.dart';
import '../provider/dispositivo_provider.dart';
import 'pantalla_resultado.dart';
import 'widgets/chip_categoria.dart';
import 'widgets/indicador_carga_skeleton.dart';
import 'widgets/widget_error_red.dart';
import '../widgets/animacion_eliminar.dart';

class PantallaHistorial extends StatefulWidget {
  const PantallaHistorial({super.key});

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  List<HistorialItem> _items = const [];
  final Set<int> _eliminandoIds = {};
  bool _cargando = true;
  bool _datosListos = false;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    HistorialNotificador.notificador.addListener(_alCambiarHistorial);
  }

  @override
  void dispose() {
    HistorialNotificador.notificador.removeListener(_alCambiarHistorial);
    super.dispose();
  }

  void _alCambiarHistorial() {
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
      if (_items.isEmpty) _cargando = true;
      _mensajeError = null;
    });
    try {
      final dispositivo = ProveedorDispositivo.of(context);
      final items = await Glosario.obtenerHistorial(dispositivo.id);
      if (!mounted) return;
      setState(() {
        _items = items;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError = 'No se pudo cargar el historial.';
        _cargando = false;
      });
    }
  }

  void _iniciarEliminacion(HistorialItem it) {
    setState(() {
      _eliminandoIds.add(it.idHistorial);
    });
  }

  Future<void> _completarEliminacion(HistorialItem it) async {
    setState(() {
      _items = _items.where((i) => i.idHistorial != it.idHistorial).toList();
      _eliminandoIds.remove(it.idHistorial);
    });
    await Glosario.eliminarDelHistorial(it.idHistorial);
  }

  Future<void> _eliminarTodo() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF212121).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
          'Eliminar todo el historial',
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
    await Glosario.eliminarTodoHistorial(dispositivo.id);
    if (!mounted) return;
    setState(() => _items = const []);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historial eliminado')),
    );
  }

  String _formatearFecha(DateTime f) {
    final ahora = DateTime.now();
    final dif = ahora.difference(f);
    if (dif.inMinutes < 1) return 'Hace un momento';
    if (dif.inMinutes < 60) return 'Hace ${dif.inMinutes} min';
    if (dif.inHours < 24) return 'Hace ${dif.inHours} h';
    if (dif.inDays < 7) return 'Hace ${dif.inDays} d';
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
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
                      'Historial',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colorTitulo,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (_items.isNotEmpty)
                    TextButton(
                      onPressed: _eliminarTodo,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      child: const Text(
                        'Limpiar historial',
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
    if (_cargando) return const ListaSkeleton(itemCount: 6, height: 75);
    if (_mensajeError != null) {
      return WidgetErrorRed(mensaje: _mensajeError!, onReintentar: _cargar);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTextoSec =
        isDark ? const Color(0xFFAAAAAA) : Colors.grey.shade600;

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined,
                size: 48,
                color: isDark ? const Color(0xFF717171) : Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Sin historial',
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
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final it = _items[i];
          return AnimacionEliminar(
            key: ValueKey(it.idHistorial),
            isDeleted: _eliminandoIds.contains(it.idHistorial),
            onAnimationCompleted: () => _completarEliminacion(it),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _itemHistorial(it),
            ),
          );
        },
      ),
    );
  }

  Widget _itemHistorial(HistorialItem it) {
    final t = it.termino;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF212121) : Colors.white;
    final colorBorde =
        isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB);
    final colorTexto =
        isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827);
    final colorFecha =
        isDark ? const Color(0xFFAAAAAA) : Colors.grey.shade600;
    final colorChevron =
        isDark ? const Color(0xFF717171) : Colors.grey.shade400;

    return Material(
      color: bgCard,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
          borderRadius: BorderRadius.circular(24),
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (t.categoria != null) ...[
                            ChipCategoria(categoria: t.categoria!),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _formatearFecha(it.fechaConsulta),
                            style:
                                TextStyle(fontSize: 11, color: colorFecha),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _iniciarEliminacion(it),
                  icon: Icon(Icons.close, color: colorChevron, size: 22),
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
