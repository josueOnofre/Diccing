import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../logica/glosario.dart';
import '../logica/notificadores.dart';
import '../logica/termino.dart';
import '../provider/dispositivo_provider.dart';
import 'widgets/chip_categoria.dart';
import 'widgets/widget_error_red.dart';

class PantallaResultado extends StatefulWidget {
  final String nombreTermino;
  const PantallaResultado({super.key, required this.nombreTermino});

  @override
  State<PantallaResultado> createState() => _PantallaResultadoState();
}

class _PantallaResultadoState extends State<PantallaResultado> {
  Termino? _termino;
  List<Termino> _relacionados = const [];
  bool _esFavorito = false;
  bool _cargando = true;
  bool _datosListos = false;
  String? _mensajeError;

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
      _cargando = true;
      _mensajeError = null;
    });
    try {
      final dispositivo = ProveedorDispositivo.of(context);
      final t = await Glosario.buscarTermino(widget.nombreTermino);

      if (t == null) {
        if (!mounted) return;
        setState(() => _cargando = false);
        return;
      }

      Glosario.guardarEnHistorial(t.idTermino, dispositivo.id);
      Glosario.incrementarVistas(t.idTermino);
      HistorialNotificador.notificar();

      final esFav = await Glosario.esFavorito(t.idTermino, dispositivo.id);
      final relacionados = await Glosario.obtenerTerminosRelacionados(
        categoria: t.categoria,
        idActual: t.idTermino,
        limite: 5,
      );

      if (!mounted) return;
      setState(() {
        _termino = t;
        _esFavorito = esFav;
        _relacionados = relacionados;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError = 'No se pudo cargar el término.';
        _cargando = false;
      });
    }
  }

  Future<void> _toggleFavorito() async {
    if (_termino == null) return;
    final dispositivo = ProveedorDispositivo.of(context);
    final estadoAnterior = _esFavorito;
    setState(() => _esFavorito = !estadoAnterior);

    await Glosario.cambiarEstadoFavorito(
      idTermino: _termino!.idTermino,
      idDispositivo: dispositivo.id,
      esFavActual: estadoAnterior,
    );
    FavoritosNotificador.notificar();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(estadoAnterior
            ? 'Eliminado de favoritos'
            : 'Añadido a favoritos'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _compartir() async {
    if (_termino == null) return;
    final texto =
        '${_termino!.nombreTermino}\n\n${_termino!.definicion}\n\nDICCING';
    await Share.share(texto, subject: _termino!.nombreTermino);
  }

  @override
  void dispose() {
    final cache = PaintingBinding.instance.imageCache;
    if (_termino?.imagenUrl != null) {
      cache.evict(NetworkImage(_termino!.imagenUrl!));
    }
    if (_termino?.imagenUrlEjemplo != null) {
      cache.evict(NetworkImage(_termino!.imagenUrlEjemplo!));
    }
    super.dispose();
  }

  Future<void> _copiarDefinicion() async {
    if (_termino == null) return;
    await Clipboard.setData(ClipboardData(text: _termino!.definicion));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Definición copiada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorSup = isDark ? const Color(0xFF212121) : Colors.white;
    final colorTexto =
        isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827);
    final colorTextoSec =
        isDark ? const Color(0xFFAAAAAA) : Colors.grey.shade600;
    final colorBorde =
        isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB);

    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_mensajeError != null) {
      return Scaffold(
        appBar: AppBar(),
        body: WidgetErrorRed(mensaje: _mensajeError!, onReintentar: _cargar),
      );
    }
    if (_termino == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('No se encontró el término',
              style: TextStyle(color: colorTextoSec)),
        ),
      );
    }

    final t = _termino!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Detalle del término',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 20),
              tooltip: 'Copiar definición',
              onPressed: _copiarDefinicion,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20),
              tooltip: 'Compartir',
              onPressed: _compartir,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // Header del término
            Container(
              width: double.infinity,
              color: colorSup,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (t.categoria != null) ChipCategoria(categoria: t.categoria!),
                  const SizedBox(height: 10),
                  Text(
                    t.nombreTermino,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colorTexto,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.visibility_outlined,
                          color: colorTextoSec, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${t.vistas} vistas',
                        style: TextStyle(color: colorTextoSec, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Tabs
            Container(
              color: colorSup,
              child: TabBar(
                labelColor: colorTexto,
                unselectedLabelColor: colorTextoSec,
                indicatorColor: colorTexto,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
                tabs: const [
                  Tab(text: 'Definición'),
                  Tab(text: 'Ejemplo'),
                  Tab(text: 'Relacionados'),
                ],
              ),
            ),
            Divider(height: 1, color: colorBorde),
            Expanded(
              child: TabBarView(
                children: [
                  _tabContenido(t.definicion, colorTexto, imagenUrl: t.imagenUrl),
                  _tabContenido(
                    t.ejemplo.isEmpty
                        ? 'No hay ejemplo disponible para este término.'
                        : t.ejemplo,
                    colorTexto,
                    imagenUrl: t.imagenUrlEjemplo,
                  ),
                  _tabRelacionados(colorSup, colorBorde, colorTexto, colorTextoSec),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _toggleFavorito,
          backgroundColor: _esFavorito ? colorTexto : colorSup,
          foregroundColor: _esFavorito ? colorSup : colorTexto,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: BorderSide(color: colorBorde),
          ),
          icon: Icon(
            _esFavorito ? Icons.bookmark : Icons.bookmark_outline,
            size: 18,
          ),
          label: Text(
            _esFavorito ? 'Guardado' : 'Guardar',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _tabContenido(String texto, Color colorTexto, {String? imagenUrl}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorFondoImg =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagenUrl != null) ...[
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _VisorImagenCompleta(url: imagenUrl),
                  fullscreenDialog: true,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  color: colorFondoImg,
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: Image.network(
                    imagenUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 120,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            texto,
            style: TextStyle(fontSize: 15, height: 1.6, color: colorTexto),
          ),
        ],
      ),
    );
  }

  Widget _tabRelacionados(
    Color colorSup,
    Color colorBorde,
    Color colorTexto,
    Color colorTextoSec,
  ) {
    if (_relacionados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 40, color: colorTextoSec),
              const SizedBox(height: 12),
              Text(
                'No hay términos relacionados',
                style: TextStyle(color: colorTextoSec, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _relacionados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = _relacionados[i];
        return Material(
          color: colorSup,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PantallaResultado(nombreTermino: r.nombreTermino),
                ),
              );
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
                    child: Text(
                      r.nombreTermino,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorTexto,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colorTextoSec, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// Visor de imagen a pantalla completa
// ════════════════════════════════════════════════════════════
class _VisorImagenCompleta extends StatelessWidget {
  final String url;
  const _VisorImagenCompleta({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 6.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Text(
                'No se pudo cargar la imagen',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
