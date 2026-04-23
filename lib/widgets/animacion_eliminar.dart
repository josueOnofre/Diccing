import 'package:flutter/material.dart';

class AnimacionEliminar extends StatefulWidget {
  final Widget child;
  final bool isDeleted;
  final VoidCallback onAnimationCompleted;

  const AnimacionEliminar({
    super.key,
    required this.child,
    required this.isDeleted,
    required this.onAnimationCompleted,
  });

  @override
  State<AnimacionEliminar> createState() => _AnimacionEliminarState();
}

class _AnimacionEliminarState extends State<AnimacionEliminar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // Inicia visible
    );

    // Efecto de escala al desaparecer (de 1.0 a 0.8)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Efecto de opacidad al desaparecer
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isDeleted) {
      _controller.reverse().then((_) => widget.onAnimationCompleted());
    }
  }

  @override
  void didUpdateWidget(covariant AnimacionEliminar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDeleted && !oldWidget.isDeleted) {
      _controller.reverse().then((_) => widget.onAnimationCompleted());
    } else if (!widget.isDeleted && oldWidget.isDeleted) {
      // Si el widget se recicla para otra tarjeta
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SizeTransition anima la altura (para que las tarjetas de abajo suban suavemente)
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutQuart,
      ),
      axisAlignment: 0.0,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}
