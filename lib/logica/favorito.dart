


class Favorito {
  final int idFavorito; 
  final int terminoId; 
  final int dispositivoId; 
  final DateTime fechaGuardado;

  Favorito({
    required this.idFavorito, 
    required this.terminoId,
    required this.dispositivoId,
    required this.fechaGuardado,
  });

  factory Favorito.fromJson(Map<String, dynamic> json) {
    return Favorito(
      idFavorito: json['id'],
      terminoId: json['termino_id'],
      dispositivoId: json['dispositivo_id'],
      fechaGuardado: DateTime.parse(json['creado_en']), 
    );
  }
}

