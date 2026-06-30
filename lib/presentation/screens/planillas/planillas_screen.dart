import 'package:bosque_flutter/core/state/planilla_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/presentation/widgets/planillas/planillas_app_bar.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_filter_bar.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_desktop_view.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_mobile_view.dart';

const int _maxGestiones = 5;
const int _anioBase = 2026;

class PlanillasScreen extends ConsumerStatefulWidget {
  const PlanillasScreen({super.key});

  @override
  ConsumerState<PlanillasScreen> createState() => _PlanillasScreenState();
}

class _PlanillasScreenState extends ConsumerState<PlanillasScreen> {
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
    ref.listen<PlanillaState>(planillaProvider, (prev, next) {
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

    final st = ref.watch(planillaProvider);
    final ntf = ref.read(planillaProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.15),
      appBar: PlanillasAppBar(st: st, ntf: ntf),
      body: Column(
        children: [
          PlanillasFilterBar(st: st, ntf: ntf, anios: _anios, uid: _uid),
          Expanded(
            child:
                isDesktop
                    ? PlanillasDesktopView(st: st, ntf: ntf)
                    : PlanillasMobileView(st: st, ntf: ntf),
          ),
        ],
      ),
    );
  }
}
