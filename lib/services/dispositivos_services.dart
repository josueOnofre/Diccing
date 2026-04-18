import 'dart:math';


import 'package:flutter_application/logica/info_dispositivo.dart';
import 'package:persistent_device_id/persistent_device_id.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



class DispositivoService {
  const DispositivoService(this._cliente);

  final SupabaseClient _cliente;
  static const String _prefsId = 'dispositivo_id';
  static const String _prefsCodigo = 'dispositivo_codigo';

  Future<InfoDispositivo> obtenerORegistrar() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? idCacheado = prefs.getInt(_prefsId);
    final String? codigoCacheado = prefs.getString(_prefsCodigo);

    if (idCacheado != null && codigoCacheado != null) {
      return InfoDispositivo(id: idCacheado, codigo: codigoCacheado);
    }

    final String codigoGenerado = await _obtenerCodigoDispositivo();

    final Map<String, dynamic>? existente = await _cliente
        .from('dispositivos')
        .select()
        .eq('codigo_dispositivo', codigoGenerado)
        .maybeSingle();

    Map<String, dynamic> registro = existente ?? <String, dynamic>{};

    if (existente == null) {
      registro = await _cliente
          .from('dispositivos')
          .insert(<String, dynamic>{
            'codigo_dispositivo': codigoGenerado,
          })
          .select()
          .single();
    }

    final int id = _convertirEntero(registro['id']);

    await prefs.setInt(_prefsId, id);
    await prefs.setString(_prefsCodigo, codigoGenerado);

    return InfoDispositivo(id: id, codigo: codigoGenerado);
  }

  Future<String> _obtenerCodigoDispositivo() async {
    try {
      final String? idPersistente = await PersistentDeviceId.getDeviceId();
      if (idPersistente != null && idPersistente.isNotEmpty) {
        return idPersistente;
      }
    } catch (_) {}
    final Random r = Random();
    final int sufijo = r.nextInt(999999999);
    // final int sufijo = r.nextInt(1 << 32);
    return 'dispositivo-${DateTime.now().millisecondsSinceEpoch}-$sufijo';
  }

  int _convertirEntero(dynamic valor) {
    if (valor is int) {
      return valor;
    }
    if (valor is String) {
      return int.tryParse(valor) ?? 0;
    }
    throw ArgumentError('No se pudo convertir el valor "$valor" a entero.');
  }
}