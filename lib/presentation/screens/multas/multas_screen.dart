import 'dart:async';
import 'package:bosque_flutter/core/state/multa_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/presentation/widgets/multas/multas_constants.dart';
import 'package:bosque_flutter/presentation/widgets/multas/multas_app_bar.dart';
import 'package:bosque_flutter/presentation/widgets/multas/multas_filter_bar.dart';
import 'package:bosque_flutter/presentation/widgets/multas/multas_desktop_view.dart';
import 'package:bosque_flutter/presentation/widgets/multas/multas_mobile_view.dart';

export 'package:bosque_flutter/presentation/widgets/multas/multas_constants.dart'
    show codEmpresaMultasProvider;

class MultasScreen extends ConsumerStatefulWidget {
  const MultasScreen({super.key});
  @override
  ConsumerState<MultasScreen> createState() => _MultasScreenState();
}

class _MultasScreenState extends ConsumerState<MultasScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _searchTimer;
  late final List<String> _anios;

  @override
  void initState() {
    super.initState();
    final int anioActual = DateTime.now().year;
    int anioInicio = anioActual - maxGestiones + 1;
    if (anioInicio < anioBase) anioInicio = anioBase;
    final int count = (anioActual - anioInicio + 1).clamp(1, maxGestiones);
    _anios = List.generate(count, (i) => (anioActual - i).toString());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  int get _uid => ref.read(userProvider)?.codUsuario ?? 0;

  void _onSearch(String q) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 380), () {
      final emp = ref.read(codEmpresaMultasProvider);
      ref.read(multaProvider(emp).notifier).buscar(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final emp = ref.watch(codEmpresaMultasProvider);

    ref.listen<MultaState>(multaProvider(emp), (prev, next) {
      if (!mounted) return;
      if (next.search.isEmpty && _searchCtrl.text.isNotEmpty) {
        _searchCtrl.clear();
      }
      if (prev?.mensajeExito != next.mensajeExito &&
          next.mensajeExito != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.mensajeExito!),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (prev?.mensajeError != next.mensajeError &&
          next.mensajeError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.mensajeError!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final st = ref.watch(multaProvider(emp));
    final ntf = ref.read(multaProvider(emp).notifier);
    final cs = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Scaffold(
      backgroundColor: cs.surfaceVariant.withOpacity(0.15),
      appBar: MultasAppBar(st: st, ntf: ntf, uid: _uid),
      body: Column(
        children: [
          MultasFilterBar(
            st: st,
            ntf: ntf,
            searchCtrl: _searchCtrl,
            onSearch: _onSearch,
            anios: _anios,
            uid: _uid, // AGREGADO
          ),
          Expanded(
            child:
                isDesktop
                    ? MultasDesktopView(st: st, ntf: ntf, uid: _uid)
                    : MultasMobileView(st: st, ntf: ntf, uid: _uid),
          ),
        ],
      ),
    );
  }
}
