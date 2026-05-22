import 'package:flutter/material.dart';

class WidgetErrorRed extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const WidgetErrorRed({
    super.key,
    required this.mensaje,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTextoSec =
        isDark ? const Color(0xFFAAAAAA) : Colors.grey.shade600;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined, size: 40, color: colorTextoSec),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorTextoSec),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
