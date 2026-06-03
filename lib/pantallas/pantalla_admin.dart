import 'package:flutter/material.dart';
import 'dart:ui';
import '../baseDeDatos/conexion.dart';
import '../logica/glosario.dart';
import '../services/auth_service.dart';

const _categoriasGlosario = [
  'Programación',
  'Redes',
  'Hardware',
  'Base de Datos',
  'Sistemas',
  'Sugerido',
];

class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});

  @override
  State<PantallaAdmin> createState() => _PantallaAdminState();
}

class _PantallaAdminState extends State<PantallaAdmin>
    with SingleTickerProviderStateMixin {
  // ── Sugerencias ──────────────────────────────────────────────
  List<Map<String, dynamic>> _sugerencias = [];
  List<Map<String, dynamic>> _sugerenciasFiltradas = [];
  bool _cargando = true;
  String? _mensajeError;
  String _filtro = 'pendiente';
  final _busquedaCtrl = TextEditingController();

  // ── Términos ─────────────────────────────────────────────────
  List<Map<String, dynamic>> _terminos = [];
  List<Map<String, dynamic>> _terminosFiltrados = [];
  bool _cargandoTerminos = true;
  String? _mensajeErrorTerminos;
  final _busquedaTerminosCtrl = TextEditingController();

  // ── Tabs ─────────────────────────────────────────────────────
  late final TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _tabIndex) {
        setState(() => _tabIndex = _tabController.index);
        if (_tabController.index == 1 && _cargandoTerminos) {
          _cargarTerminos();
        }
      }
    });
    _busquedaCtrl.addListener(_aplicarFiltros);
    _busquedaTerminosCtrl.addListener(_filtrarTerminos);
    _cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.removeListener(_aplicarFiltros);
    _busquedaCtrl.dispose();
    _busquedaTerminosCtrl.removeListener(_filtrarTerminos);
    _busquedaTerminosCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Cargar sugerencias ─────────────────────────────────────
  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });
    try {
      final resp = await SupabaseConexion.client
          .from('sugerencias')
          .select()
          .order('creado_en', ascending: false);
      if (!mounted) return;
      _sugerencias = List<Map<String, dynamic>>.from(resp as List);
      _aplicarFiltros();
      setState(() => _cargando = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError = 'No se pudieron cargar las sugerencias.';
        _cargando = false;
      });
    }
  }

  void _aplicarFiltros() {
    final q = _busquedaCtrl.text.toLowerCase();
    setState(() {
      _sugerenciasFiltradas = _sugerencias.where((s) {
        final estado =
            (s['estado'] as String? ?? 'pendiente').trim().toLowerCase();
        final termino = (s['termino_sugerido'] as String? ?? '').toLowerCase();
        return (q.isEmpty || termino.contains(q)) &&
            (_filtro == 'todas' || estado == _filtro);
      }).toList();
    });
  }

  int get _totalPendientes => _sugerencias
      .where((s) => (s['estado'] as String? ?? 'pendiente') == 'pendiente')
      .length;

  // ── Cargar términos ────────────────────────────────────────
  Future<void> _cargarTerminos() async {
    setState(() {
      _cargandoTerminos = true;
      _mensajeErrorTerminos = null;
    });
    try {
      final resp = await SupabaseConexion.client
          .from('terminos')
          .select(
              'id, nombretermino, definicion, ejemplo, imagen_url, imagen_url_ejemplo, categoria, vistas')
          .order('nombretermino', ascending: true);
      if (!mounted) return;
      _terminos = List<Map<String, dynamic>>.from(resp as List);
      _filtrarTerminos();
      setState(() => _cargandoTerminos = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeErrorTerminos = 'No se pudieron cargar los términos.';
        _cargandoTerminos = false;
      });
    }
  }

  void _filtrarTerminos() {
    final q = _busquedaTerminosCtrl.text.toLowerCase();
    setState(() {
      _terminosFiltrados = _terminos.where((t) {
        final nombre = (t['nombretermino'] as String? ?? '').toLowerCase();
        return q.isEmpty || nombre.contains(q);
      }).toList();
    });
  }

  // ── Aprobar sugerencia ─────────────────────────────────────
  Future<void> _aprobar(Map<String, dynamic> s) async {
    final nombre = s['termino_sugerido'] as String? ?? '';
    final desc = s['descripcion'] as String? ?? '';
    final adminEmail = AuthService.emailUsuario ?? 'admin';
    try {
      await SupabaseConexion.client.from('terminos').insert({
        'nombretermino': nombre,
        'definicion': desc.isNotEmpty ? desc : nombre,
        'ejemplo': '',
        'categoria': 'Sugerido',
        'vistas': 0,
      });
      await SupabaseConexion.client.from('sugerencias').update({
        'estado': 'aprobada',
        'aprobado_por': adminEmail,
        'aprobado_en': DateTime.now().toIso8601String(),
      }).eq('id', s['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Término "$nombre" aprobado')));
      _cargar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al aprobar la sugerencia')));
    }
  }

  // ── Rechazar sugerencia ────────────────────────────────────
  Future<void> _rechazar(Map<String, dynamic> s) async {
    final adminEmail = AuthService.emailUsuario ?? 'admin';
    try {
      await SupabaseConexion.client.from('sugerencias').update({
        'estado': 'rechazada',
        'aprobado_por': adminEmail,
        'aprobado_en': DateTime.now().toIso8601String(),
      }).eq('id', s['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sugerencia rechazada')));
      _cargar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al rechazar la sugerencia')));
    }
  }

  // ── Buscar término en glosario por nombre ──────────────────
  Future<Map<String, dynamic>?> _buscarTerminoEnGlosario(
      String nombre) async {
    try {
      final resp = await SupabaseConexion.client
          .from('terminos')
          .select(
              'id, nombretermino, definicion, ejemplo, imagen_url, imagen_url_ejemplo, categoria, vistas')
          .ilike('nombretermino', nombre)
          .limit(1);
      final lista = resp as List;
      if (lista.isEmpty) return null;
      return lista.first as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Editar término desde sugerencia aprobada ───────────────
  Future<void> _abrirEditorTermino(Map<String, dynamic> sugerencia) async {
    final nombreSugerido = sugerencia['termino_sugerido'] as String? ?? '';
    final termino = await _buscarTerminoEnGlosario(nombreSugerido);
    if (!mounted) return;
    if (termino == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'No se encontró "$nombreSugerido" en el glosario. Puede haber sido eliminado.'),
      ));
      return;
    }
    final actualizado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheetEditarTermino(termino: termino),
    );
    if (actualizado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Término actualizado en el glosario')));
    }
  }

  // ── Editar término directo desde tab Términos ──────────────
  Future<void> _editarTerminoDirecto(Map<String, dynamic> termino) async {
    final actualizado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheetEditarTermino(termino: termino),
    );
    if (actualizado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Término actualizado en el glosario')));
      _cargarTerminos();
    }
  }

  // ── Quitar término desde sugerencia aprobada ───────────────
  Future<void> _quitarDelGlosario(Map<String, dynamic> sugerencia) async {
    final nombreSugerido = sugerencia['termino_sugerido'] as String? ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Validar que el usuario sea admin
    if (!AuthService.esAdmin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solo administradores pueden quitar términos')));
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => _dialogConfirmacion(
        isDark: isDark,
        titulo: 'Quitar del glosario',
        cuerpo:
            '¿Eliminar "$nombreSugerido" del glosario global? La sugerencia seguirá registrada como aprobada.',
        labelConfirmar: 'Quitar',
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await SupabaseConexion.client
          .from('terminos')
          .delete()
          .ilike('nombretermino', nombreSugerido);

      // Eliminar también la fila de sugerencias para no dejarla huérfana
      await SupabaseConexion.client
          .from('sugerencias')
          .delete()
          .eq('id', sugerencia['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$nombreSugerido" quitado del glosario')));
      _cargar();
    } catch (e) {
      if (!mounted) return;
      print('Error quitando término: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().split('\n').first}')));
    }
  }

  // ── Eliminar término directo desde tab Términos ────────────
  Future<void> _eliminarTermino(Map<String, dynamic> termino) async {
    final nombre = termino['nombretermino'] as String? ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Validar que el usuario sea admin
    if (!AuthService.esAdmin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solo administradores pueden eliminar términos')));
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => _dialogConfirmacion(
        isDark: isDark,
        titulo: 'Eliminar término',
        cuerpo: '¿Eliminar "$nombre" del glosario permanentemente?',
        labelConfirmar: 'Eliminar',
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      final id = termino['id'];
      if (id == null) {
        throw Exception('ID del término inválido');
      }

      await SupabaseConexion.client
          .from('terminos')
          .delete()
          .eq('id', id);

      // Limpiar sugerencias aprobadas con ese nombre para no dejar huérfanas
      await SupabaseConexion.client
          .from('sugerencias')
          .delete()
          .eq('estado', 'aprobada')
          .ilike('termino_sugerido', nombre);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$nombre" eliminado del glosario')));
      _cargarTerminos();
    } catch (e) {
      if (!mounted) return;
      print('Error eliminando término: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().split('\n').first}')));
    }
  }

  // ── Crear término nuevo ────────────────────────────────────
  Future<void> _crearTermino() async {
    final creado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BottomSheetCrearTermino(),
    );
    if (creado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Término creado en el glosario')));
      _cargarTerminos();
    }
  }

  // ── Dialog de confirmación reutilizable ────────────────────
  Widget _dialogConfirmacion({
    required bool isDark,
    required String titulo,
    required String cuerpo,
    required String labelConfirmar,
  }) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF212121).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(titulo,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFF1F1F1)
                    : const Color(0xFF111827))),
        content: Text(cuerpo,
            style: TextStyle(
                color: isDark
                    ? const Color(0xFFAAAAAA)
                    : const Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFFAAAAAA)
                        : Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(labelConfirmar,
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = isDark ? const Color(0xFF212121) : Colors.white;
    final colorBorde =
        isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB);
    final colorTexto =
        isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827);
    final colorTextoSec =
        isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B7280);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Recargar',
            onPressed: _tabIndex == 0 ? _cargar : _cargarTerminos,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorTexto,
          unselectedLabelColor: colorTextoSec,
          indicatorColor: colorTexto,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Inter'),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500, fontSize: 13, fontFamily: 'Inter'),
          tabs: [
            Tab(
              text: _totalPendientes > 0
                  ? 'Sugerencias ($_totalPendientes)'
                  : 'Sugerencias',
            ),
            const Tab(text: 'Términos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _tabSugerencias(colorFondo, colorBorde, colorTexto, colorTextoSec),
          _tabTerminos(colorFondo, colorBorde, colorTexto, colorTextoSec),
        ],
      ),
      floatingActionButton: _tabIndex == 1
          ? FloatingActionButton(
              onPressed: _crearTermino,
              backgroundColor: colorTexto,
              foregroundColor: colorFondo,
              tooltip: 'Nuevo término',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // ── Tab Sugerencias ────────────────────────────────────────
  Widget _tabSugerencias(Color colorFondo, Color colorBorde, Color colorTexto,
      Color colorTextoSec) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          color: colorFondo,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Sugerencias pendientes: ',
                      style:
                          TextStyle(fontSize: 13, color: colorTextoSec)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _totalPendientes > 0
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_totalPendientes',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _totalPendientes > 0
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _busquedaCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por término...',
                  prefixIcon:
                      Icon(Icons.search, color: colorTextoSec, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF3D3D3D)
                            : const Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['todas', 'pendiente', 'aprobada', 'rechazada']
                      .map((f) {
                    final activo = _filtro == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          f[0].toUpperCase() + f.substring(1),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: activo
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color:
                                activo ? Colors.white : colorTextoSec,
                          ),
                        ),
                        selected: activo,
                        selectedColor: const Color(0xFF1F2937),
                        backgroundColor: isDark
                            ? const Color(0xFF0F0F0F)
                            : colorBorde,
                        onSelected: (_) {
                          setState(() => _filtro = f);
                          _aplicarFiltros();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: colorBorde),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: colorBorde),
            ],
          ),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _mensajeError != null
                  ? _errorWidget(_mensajeError!, colorTextoSec, _cargar)
                  : _sugerenciasFiltradas.isEmpty
                      ? _vacioCentered(
                          'No hay sugerencias en esta categoría',
                          colorTextoSec)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _sugerenciasFiltradas.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _cardSugerencia(
                            _sugerenciasFiltradas[i],
                            colorFondo,
                            colorBorde,
                            colorTexto,
                            colorTextoSec,
                          ),
                        ),
        ),
      ],
    );
  }

  // ── Tab Términos ───────────────────────────────────────────
  Widget _tabTerminos(Color colorFondo, Color colorBorde, Color colorTexto,
      Color colorTextoSec) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          color: colorFondo,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            children: [
              TextField(
                controller: _busquedaTerminosCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar término...',
                  prefixIcon:
                      Icon(Icons.search, color: colorTextoSec, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF3D3D3D)
                            : const Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: colorBorde),
            ],
          ),
        ),
        Expanded(
          child: _cargandoTerminos
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _mensajeErrorTerminos != null
                  ? _errorWidget(
                      _mensajeErrorTerminos!, colorTextoSec, _cargarTerminos)
                  : _terminosFiltrados.isEmpty
                      ? _vacioCentered(
                          'No hay términos en el glosario', colorTextoSec)
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _terminosFiltrados.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _cardTermino(
                            _terminosFiltrados[i],
                            colorFondo,
                            colorBorde,
                            colorTexto,
                            colorTextoSec,
                          ),
                        ),
        ),
      ],
    );
  }

  // ── Card Sugerencia ────────────────────────────────────────
  Widget _cardSugerencia(
    Map<String, dynamic> s,
    Color colorFondo,
    Color colorBorde,
    Color colorTexto,
    Color colorTextoSec,
  ) {
    final nombre = s['termino_sugerido'] as String? ?? '';
    final desc = s['descripcion'] as String? ?? '';
    final estado = s['estado'] as String? ?? 'pendiente';
    final creadoEn = s['creado_en'] as String?;
    final aprobadoPor = s['aprobado_por'] as String?;
    final estadoNorm = estado.trim().toLowerCase();
    final isPendiente = estadoNorm == 'pendiente';
    final isAprobada = estadoNorm == 'aprobada';

    Color estadoColor;
    String estadoLabel;
    switch (estado) {
      case 'aprobada':
        estadoColor = Colors.green.shade600;
        estadoLabel = 'Aprobada';
        break;
      case 'rechazada':
        estadoColor = Colors.red.shade400;
        estadoLabel = 'Rechazada';
        break;
      default:
        estadoColor = Colors.orange.shade600;
        estadoLabel = 'Pendiente';
    }

    return Container(
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorBorde),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(nombre,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorTexto)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(estadoLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: estadoColor)),
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc,
                style: TextStyle(fontSize: 13, color: colorTextoSec),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          if (creadoEn != null) ...[
            const SizedBox(height: 6),
            Text(_formatFecha(creadoEn),
                style: TextStyle(fontSize: 11, color: colorTextoSec)),
          ],
          if (aprobadoPor != null && !isPendiente) ...[
            const SizedBox(height: 4),
            Text('Procesado por: $aprobadoPor',
                style: TextStyle(fontSize: 11, color: colorTextoSec)),
          ],
          if (isPendiente) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rechazar(s),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: const Text('Rechazar',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _aprobar(s),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: const Text('Aprobar',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
          if (isAprobada) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirEditorTermino(s),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Editar',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _quitarDelGlosario(s),
                    icon:
                        const Icon(Icons.visibility_off_outlined, size: 16),
                    label: const Text('Quitar',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Card Término ───────────────────────────────────────────
  Widget _cardTermino(
    Map<String, dynamic> t,
    Color colorFondo,
    Color colorBorde,
    Color colorTexto,
    Color colorTextoSec,
  ) {
    final nombre = t['nombretermino'] as String? ?? '';
    final categoria = t['categoria'] as String? ?? '';
    final vistas = (t['vistas'] as num?)?.toInt() ?? 0;
    final tieneImagen = (t['imagen_url'] as String?) != null ||
        (t['imagen_url_ejemplo'] as String?) != null;

    return Container(
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorBorde),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(nombre,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorTexto)),
              ),
              if (tieneImagen) ...[
                Icon(Icons.image_outlined, size: 16, color: colorTextoSec),
                const SizedBox(width: 6),
              ],
              if (categoria.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorBorde,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(categoria,
                      style:
                          TextStyle(fontSize: 11, color: colorTextoSec)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$vistas vistas',
              style: TextStyle(fontSize: 11, color: colorTextoSec)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editarTerminoDirecto(t),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _eliminarTermino(t),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Eliminar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFecha(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _errorWidget(
      String msg, Color colorTextoSec, VoidCallback onReintentar) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined, size: 40, color: colorTextoSec),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorTextoSec)),
            const SizedBox(height: 16),
            TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _vacioCentered(String msg, Color colorTextoSec) {
    return Center(
      child: Text(msg, style: TextStyle(color: colorTextoSec, fontSize: 14)),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Bottom Sheet — Editar término en el glosario global
// ════════════════════════════════════════════════════════════
class _BottomSheetEditarTermino extends StatefulWidget {
  final Map<String, dynamic> termino;
  const _BottomSheetEditarTermino({required this.termino});

  @override
  State<_BottomSheetEditarTermino> createState() =>
      _BottomSheetEditarTerminoState();
}

class _BottomSheetEditarTerminoState
    extends State<_BottomSheetEditarTermino> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _defCtrl;
  late final TextEditingController _ejemploCtrl;
  late final TextEditingController _imgDefCtrl;
  late final TextEditingController _imgEjCtrl;
  String? _categoria;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(
        text: widget.termino['nombretermino'] as String? ?? '');
    _defCtrl = TextEditingController(
        text: widget.termino['definicion'] as String? ?? '');
    _ejemploCtrl = TextEditingController(
        text: widget.termino['ejemplo'] as String? ?? '');
    _imgDefCtrl = TextEditingController(
        text: widget.termino['imagen_url'] as String? ?? '');
    _imgEjCtrl = TextEditingController(
        text: widget.termino['imagen_url_ejemplo'] as String? ?? '');
    _categoria = widget.termino['categoria'] as String?;
    if (_categoria != null && !_categoriasGlosario.contains(_categoria)) {
      _categoria = null;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _defCtrl.dispose();
    _ejemploCtrl.dispose();
    _imgDefCtrl.dispose();
    _imgEjCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final imgDef = _imgDefCtrl.text.trim();
      final imgEj = _imgEjCtrl.text.trim();
      await SupabaseConexion.client.from('terminos').update({
        'nombretermino': _nombreCtrl.text.trim(),
        'definicion': _defCtrl.text.trim(),
        'ejemplo': _ejemploCtrl.text.trim(),
        if (_categoria != null) 'categoria': _categoria,
        'imagen_url': imgDef.isEmpty ? null : imgDef,
        'imagen_url_ejemplo': imgEj.isEmpty ? null : imgEj,
      }).eq('id', widget.termino['id']);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar los cambios')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSheet = isDark ? const Color(0xFF212121) : Colors.white;
    final colorEtiqueta =
        isDark ? const Color(0xFFAAAAAA) : const Color(0xFF374151);
    final colorTitulo =
        isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827);

    return Container(
      decoration: BoxDecoration(
        color: bgSheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF717171)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Editar término del glosario',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: colorTitulo)),
              const SizedBox(height: 20),
              _label('Nombre', colorEtiqueta),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nombreCtrl,
                decoration:
                    const InputDecoration(hintText: 'Nombre del término'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),
              _label('Definición', colorEtiqueta),
              const SizedBox(height: 6),
              TextFormField(
                controller: _defCtrl,
                maxLines: 4,
                decoration:
                    const InputDecoration(hintText: 'Definición del término'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),
              _label('Ejemplo (opcional)', colorEtiqueta),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ejemploCtrl,
                maxLines: 2,
                decoration:
                    const InputDecoration(hintText: 'Ejemplo de uso'),
              ),
              const SizedBox(height: 16),
              _label('Categoría', colorEtiqueta),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration:
                    const InputDecoration(hintText: 'Selecciona categoría'),
                items: _categoriasGlosario
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v),
              ),
              const SizedBox(height: 16),
              _label('Imagen definición (URL, opcional)', colorEtiqueta),
              const SizedBox(height: 6),
              TextFormField(
                controller: _imgDefCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(hintText: 'https://...'),
              ),
              const SizedBox(height: 16),
              _label('Imagen ejemplo (URL, opcional)', colorEtiqueta),
              const SizedBox(height: 6),
              TextFormField(
                controller: _imgEjCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(hintText: 'https://...'),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String texto, Color color) => Text(texto,
      style:
          TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color));
}

// ════════════════════════════════════════════════════════════
// Bottom Sheet — Crear término nuevo en el glosario global
// ════════════════════════════════════════════════════════════
class _BottomSheetCrearTermino extends StatefulWidget {
  const _BottomSheetCrearTermino();

  @override
  State<_BottomSheetCrearTermino> createState() =>
      _BottomSheetCrearTerminoState();
}

class _BottomSheetCrearTerminoState extends State<_BottomSheetCrearTermino> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _defCtrl = TextEditingController();
  final _ejemploCtrl = TextEditingController();
  final _imgDefCtrl = TextEditingController();
  final _imgEjCtrl = TextEditingController();
  String? _categoria;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _defCtrl.dispose();
    _ejemploCtrl.dispose();
    _imgDefCtrl.dispose();
    _imgEjCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await Glosario.crearTermino(
        nombre: _nombreCtrl.text.trim(),
        definicion: _defCtrl.text.trim(),
        ejemplo: _ejemploCtrl.text.trim(),
        categoria: _categoria,
        imagenUrl:
            _imgDefCtrl.text.trim().isEmpty ? null : _imgDefCtrl.text.trim(),
        imagenUrlEjemplo:
            _imgEjCtrl.text.trim().isEmpty ? null : _imgEjCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear el término')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSheet = isDark ? const Color(0xFF212121) : Colors.white;
    final colorEtiqueta =
        isDark ? const Color(0xFFAAAAAA) : const Color(0xFF374151);
    final colorTitulo =
        isDark ? const Color(0xFFF1F1F1) : const Color(0xFF111827);

    return Container(
      decoration: BoxDecoration(
        color: bgSheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF717171)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Nuevo término',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: colorTitulo)),
              const SizedBox(height: 20),
              _label('Nombre', colorEtiqueta),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nombreCtrl,
                decoration:
                    const InputDecoration(hintText: 'Nombre del término'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),
              _label('Definición', colorEtiqueta),
              const SizedBox(height: 6),
              TextFormField(
                controller: _defCtrl,
                maxLines: 4,
                decoration:
                    const InputDecoration(hintText: 'Definición del término'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),
              _label('Ejemplo (opcional)', colorEtiqueta),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ejemploCtrl,
                maxLines: 2,
                decoration:
                    const InputDecoration(hintText: 'Ejemplo de uso'),
              ),
              const SizedBox(height: 16),
              _label('Categoría', colorEtiqueta),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                decoration:
                    const InputDecoration(hintText: 'Selecciona categoría'),
                items: _categoriasGlosario
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v),
              ),
              const SizedBox(height: 16),
              _label('Imagen definición (URL, opcional)', colorEtiqueta),
              const SizedBox(height: 6),
              TextFormField(
                controller: _imgDefCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(hintText: 'https://...'),
              ),
              const SizedBox(height: 16),
              _label('Imagen ejemplo (URL, opcional)', colorEtiqueta),
              const SizedBox(height: 6),
              TextFormField(
                controller: _imgEjCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(hintText: 'https://...'),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Crear término'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String texto, Color color) => Text(texto,
      style:
          TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color));
}
