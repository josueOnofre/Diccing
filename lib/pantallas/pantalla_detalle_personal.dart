import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../logica/termino_personal.dart';
import '../logica/diccionario_personal.dart';
import '../widgets/notificacion.dart';
import 'pantalla_crear_termino.dart';

class PantallaDetallePersonal extends StatefulWidget {
  final TerminoPersonal termino;

  const PantallaDetallePersonal({super.key, required this.termino});

  @override
  State<PantallaDetallePersonal> createState() =>
      _PantallaDetallePersonalState();
}

class _PantallaDetallePersonalState extends State<PantallaDetallePersonal> {
  late TerminoPersonal _termino;
  bool _eliminando = false;

  @override
  void initState() {
    super.initState();
    _termino = widget.termino;
  }

  Future<void> _editar() async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaCrearTermino(terminoAEditar: _termino),
      ),
    );
    if (actualizado == true) {
      // Cerramos y el padre recarga la lista
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _confirmarEliminar() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: AlertDialog(
          backgroundColor:
              isDark ? const Color(0xFF212121).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Eliminar término',
          style: TextStyle(
            color: isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '¿Seguro que quieres eliminar "${_termino.nombre}"? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? const Color(0xFFAAAAAA) : Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _eliminando = true);
    final exito = await DiccionarioPersonal.eliminar(_termino.id!);

    if (!mounted) return;
    setState(() => _eliminando = false);

    if (exito) {
      Navigator.pop(context, true);
    } else {
      mostrarNotificacion(context, 'No se pudo eliminar. Verifica tu conexión.', esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTexto =
        isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827);
    final colorTextoSec =
        isDark ? const Color(0xFFAAAAAA) : const Color(0xFF4B5563);
    final colorDivider =
        isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Término'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: _editar,
          ),
          _eliminando
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  tooltip: 'Eliminar',
                  onPressed: _confirmarEliminar,
                ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge personal
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.book_fill,
                        color: Color(0xFF6366F1), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Mi Diccionario',
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nombre
              Text(
                _termino.nombre,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: colorTexto,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Categoría
              if (_termino.categoria != null &&
                  _termino.categoria!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _termino.categoria!,
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              Divider(color: colorDivider, height: 1),
              const SizedBox(height: 24),

              // Definición
              Text(
                'Definición',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorTexto,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _termino.definicion,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: colorTextoSec,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
