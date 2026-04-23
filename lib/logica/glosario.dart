import '../baseDeDatos/conexion.dart';
import '../services/auth_service.dart';
import 'termino.dart';
import 'sugerencia.dart';
import 'historial.dart';

class Glosario {
  static const String _tabla = 'terminos';
  static const String _tablaFavoritos = 'favoritos';
  static const String _tablaHistorial = 'historial';
  static const String _tablaSugerencias = 'sugerencias';

  static const String _colsTermino =
      'id, nombretermino, definicion, ejemplo, imagen_url, imagen_url_ejemplo, categoria, vistas';

  // ── Helper: user_id activo si hay sesión Google ─────────────
  static String? get _userId => AuthService.usuario.value?.id;

  // =====================================================
  // LECTURA DE TERMINOS
  // =====================================================

  static Future<List<String>> obtenerTodosLosNombres() async {
    try {
      final response = await SupabaseConexion.client
          .from(_tabla)
          .select('nombretermino')
          .order('nombretermino', ascending: true);
      return (response as List)
          .map((item) => item['nombretermino'] as String)
          .toList();
    } catch (_) {
      return <String>[];
    }
  }

  static Future<List<Termino>> obtenerTodosLosTerminos() async {
    try {
      final response = await SupabaseConexion.client
          .from(_tabla)
          .select(_colsTermino)
          .order('nombretermino', ascending: true);
      return (response as List)
          .map((item) => Termino.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Termino>[];
    }
  }

  static Future<Termino?> buscarTermino(String palabra) async {
    try {
      final response = await SupabaseConexion.client
          .from(_tabla)
          .select(_colsTermino)
          .ilike('nombretermino', palabra)
          .limit(1);
      if ((response as List).isEmpty) return null;
      return Termino.fromJson(response.first);
    } catch (_) {
      rethrow;
    }
  }

  static Future<List<Termino>> buscarTerminos({
    String? query,
    String? categoria,
  }) async {
    try {
      dynamic builder =
          SupabaseConexion.client.from(_tabla).select(_colsTermino);
      if (query != null && query.trim().isNotEmpty) {
        builder = builder.ilike('nombretermino', '%${query.trim()}%');
      }
      if (categoria != null && categoria.isNotEmpty) {
        builder = builder.eq('categoria', categoria);
      }
      final response = await builder.order('nombretermino', ascending: true);
      return (response as List)
          .map((item) => Termino.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      rethrow;
    }
  }

  static Future<List<Termino>> obtenerTerminosPorIds(List<int> ids) async {
    if (ids.isEmpty) return <Termino>[];
    try {
      final response = await SupabaseConexion.client
          .from(_tabla)
          .select(_colsTermino)
          .inFilter('id', ids);
      return (response as List)
          .map((item) => Termino.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Termino>[];
    }
  }

  static Future<List<Termino>> obtenerTerminosRelacionados({
    required String? categoria,
    required int idActual,
    int limite = 5,
  }) async {
    if (categoria == null || categoria.isEmpty) return <Termino>[];
    try {
      final response = await SupabaseConexion.client
          .from(_tabla)
          .select(_colsTermino)
          .eq('categoria', categoria)
          .neq('id', idActual)
          .order('nombretermino', ascending: true)
          .limit(limite);
      return (response as List)
          .map((item) => Termino.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      rethrow;
    }
  }

  static Future<Termino?> obtenerTerminoDelDia() async {
    try {
      final response = await SupabaseConexion.client
          .from(_tabla)
          .select(_colsTermino)
          .order('id', ascending: true);
      final lista = response as List;
      if (lista.isEmpty) return null;
      final ahora = DateTime.now();
      final diaAnio = ahora.difference(DateTime(ahora.year, 1, 1)).inDays;
      return Termino.fromJson(lista[diaAnio % lista.length] as Map<String, dynamic>);
    } catch (_) {
      rethrow;
    }
  }

  static Future<List<Termino>> obtenerMasConsultados({int limite = 5}) async {
    try {
      final response = await SupabaseConexion.client
          .from(_tabla)
          .select(_colsTermino)
          .order('vistas', ascending: false)
          .limit(limite);
      return (response as List)
          .map((item) => Termino.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      rethrow;
    }
  }

  static Future<void> incrementarVistas(int idTermino) async {
    try {
      await SupabaseConexion.client.rpc(
        'incrementar_vistas',
        params: <String, dynamic>{'p_id_termino': idTermino},
      );
    } catch (_) {}
  }

  // =====================================================
  // FAVORITOS  (sincroniza por user_id si está autenticado)
  // =====================================================

  static Future<bool> esFavorito(int idTermino, int idDispositivo) async {
    try {
      final uid = _userId;
      dynamic query = SupabaseConexion.client
          .from(_tablaFavoritos)
          .select('id')
          .eq('termino_id', idTermino);

      query = uid != null
          ? query.eq('user_id', uid)
          : query.eq('dispositivo_id', idDispositivo);

      final response = await query.limit(1);
      return (response as List).isNotEmpty;
    } catch (_) {
      rethrow;
    }
  }

  static Future<void> cambiarEstadoFavorito({
    required int idTermino,
    required int idDispositivo,
    required bool esFavActual,
  }) async {
    try {
      final uid = _userId;
      if (esFavActual) {
        // Eliminar
        dynamic q = SupabaseConexion.client
            .from(_tablaFavoritos)
            .delete()
            .eq('termino_id', idTermino);
        q = uid != null
            ? q.eq('user_id', uid)
            : q.eq('dispositivo_id', idDispositivo);
        await q;
      } else {
        // Insertar
        final dato = <String, dynamic>{
          'termino_id': idTermino,
          'dispositivo_id': idDispositivo,
          'creado_en': DateTime.now().toIso8601String(),
        };
        if (uid != null) dato['user_id'] = uid;
        await SupabaseConexion.client.from(_tablaFavoritos).insert(dato);
      }
    } catch (_) {}
  }

  static Future<List<Termino>> obtenerFavoritos(int dispositivoId) async {
    try {
      final uid = _userId;
      dynamic query = SupabaseConexion.client
          .from(_tablaFavoritos)
          .select('termino_id, creado_en, terminos:termino_id ($_colsTermino)');

      query = uid != null
          ? query.eq('user_id', uid)
          : query.eq('dispositivo_id', dispositivoId);

      final List<dynamic> data =
          await query.order('creado_en', ascending: false);

      return data.whereType<Map<String, dynamic>>().map((row) {
        final terminoJson = row['terminos'] as Map<String, dynamic>?;
        if (terminoJson == null) {
          return Termino.fromJson(<String, dynamic>{
            'id': row['termino_id'],
            'nombretermino': 'Término desconocido',
            'definicion': '',
          });
        }
        return Termino.fromJson(terminoJson);
      }).toList();
    } catch (_) {
      rethrow;
    }
  }

  static Future<bool> eliminarFavorito(int idTermino, int idDispositivo) async {
    try {
      final uid = _userId;
      dynamic q = SupabaseConexion.client
          .from(_tablaFavoritos)
          .delete()
          .eq('termino_id', idTermino);
      q = uid != null
          ? q.eq('user_id', uid)
          : q.eq('dispositivo_id', idDispositivo);
      await q;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> eliminarTodosLosFavoritos(int idDispositivo) async {
    try {
      final uid = _userId;
      dynamic q =
          SupabaseConexion.client.from(_tablaFavoritos).delete();
      q = uid != null
          ? q.eq('user_id', uid)
          : q.eq('dispositivo_id', idDispositivo);
      await q;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<int> contarFavoritos(int idDispositivo) async {
    try {
      final uid = _userId;
      dynamic q = SupabaseConexion.client.from(_tablaFavoritos).select('id');
      q = uid != null
          ? q.eq('user_id', uid)
          : q.eq('dispositivo_id', idDispositivo);
      final response = await q;
      return (response as List).length;
    } catch (_) {
      rethrow;
    }
  }

  // =====================================================
  // HISTORIAL  (sincroniza por user_id si está autenticado)
  // =====================================================

  static Future<void> guardarEnHistorial(
    int idTermino,
    int idDispositivo,
  ) async {
    try {
      final dato = <String, dynamic>{
        'termino_id': idTermino,
        'dispositivo_id': idDispositivo,
        'visto_en': DateTime.now().toIso8601String(),
      };
      final uid = _userId;
      if (uid != null) dato['user_id'] = uid;
      await SupabaseConexion.client.from(_tablaHistorial).insert(dato);
    } catch (_) {}
  }

  static Future<List<HistorialItem>> obtenerHistorial(int idDispositivo) async {
    try {
      final uid = _userId;
      dynamic query = SupabaseConexion.client
          .from(_tablaHistorial)
          .select('id, visto_en, terminos:termino_id ($_colsTermino)');

      query = uid != null
          ? query.eq('user_id', uid)
          : query.eq('dispositivo_id', idDispositivo);

      final resp = await query.order('visto_en', ascending: false);

      return (resp as List).whereType<Map<String, dynamic>>().map((row) {
        final terminoJson = row['terminos'] as Map<String, dynamic>?;
        final termino = terminoJson != null
            ? Termino.fromJson(terminoJson)
            : Termino.fromJson(<String, dynamic>{
                'id': 0,
                'nombretermino': 'Término desconocido',
                'definicion': '',
              });
        return HistorialItem(
          idHistorial: (row['id'] as num).toInt(),
          termino: termino,
          fechaConsulta: DateTime.parse(row['visto_en'] as String),
        );
      }).toList();
    } catch (_) {
      rethrow;
    }
  }

  static Future<int> contarHistorial(int idDispositivo) async {
    try {
      final uid = _userId;
      dynamic q = SupabaseConexion.client.from(_tablaHistorial).select('id');
      q = uid != null
          ? q.eq('user_id', uid)
          : q.eq('dispositivo_id', idDispositivo);
      final response = await q;
      return (response as List).length;
    } catch (_) {
      rethrow;
    }
  }

  static Future<void> eliminarTodoHistorial(int idDispositivo) async {
    try {
      final uid = _userId;
      dynamic q = SupabaseConexion.client.from(_tablaHistorial).delete();
      q = uid != null
          ? q.eq('user_id', uid)
          : q.eq('dispositivo_id', idDispositivo);
      await q;
    } catch (_) {}
  }

  static Future<void> eliminarDelHistorial(int idHistorial) async {
    try {
      await SupabaseConexion.client
          .from(_tablaHistorial)
          .delete()
          .eq('id', idHistorial);
    } catch (_) {}
  }

  // =====================================================
  // SUGERENCIAS
  // =====================================================

  static Future<bool> guardarSugerencia({
    required String palabra,
    required int idDispositivo,
    String? descripcion,
  }) async {
    try {
      final dato = <String, dynamic>{
        'termino_sugerido': palabra,
        'dispositivo_id': idDispositivo,
        'creado_en': DateTime.now().toIso8601String(),
      };
      if (descripcion != null && descripcion.trim().isNotEmpty) {
        dato['descripcion'] = descripcion.trim();
      }
      await SupabaseConexion.client.from(_tablaSugerencias).insert(dato);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Sugerencia>> obtenerSugerencias(int idDispositivo) async {
    try {
      final resp = await SupabaseConexion.client
          .from(_tablaSugerencias)
          .select()
          .eq('dispositivo_id', idDispositivo)
          .order('creado_en', ascending: false);
      return (resp as List)
          .map((item) => Sugerencia.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Sugerencia>[];
    }
  }

  static Future<void> eliminarTodasSugerencias(int idDispositivo) async {
    try {
      await SupabaseConexion.client
          .from(_tablaSugerencias)
          .delete()
          .eq('dispositivo_id', idDispositivo);
    } catch (_) {}
  }

  // =====================================================
  // CRUD ADMIN — TÉRMINOS GLOBALES
  // =====================================================

  static Future<void> crearTermino({
    required String nombre,
    required String definicion,
    String ejemplo = '',
    String? categoria,
    String? imagenUrl,
    String? imagenUrlEjemplo,
  }) async {
    final dato = <String, dynamic>{
      'nombretermino': nombre.trim(),
      'definicion': definicion.trim(),
      'ejemplo': ejemplo.trim(),
      'vistas': 0,
    };
    if (categoria != null && categoria.isNotEmpty) dato['categoria'] = categoria;
    if (imagenUrl != null && imagenUrl.trim().isNotEmpty) {
      dato['imagen_url'] = imagenUrl.trim();
    }
    if (imagenUrlEjemplo != null && imagenUrlEjemplo.trim().isNotEmpty) {
      dato['imagen_url_ejemplo'] = imagenUrlEjemplo.trim();
    }
    await SupabaseConexion.client.from(_tabla).insert(dato);
  }
}
