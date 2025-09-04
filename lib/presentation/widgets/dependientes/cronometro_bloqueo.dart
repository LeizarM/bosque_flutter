import 'dart:async';
import 'package:flutter/material.dart';

class CronometroBloqueo extends StatefulWidget {
  final DateTime fechaLimite;
  final bool estaBloqueado;
  final Future<void> Function()? onFinalizado;

  const CronometroBloqueo({
    Key? key,
    required this.fechaLimite,
    required this.estaBloqueado,
    this.onFinalizado,
  }) : super(key: key);

  @override
  State<CronometroBloqueo> createState() => _CronometroBloqueoState();
}

class _CronometroBloqueoState extends State<CronometroBloqueo> {
  late Duration _restante;
  Timer? _timer;
bool _finalizado = false;
  @override
  void initState() {
    super.initState();
    _restante = widget.fechaLimite.difference(DateTime.now());
    if (!widget.estaBloqueado) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final nuevaRestante = widget.fechaLimite.difference(DateTime.now());
        if ((nuevaRestante.isNegative || nuevaRestante == Duration.zero) && !_finalizado) {
          _finalizado = true;
          _timer?.cancel();
          if (widget.onFinalizado != null) {
            widget.onFinalizado!();
          }
          setState(() => _restante = Duration.zero);
        } else {
          setState(() => _restante = nuevaRestante);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatearDuracion(Duration d) {
    final horas = d.inHours;
    final minutos = d.inMinutes.remainder(60);
    final segundos = d.inSeconds.remainder(60);
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.estaBloqueado) {
      return const Text(
        'Usuario bloqueado',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }
    if (_restante.isNegative || _restante == Duration.zero) {
      return const Text(
        'Tiempo agotado',
        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
      );
    }
    final isMobile = MediaQuery.of(context).size.width < 400;

  if (isMobile) {
    // Diseño vertical para móvil
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timer, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              _formatearDuracion(_restante),
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Debe actualizar sus datos o se bloqueará su usuario.',
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          maxLines: 3,
        ),
      ],
    );
  }
    return Row(
      children: [
        const Icon(Icons.timer, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          'Debe actualizar sus datos o se bloqueará su usuario en: ${_formatearDuracion(_restante)}',
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          maxLines: 3,
        ),
      ],
    );
  }
}