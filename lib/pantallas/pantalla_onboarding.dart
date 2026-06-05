import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pantalla_principal.dart';

class PantallaOnboarding extends StatefulWidget {
  const PantallaOnboarding({super.key});

  @override
  State<PantallaOnboarding> createState() => _PantallaOnboardingState();
}

class _PantallaOnboardingState extends State<PantallaOnboarding> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'titulo': 'Busca Términos',
      'descripcion': 'Encuentra definiciones precisas de conceptos de programación, redes, bases de datos y más.',
      'icono': CupertinoIcons.search,
      'color': const Color(0xFF6366F1), // Indigo
    },
    {
      'titulo': 'Mi Diccionario',
      'descripcion': 'Crea tus propias definiciones personalizadas y guárdalas de forma segura en la nube.',
      'icono': CupertinoIcons.book_fill,
      'color': const Color(0xFF10B981), // Emerald
    },
    {
      'titulo': 'Sugerencias',
      'descripcion': 'Aporta a la comunidad sugiriendo nuevos términos. Tu conocimiento ayuda a todos.',
      'icono': CupertinoIcons.lightbulb_fill,
      'color': const Color(0xFFF59E0B), // Amber
    },
  ];

  void _irAInicio() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ya_vio_onboarding', true);

    if (!mounted) return;
    
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PantallaPrincipal()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Botón Saltar
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _irAInicio,
                child: Text(
                  'Saltar',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _paginaActual = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: (slide['color'] as Color).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                slide['icono'] as IconData,
                                size: 80,
                                color: slide['color'] as Color,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              slide['titulo'] as String,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827),
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide['descripcion'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF4B5563),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Indicadores y Botón Siguiente/Comenzar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _paginaActual == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _paginaActual == index
                              ? const Color(0xFF6366F1) // Indigo
                              : (isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  // Botón Siguiente o Comenzar
                  ElevatedButton(
                    onPressed: () {
                      if (_paginaActual == _slides.length - 1) {
                        _irAInicio();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1), // Indigo
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _paginaActual == _slides.length - 1 ? 'Comenzar' : 'Siguiente',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
