import 'package:flutter/material.dart';

/// Notificador global que se incrementa cada vez que los favoritos cambian.
/// Las pantallas que muestran favoritos escuchan este notificador y se refrescan.
class FavoritosNotificador {
  static final ValueNotifier<int> notificador = ValueNotifier<int>(0);

  /// Llamar a esto cada vez que se agrega o quita un favorito.
  static void notificar() {
    notificador.value++;
  }
}

/// Notificador global para cambios en historial.
class HistorialNotificador {
  static final ValueNotifier<int> notificador = ValueNotifier<int>(0);

  static void notificar() {
    notificador.value++;
  }
}
