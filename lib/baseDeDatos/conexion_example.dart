import 'package:supabase_flutter/supabase_flutter.dart';

// Copia este archivo como "conexion.dart" y rellena tus credenciales.
// NUNCA subas conexion.dart al repositorio (está en .gitignore).
class SupabaseConexion {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'TU_SUPABASE_URL',
      anonKey: 'TU_SUPABASE_ANON_KEY',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
