class Sugerencia {
  final int idSugerencia;
  final String terminoSugerido;
  final String? descripcion;
  final int dispositivoId;
  final DateTime fechaCreacion;

  Sugerencia({
    required this.idSugerencia,
    required this.terminoSugerido,
    this.descripcion,
    required this.dispositivoId,
    required this.fechaCreacion,
  });

  factory Sugerencia.fromJson(Map<String, dynamic> json) {
    return Sugerencia(
      idSugerencia: (json['id'] as num).toInt(),
      terminoSugerido: json['termino_sugerido'] as String,
      descripcion: json['descripcion'] as String?,
      dispositivoId: (json['dispositivo_id'] as num).toInt(),
      fechaCreacion: DateTime.parse(json['creado_en'] as String),
    );
  }
}
