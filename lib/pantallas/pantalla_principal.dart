import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../services/auth_service.dart';
import 'pantalla_inicio.dart';
import 'pantalla_busqueda.dart';
import 'pantalla_favoritos.dart';
import 'pantalla_historial.dart';
import 'pantalla_diccionario_personal.dart';

/// Contenedor principal con BottomNavigationBar.
/// Permite cambiar de tab desde cualquier parte usando
/// PantallaPrincipal.irATab(int).
class PantallaPrincipal extends StatefulWidget {
  PantallaPrincipal({Key? key}) : super(key: key ?? _globalKey);

  static final GlobalKey<EstadoPantallaPrincipal> _globalKey =
      GlobalKey<EstadoPantallaPrincipal>();

  /// Cambia el tab activo desde cualquier pantalla.
  static void irATab(int indice) {
    _globalKey.currentState?.cambiarTab(indice);
  }

  @override
  State<PantallaPrincipal> createState() => EstadoPantallaPrincipal();
}

class EstadoPantallaPrincipal extends State<PantallaPrincipal> {
  int _indice = 0;

  final List<Widget> _pantallas = const [
    PantallaInicio(),
    PantallaBusqueda(),
    PantallaFavoritos(),
    PantallaHistorial(),
    PantallaDiccionarioPersonal(),
  ];

  void cambiarTab(int i) {
    if (i < 0 || i >= _pantallas.length) return;
    setState(() => _indice = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _indice, children: _pantallas),
          Align(
            alignment: Alignment.bottomCenter,
            child: ValueListenableBuilder<User?>(
              valueListenable: AuthService.usuario,
              builder: (_, user, __) {
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(
                              (255 * (isDark ? 0.3 : 0.1)).round(),
                            ),
                            blurRadius: 20,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Theme.of(context).colorScheme.surface
                                        .withValues(alpha: 0.55)
                                  : Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: SizedBox(
                              height: 56,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: _buildNavItem(
                                      0,
                                      Icons.home_outlined,
                                      Icons.home_rounded,
                                      'Inicio',
                                      isDark,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildNavItem(
                                      1,
                                      Icons.search_outlined,
                                      Icons.search_rounded,
                                      'Buscar',
                                      isDark,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildNavItem(
                                      2,
                                      Icons.star_outline_rounded,
                                      Icons.star_rounded,
                                      'Favoritos',
                                      isDark,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildNavItem(
                                      3,
                                      Icons.history_outlined,
                                      Icons.history_rounded,
                                      'Historial',
                                      isDark,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildNavItem(
                                      4,
                                      Icons.menu_book_outlined,
                                      Icons.menu_book_rounded,
                                      'Personal',
                                      isDark,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
    bool isDark,
  ) {
    return _NavItemAnimado(
      index: index,
      isSelected: _indice == index,
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
      isDark: isDark,
      onTap: () => cambiarTab(index),
    );
  }
}

class _NavItemAnimado extends StatefulWidget {
  final int index;
  final bool isSelected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItemAnimado({
    required this.index,
    required this.isSelected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavItemAnimado> createState() => _NavItemAnimadoState();
}

class _NavItemAnimadoState extends State<_NavItemAnimado> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).colorScheme.primary;
    final colorTextoSec = widget.isDark
        ? const Color(0xFFAAAAAA)
        : Colors.grey.shade600;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? colorPrimario.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    widget.isSelected ? widget.selectedIcon : widget.icon,
                    key: ValueKey<bool>(widget.isSelected),
                    color: widget.isSelected ? colorPrimario : colorTextoSec,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: widget.isSelected ? colorPrimario : colorTextoSec,
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
