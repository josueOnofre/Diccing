import 'package:flutter/widgets.dart';
import 'package:flutter_application/logica/info_dispositivo.dart';

class ProveedorDispositivo extends InheritedWidget {
  const ProveedorDispositivo({
    super.key,
    required this.dispositivo,
    required super.child,
  });

  final InfoDispositivo dispositivo;

  static InfoDispositivo of(BuildContext context) {
    final ProveedorDispositivo? proveedor =
        context.dependOnInheritedWidgetOfExactType<ProveedorDispositivo>();
    assert(
      proveedor != null,
      'No encontrado en el árbol de widgets',
    );
    return proveedor!.dispositivo;
  }

  @override
  bool updateShouldNotify(ProveedorDispositivo oldWidget) =>
      dispositivo.id != oldWidget.dispositivo.id ||
      dispositivo.codigo != oldWidget.dispositivo.codigo;
}