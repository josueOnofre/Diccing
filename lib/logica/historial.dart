import 'termino.dart';

class Historial {
  final int idHistorial;
  final int terminoId;
  final int dispositivoId;
  final DateTime fechaConsulta;

  Historial({
    required this.idHistorial,
    required this.terminoId,
    required this.dispositivoId,
    required this.fechaConsulta,
  });

  factory Historial.fromJson(Map<String, dynamic> json) {
    return Historial(
      idHistorial: (json['id'] as num).toInt(),
      terminoId: (json['termino_id'] as num).toInt(),
      dispositivoId: (json['dispositivo_id'] as num).toInt(),
      fechaConsulta: DateTime.parse(json['visto_en'] as String),
    );
  }
}

/// Item de historial: combina el Termino consultado con la fecha y el id del registro.
class HistorialItem {
  final int idHistorial;
  final Termino termino;
  final DateTime fechaConsulta;

  HistorialItem({
    required this.idHistorial,
    required this.termino,
    required this.fechaConsulta,
  });
}
