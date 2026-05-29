// ─────────────────────────────────────────────────────────────
// DiccionarioPersonal — CRUD para la tabla terminos_personales
//
// SQL necesario en Supabase (ejecutar una sola vez):
// ─────────────────────────────────────────────────────────────
// CREATE TABLE IF NOT EXISTS terminos_personales (
//   id             BIGSERIAL PRIMARY KEY,
//   user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
//   nombre         TEXT NOT NULL,
//   definicion     TEXT NOT NULL,
//   categoria      TEXT,
//   creado_en      TIMESTAMPTZ DEFAULT NOW(),
//   actualizado_en TIMESTAMPTZ DEFAULT NOW()
// );
// ALTER TABLE terminos_personales ENABLE ROW LEVEL SECURITY;
// CREATE POLICY "select_own" ON terminos_personales FOR SELECT  USING (auth.uid() = user_id);
// CREATE POLICY "insert_own" ON terminos_personales FOR INSERT  WITH CHECK (auth.uid() = user_id);
// CREATE POLICY "update_own" ON terminos_personales FOR UPDATE  USING (auth.uid() = user_id);
// CREATE POLICY "delete_own" ON terminos_personales FOR DELETE  USING (auth.uid() = user_id);
// ─────────────────────────────────────────────────────────────

import '../baseDeDatos/conexion.dart';
import 'termino_personal.dart';

class DiccionarioPersonal {
  static const _tabla = 'terminos_personales';

  static Future<List<TerminoPersonal>> obtenerMios(String userId) async {
    try {
      final resp = await SupabaseConexion.client
          .from(_tabla)
          .select()
          .eq('user_id', userId)
          .order('creado_en', ascending: false);

      return (resp as List)
          .map((e) => TerminoPersonal.fromJson(e))
          .toList();
    } catch (_) {
      rethrow;
    }
  }

  static Future<TerminoPersonal?> crear(TerminoPersonal t) async {
    try {
      final resp = await SupabaseConexion.client
          .from(_tabla)
          .insert(t.toInsertJson())
          .select()
          .single();
      return TerminoPersonal.fromJson(resp);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> actualizar(TerminoPersonal t) async {
    if (t.id == null) return false;
    try {
      await SupabaseConexion.client
          .from(_tabla)
          .update(t.toUpdateJson())
          .eq('id', t.id!);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> eliminar(int id) async {
    try {
      await SupabaseConexion.client.from(_tabla).delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
