import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// AuthService
// Gestiona sesión Google-OAuth vía Supabase.
//
// SETUP REQUERIDO (Supabase Console):
//   1. Authentication → Providers → Google → Enable
//   2. Client ID:     (web client_id de Google Cloud)
//   3. Client Secret: (client_secret de Google Cloud)
//   4. Redirect URL:  flvnbscjemvozslarxnc://login-callback/
//      (copiar esta URL exacta al "Authorized redirect URIs" en Google Cloud)
// ─────────────────────────────────────────────────────────────

class AuthService {
  AuthService._();

  static final SupabaseClient _sb = Supabase.instance.client;

  static final ValueNotifier<User?> usuario = ValueNotifier(
    _sb.auth.currentUser,
  );

  static StreamSubscription<AuthState>? _suscripcion;

  static void init() {
    _suscripcion = _sb.auth.onAuthStateChange.listen((data) {
      usuario.value = data.session?.user;
    });
  }

  static void dispose() {
    _suscripcion?.cancel();
  }

  static bool get estaAutenticado => usuario.value != null;

  static String? get nombreUsuario =>
      usuario.value?.userMetadata?['full_name'] as String? ??
      usuario.value?.userMetadata?['name'] as String?;

  static String? get emailUsuario => usuario.value?.email;

  static String? get avatarUrl =>
      usuario.value?.userMetadata?['avatar_url'] as String?;

  static bool get esAdmin =>
      usuario.value?.appMetadata['role'] == 'admin';

  static Future<void> iniciarSesionConGoogle() async {
    await _sb.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'diccing://login-callback/',
    );
  }

  static Future<void> cerrarSesion() async {
    await _sb.auth.signOut();
  }
}
