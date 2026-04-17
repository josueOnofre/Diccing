class Termino {
  final int idTermino;
  final String nombreTermino;
  final String definicion;
  final String ejemplo;
  final String? imagenUrl;
  final String? imagenUrlEjemplo;
  final String? categoria;
  final int vistas;

  Termino({
    required this.idTermino,
    required this.nombreTermino,
    required this.definicion,
    required this.ejemplo,
    this.imagenUrl,
    this.imagenUrlEjemplo,
    this.categoria,
    this.vistas = 0,
  });

  factory Termino.fromJson(Map<String, dynamic> json) {
    return Termino(
      idTermino: (json['id'] as num?)?.toInt() ?? 0,
      nombreTermino: (json['nombretermino'] ?? '') as String,
      definicion: (json['definicion'] ?? '') as String,
      ejemplo: (json['ejemplo'] ?? '') as String,
      imagenUrl: json['imagen_url'] as String?,
      imagenUrlEjemplo: json['imagen_url_ejemplo'] as String?,
      categoria: json['categoria'] as String?,
      vistas: (json['vistas'] as num?)?.toInt() ?? 0,
    );
  }
}
