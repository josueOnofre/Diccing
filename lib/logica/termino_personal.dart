class TerminoPersonal {
  final int? id;
  final String userId;
  final String nombre;
  final String definicion;
  final String? categoria;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const TerminoPersonal({
    this.id,
    required this.userId,
    required this.nombre,
    required this.definicion,
    this.categoria,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory TerminoPersonal.fromJson(Map<String, dynamic> json) {
    return TerminoPersonal(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      definicion: json['definicion'] as String? ?? '',
      categoria: json['categoria'] as String?,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
      actualizadoEn: json['actualizado_en'] != null
          ? DateTime.parse(json['actualizado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'nombre': nombre,
        'definicion': definicion,
        if (categoria != null && categoria!.isNotEmpty) 'categoria': categoria,
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      };

  Map<String, dynamic> toUpdateJson() => {
        'nombre': nombre,
        'definicion': definicion,
        'categoria': (categoria != null && categoria!.isNotEmpty) ? categoria : null,
        'actualizado_en': DateTime.now().toIso8601String(),
      };

  TerminoPersonal copyWith({
    int? id,
    String? userId,
    String? nombre,
    String? definicion,
    String? categoria,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return TerminoPersonal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      definicion: definicion ?? this.definicion,
      categoria: categoria ?? this.categoria,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}

const List<String> categoriasPersonales = [
  'Programación',
  'Redes',
  'Bases de Datos',
  'Hardware',
  'Software',
  'Seguridad',
  'Inteligencia Artificial',
  'Web',
  'Sistemas Operativos',
  'Otro',
];
