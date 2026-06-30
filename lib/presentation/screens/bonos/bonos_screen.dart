import 'package:bosque_flutter/core/state/bono_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/presentation/widgets/bonos/bonos_app_bar.dart';
import 'package:bosque_flutter/presentation/widgets/bonos/bonos_filter_bar.dart';
import 'package:bosque_flutter/presentation/widgets/bonos/bonos_desktop_view.dart';
import 'package:bosque_flutter/presentation/widgets/bonos/bonos_mobile_view.dart';

const int _maxGestiones = 5;
const int _anioBase = 2026;

class BonosScreen extends ConsumerStatefulWidget {
  const BonosScreen({super.key});

  @override
  ConsumerState<BonosScreen> createState() => _BonosScreenState();
}

class _BonosScreenState extends ConsumerState<BonosScreen> {
  late final List<String> _anios;

  @override
  void initState() {
    super.initState();
    final int anioActual = DateTime.now().year;
    int anioInicio = anioActual - _maxGestiones + 1;
    if (anioInicio < _anioBase) anioInicio = _anioBase;

    final int count = (anioActual - anioInicio + 1).clamp(1, _maxGestiones);
    _anios = List.generate(count, (i) => (anioActual - i).toString());
  }

  int get _uid => ref.read(userProvider)?.codUsuario ?? 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<BonoState>(bonoProvider, (prev, next) {
      if (!mounted) return;
      if (prev?.mensajeExito != next.mensajeExito &&
          next.mensajeExito != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.mensajeExito!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (prev?.mensajeError != next.mensajeError &&
          next.mensajeError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.mensajeError!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final st = ref.watch(bonoProvider);
    final ntf = ref.read(bonoProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.15),
      appBar: BonosAppBar(st: st, ntf: ntf),
      body: Column(
        children: [
          BonosFilterBar(st: st, ntf: ntf, anios: _anios, uid: _uid),
          Expanded(
            child:
                isDesktop
                    ? BonosDesktopView(st: st, ntf: ntf)
                    : BonosMobileView(st: st, ntf: ntf),
          ),
        ],
      ),
    );
  }
}
