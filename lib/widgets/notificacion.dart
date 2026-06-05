import 'package:flutter/material.dart';

OverlayEntry? _entradaActual;

void mostrarNotificacion(BuildContext context, String mensaje, {bool esError = false}) {
  // Eliminar notificación anterior si existe
  _entradaActual?.remove();
  _entradaActual = null;

  final overlay = Overlay.of(context);
  late OverlayEntry entrada;

  entrada = OverlayEntry(
    builder: (_) => _NotificacionFlotante(
      mensaje: mensaje,
      esError: esError,
      onDismiss: () {
        _entradaActual?.remove();
        _entradaActual = null;
      },
    ),
  );

  _entradaActual = entrada;
  overlay.insert(entrada);
}

class _NotificacionFlotante extends StatefulWidget {
  final String mensaje;
  final bool esError;
  final VoidCallback onDismiss;

  const _NotificacionFlotante({
    required this.mensaje,
    required this.esError,
    required this.onDismiss,
  });

  @override
  State<_NotificacionFlotante> createState() => _NotificacionFlotanteState();
}

class _NotificacionFlotanteState extends State<_NotificacionFlotante>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacidad;
  late Animation<Offset> _deslizamiento;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _opacidad = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      reverseCurve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    _deslizamiento = Tween<Offset>(
      begin: const Offset(0, -1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();

    // Esperar y luego desaparecer
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = widget.esError
        ? const Color(0xFFDC2626)
        : (isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937));

    final Color bordeColor = widget.esError
        ? const Color(0xFFEF4444).withValues(alpha: 0.4)
        : (isDark
            ? Colors.black.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.15));

    final Color contentColor = widget.esError
        ? Colors.white
        : (isDark ? const Color(0xFF111827) : Colors.white);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
          child: SlideTransition(
            position: _deslizamiento,
            child: FadeTransition(
              opacity: _opacidad,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {
                    _controller.reverse().then((_) {
                      if (mounted) widget.onDismiss();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(50), // más redondeado
                      border: Border.all(color: bordeColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // se adapta al contenido
                      children: [
                        Icon(
                          widget.esError
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          color: contentColor,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Flexible( // no fuerza ancho máximo
                          child: Text(
                            widget.mensaje,
                            style: TextStyle(
                              color: contentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
