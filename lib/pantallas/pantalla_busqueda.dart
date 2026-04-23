import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../logica/diccionario_personal.dart';
import '../logica/glosario.dart';
import '../logica/termino.dart';
import '../logica/termino_personal.dart';
import '../services/auth_service.dart';
import 'pantalla_detalle_personal.dart';
import 'pantalla_resultado.dart';
import 'pantalla_sugerir.dart';
import 'widgets/chip_categoria.dart';
import 'widgets/indicador_carga_skeleton.dart';
import 'widgets/widget_error_red.dart';

class PantallaBusqueda extends StatefulWidget {
  const PantallaBusqueda({super.key});

  @override
  State<PantallaBusqueda> createState() => _PantallaBusquedaState();
}

class _PantallaBusquedaState extends State<PantallaBusqueda> {
  final TextEditingController _ctrl = TextEditingController();

  // Resultados globales
  List<Termino> _resultados = const [];
  // Resultados personales (cuando categoría == 'Personal')
  List<TerminoPersonal> _personales = const [];

  String? _categoriaSeleccionada;
  bool _cargando = true;
  String? _mensajeError;

  bool get _modoPersonal => _categoriaSeleccionada == 'Personal';

  @override
  void initState() {
    super.initState();
    AuthService.usuario.addListener(_onAuthChange);
    _buscar();
  }

  @override
  void dispose() {
    AuthService.usuario.removeListener(_onAuthChange);
    _ctrl.dispose();
    super.dispose();
  }

  void _onAuthChange() {
    if (mounted && _modoPersonal) _buscar();
  }

  Future<void> _buscar() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    try {
      if (_modoPersonal) {
        // ── Modo Personal ────────────────────────────────────
        final uid = AuthService.usuario.value?.id;
        if (uid == null) {
          if (!mounted) return;
          setState(() {
            _personales = [];
            _cargando = false;
          });
          return;
        }

        final q = _ctrl.text.trim().toLowerCase();
        final todos = await DiccionarioPersonal.obtenerMios(uid);
        final filtrados = q.isEmpty
            ? todos
            : todos
                .where((t) =>
                    t.nombre.toLowerCase().contains(q) ||
                    t.definicion.toLowerCase().contains(q))
                .toList();

        if (!mounted) return;
        setState(() {
          _personales = filtrados;
          _cargando = false;
        });
      } else {
        // ── Modo Global ──────────────────────────────────────
        final resultados = await Glosario.buscarTerminos(
          query: _ctrl.text,
          categoria: _categoriaSeleccionada,
        );
        if (!mounted) return;
        setState(() {
          _resultados = resultados;
          _cargando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError = 'No se pudieron buscar los términos.';
        _cargando = false;
      });
    }
  }

  void _seleccionarCategoria(String categoria) {
    setState(() {
      _categoriaSeleccionada =
          _categoriaSeleccionada == categoria ? null : categoria;
    });
    _buscar();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTitulo =
        isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827);
    final colorTextoSec =
        isDark ? const Color(0xFFAAAAAA) : Colors.grey.shade500;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buscar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorTitulo,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ctrl,
                    onChanged: (_) => _buscar(),
                    decoration: InputDecoration(
                      hintText: _modoPersonal
                          ? 'Buscar en mi diccionario...'
                          : 'Escribe un término',
                      prefixIcon:
                          Icon(Icons.search, color: colorTextoSec, size: 20),
                      suffixIcon: _ctrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(Icons.close,
                                  color: colorTextoSec, size: 18),
                              onPressed: () {
                                _ctrl.clear();
                                _buscar();
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ColoresCategoria.todas.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = ColoresCategoria.todas[i];
                        return ChipFiltroCategoria(
                          categoria: cat,
                          seleccionado: _categoriaSeleccionada == cat,
                          onTap: () => _seleccionarCategoria(cat),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(child: _buildResultados()),
          ],
        ),
      ),
    );
  }

  Widget _buildResultados() {
    if (_cargando) return const ListaSkeleton(itemCount: 6, height: 70);
    if (_mensajeError != null) {
      return WidgetErrorRed(mensaje: _mensajeError!, onReintentar: _buscar);
    }

    // ── Vista Personal ────────────────────────────────────────
    if (_modoPersonal) return _buildResultadosPersonales();

    // ── Vista Global ──────────────────────────────────────────
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTextoSec =
        isDark ? const Color(0xFFAAAAAA) : Colors.grey.shade600;

    if (_resultados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 48,
                color: isDark ? const Color(0xFF717171) : Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Sin resultados',
                style: TextStyle(fontSize: 14, color: colorTextoSec)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaSugerir()),
                );
              },
              icon: const Icon(CupertinoIcons.lightbulb, size: 18),
              label: const Text('Sugerir término'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      itemCount: _resultados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _cardGlobal(_resultados[i]),
    );
  }

  Widget _buildResultadosPersonales() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTextoSec =
        isDark ? const Color(0xFFAAAAAA) : Colors.grey.shade600;

    // No autenticado
    if (AuthService.usuario.value == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.lock_circle,
                  size: 52, color: colorTextoSec),
              const SizedBox(height: 14),
              Text(
                'Inicia sesión con Google para\nver tu diccionario personal',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: colorTextoSec, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    // Autenticado pero vacío
    if (_personales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.book_circle,
                size: 48, color: colorTextoSec),
            const SizedBox(height: 12),
            Text(
              _ctrl.text.isEmpty
                  ? 'Tu diccionario personal está vacío'
                  : 'Sin coincidencias en tu diccionario',
              style: TextStyle(fontSize: 14, color: colorTextoSec),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      itemCount: _personales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _cardPersonal(_personales[i]),
    );
  }

  // ── Card término global ──────────────────────────────────────
  Widget _cardGlobal(Termino t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF212121) : Colors.white;
    final colorBorde =
        isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB);
    final colorTexto =
        isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827);
    final colorChevron =
        isDark ? const Color(0xFF717171) : Colors.grey.shade400;

    return Material(
      color: bgCard,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  PantallaResultado(nombreTermino: t.nombreTermino)),
        ),
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
                    const SizedBox(height: 6),
                    if (t.categoria != null)
                      ChipCategoria(categoria: t.categoria!),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorChevron, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card término personal (estilo índigo) ────────────────────
  Widget _cardPersonal(TerminoPersonal t) {
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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PantallaDetallePersonal(termino: t)),
            );
            // Recargar por si editó o eliminó
            if (_modoPersonal) _buscar();
          },
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorNombre,
                        ),
                      ),
                      if (t.categoria != null &&
                          t.categoria!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          t.categoria!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6366F1),
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
                const SizedBox(width: 10),
                Icon(Icons.chevron_right,
                    color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                    size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
