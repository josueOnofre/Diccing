import 'package:flutter/material.dart';

/// Categorías y estilos uniformes (escala de grises).
class ColoresCategoria {
  static Color fondo(String? categoria) => const Color(0xFFF3F4F6);
  static Color texto(String? categoria) => const Color(0xFF4B5563);
  static Color borde(String? categoria) => const Color(0xFFE5E7EB);

  static const List<String> todas = [
    'Programación',
    'Redes',
    'Hardware',
    'Base de Datos',
    'Sistemas',
    'Personal',
  ];
}

/// Chip de categoría — etiqueta simple con borde sutil.
class ChipCategoria extends StatelessWidget {
  final String categoria;
  final bool onLight;

  const ChipCategoria({
    super.key,
    required this.categoria,
    this.onLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (onLight) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Text(
          categoria,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    final fondo = isDark ? const Color(0xFF212121) : const Color(0xFFF3F4F6);
    final texto = isDark ? const Color(0xFFAAAAAA) : const Color(0xFF4B5563);
    final borde = isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borde, width: 1),
      ),
      child: Text(
        categoria,
        style: TextStyle(
          color: texto,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Chip seleccionable para filtros (pantalla Búsqueda).
class ChipFiltroCategoria extends StatelessWidget {
  final String categoria;
  final bool seleccionado;
  final VoidCallback onTap;

  const ChipFiltroCategoria({
    super.key,
    required this.categoria,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorBorde = isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB);
    final colorTextoSec = isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B7280);

    return ChoiceChip(
      label: Text(
        categoria,
        style: TextStyle(
          fontSize: 13,
          fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w400,
          color: seleccionado ? Colors.white : colorTextoSec,
        ),
      ),
      selected: seleccionado,
      selectedColor: const Color(0xFF1F2937),
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : colorBorde,
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorBorde),
      ),
    );
  }
}
