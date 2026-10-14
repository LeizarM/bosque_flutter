import 'dart:async';

import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:flutter/widgets.dart';

/// Revisa cada [intervalo] si el usuario sigue habilitado, para que un bloqueado o dado
/// de baja vuelva al login aunque no toque nada. Con la app oculta no consulta; al
/// volver a mostrarse revisa en el acto.
class VigilanciaSesion extends StatefulWidget {
  const VigilanciaSesion({
    super.key,
    required this.child,
    this.verificar = DioClient.verificarSesion,
  });

  static const Duration intervalo = Duration(minutes: 2);

  final Widget child;
  final Future<void> Function() verificar;

  @override
  State<VigilanciaSesion> createState() => _VigilanciaSesionState();
}

class _VigilanciaSesionState extends State<VigilanciaSesion> {
  late final AppLifecycleListener _ciclo;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _ciclo = AppLifecycleListener(onShow: _reanudar, onHide: () => _reloj?.cancel());
    _programar();
  }

  void _programar() {
    _reloj?.cancel();
    _reloj = Timer.periodic(VigilanciaSesion.intervalo, (_) => widget.verificar());
  }

  void _reanudar() {
    widget.verificar();
    _programar();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
