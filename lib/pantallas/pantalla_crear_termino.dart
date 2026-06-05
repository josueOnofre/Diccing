import 'package:flutter/material.dart';
import '../logica/diccionario_personal.dart';
import '../logica/termino_personal.dart';
import '../services/auth_service.dart';
import '../widgets/notificacion.dart';

class PantallaCrearTermino extends StatefulWidget {
  final TerminoPersonal? terminoAEditar;

  const PantallaCrearTermino({super.key, this.terminoAEditar});

  @override
  State<PantallaCrearTermino> createState() => _PantallaCrearTerminoState();
}

class _PantallaCrearTerminoState extends State<PantallaCrearTermino> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _definicionController = TextEditingController();
  String? _categoriaSeleccionada;
  bool _guardando = false;

  bool get _esEdicion => widget.terminoAEditar != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreController.text = widget.terminoAEditar!.nombre;
      _definicionController.text = widget.terminoAEditar!.definicion;
      _categoriaSeleccionada = widget.terminoAEditar!.categoria;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _definicionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = AuthService.usuario.value?.id;
    if (userId == null) {
      mostrarNotificacion(context, 'Debes iniciar sesión para guardar términos.', esError: true);
      return;
    }

    setState(() => _guardando = true);

    bool exito;
    if (_esEdicion) {
      final actualizado = widget.terminoAEditar!.copyWith(
        nombre: _nombreController.text.trim(),
        definicion: _definicionController.text.trim(),
        categoria: _categoriaSeleccionada,
      );
      exito = await DiccionarioPersonal.actualizar(actualizado);
    } else {
      final nuevo = TerminoPersonal(
        userId: userId,
        nombre: _nombreController.text.trim(),
        definicion: _definicionController.text.trim(),
        categoria: _categoriaSeleccionada,
      );
      final creado = await DiccionarioPersonal.crear(nuevo);
      exito = creado != null;
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    if (exito) {
      mostrarNotificacion(context, _esEdicion ? 'Término actualizado exitosamente' : 'Término guardado exitosamente');
      Navigator.pop(context, true);
    } else {
      mostrarNotificacion(context, 'No se pudo guardar. Verifica tu conexión.', esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorEtiqueta = isDark ? const Color(0xFFAAAAAA) : const Color(0xFF374151);

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Término' : 'Nuevo Término Personal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _esEdicion
                      ? 'Actualiza los datos de tu término personal.'
                      : 'Crea una definición propia para agregarla a tu diccionario personal.',
                  style: TextStyle(color: colorEtiqueta, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // ── Nombre ────────────────────────────
                Text(
                  'Nombre del término *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorEtiqueta,
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nombreController,
                  builder: (_, val, __) => TextFormField(
                    controller: _nombreController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: 'Ej: API, Servidor, Caché...',
                      counterText: '${val.text.length}/100',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El nombre es obligatorio'
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Definición ────────────────────────
                Text(
                  'Definición *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorEtiqueta,
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _definicionController,
                  builder: (_, val, __) => TextFormField(
                    controller: _definicionController,
                    maxLength: 500,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu definición aquí...',
                      counterText: '${val.text.length}/500',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'La definición es obligatoria'
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Categoría ─────────────────────────
                Text(
                  'Categoría (opcional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorEtiqueta,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _categoriaSeleccionada,
                  decoration: InputDecoration(
                    hintText: 'Selecciona una categoría',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  icon: const Icon(Icons.arrow_drop_down_rounded, size: 28),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('— Sin categoría —'),
                    ),
                    ...categoriasPersonales.map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _categoriaSeleccionada = val),
                ),
                const SizedBox(height: 32),

                // ── Guardar ───────────────────────────
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _esEdicion ? 'Actualizar Término' : 'Guardar Término',
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
