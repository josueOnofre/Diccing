import 'package:flutter/material.dart';
import '../logica/glosario.dart';
import '../provider/dispositivo_provider.dart';

class PantallaSugerir extends StatefulWidget {
  const PantallaSugerir({super.key});

  @override
  State<PantallaSugerir> createState() => _PantallaSugerirState();
}

class _PantallaSugerirState extends State<PantallaSugerir> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ctrlNombre = TextEditingController();
  final TextEditingController _ctrlDescripcion = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _ctrlNombre.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrlNombre.dispose();
    _ctrlDescripcion.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    final dispositivo = ProveedorDispositivo.of(context);
    final ok = await Glosario.guardarSugerencia(
      palabra: _ctrlNombre.text.trim(),
      idDispositivo: dispositivo.id,
      descripcion: _ctrlDescripcion.text.trim(),
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (ok) {
      _ctrlNombre.clear();
      _ctrlDescripcion.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sugerencia enviada')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar la sugerencia')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = isDark ? const Color(0xFFF1F1F1) : const Color(0xFF374151);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugerir término'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF212121) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  'Si conoces un término que no está en Diccing, sugiérelo a continuación.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF4B5563),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Término',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorTexto,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ctrlNombre,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'Ej. Inteligencia Artificial',
                  counterText: '${_ctrlNombre.text.length}/100',
                  counterStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Escribe un término';
                  }
                  if (v.trim().length < 2) {
                    return 'El término es demasiado corto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Descripción (opcional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorTexto,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ctrlDescripcion,
                maxLength: 300,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Breve contexto o significado del término',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviar,
                  child: _enviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Enviar sugerencia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
