import 'dart:async';
import 'package:bosque_flutter/core/state/anticipo_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Widget imports ──────────────────────────────────────────────────────────
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_app_bar.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_filter_bar.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_desktop_view.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_mobile_view.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_modo_asignacion_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_asignacion_tigo_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_asignacion_manual_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_detalle_sheet.dart';

// Re-export para que screens.dart siga exportando BosqueFiltroDropdown
export 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_filter_bar.dart'
    show BosqueFiltroDropdown;
export 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart'
    show codEmpresaAnticiposProvider;

// ══════════════════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ══════════════════════════════════════════════════════════════════════════════
class AnticiposScreen extends ConsumerStatefulWidget {
  const AnticiposScreen({super.key});
  @override
  ConsumerState<AnticiposScreen> createState() => _AnticiposScreenState();
}

class _AnticiposScreenState extends ConsumerState<AnticiposScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _searchTimer;
  late final List<String> _anios;

  @override
  void initState() {
    super.initState();

    final int anioActual = DateTime.now().year;

    // Calculamos el año inicial respetando el año base y el límite de gestiones
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
      final emp = ref.read(codEmpresaAnticiposProvider);
      ref.read(anticipoProvider(emp).notifier).buscar(q);
    });
  }

  void _abrirAsignacion(BuildContext ctx, AnticipoEntity e) {
    final uid = _uid;
    showDialog(
      context: ctx,
      builder:
          (dCtx) => ModoAsignacionDialog(
            cabecera: e,
            onTigo: () {
              Navigator.pop(dCtx);
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder:
                    (_) => AsignacionTigoSheet(cabecera: e, audUsuarioI: uid),
              );
            },
            onManual: () {
              Navigator.pop(dCtx);
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder:
                    (_) => AsignacionManualSheet(cabecera: e, audUsuarioI: uid),
              );
            },
          ),
    );
  }

  void _verDetalle(BuildContext ctx, AnticipoEntity e) => showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AnticipoDetalleSheet(anticipo: e),
  );

  @override
  Widget build(BuildContext context) {
    final emp = ref.watch(codEmpresaAnticiposProvider);
    ref.listenMessages(anticipoProvider(emp), context);
    ref.listen<AnticipoState>(anticipoProvider(emp), (prev, next) {
      if (!mounted) return;
      if (next.search.isEmpty && _searchCtrl.text.isNotEmpty) {
        _searchCtrl.clear();
      }
    });

    final st = ref.watch(anticipoProvider(emp));
    final ntf = ref.read(anticipoProvider(emp).notifier);
    final cs = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Scaffold(
      backgroundColor: cs.surfaceVariant.withOpacity(0.15),
      appBar: AnticiposAppBar(st: st, ntf: ntf),
      body: Column(
        children: [
          AnticiposFilterBar(
            st: st,
            ntf: ntf,
            searchCtrl: _searchCtrl,
            onSearch: _onSearch,
            anios: _anios,
          ),
          Expanded(
            child:
                isDesktop
                    ? AnticiposDesktopView(
                      st: st,
                      ntf: ntf,
                      onAsignar: (e) => _abrirAsignacion(context, e),
                      onVerDetalle: (e) => _verDetalle(context, e),
                      uid: _uid,
                    )
                    : AnticiposMobileView(
                      st: st,
                      ntf: ntf,
                      onAsignar: (e) => _abrirAsignacion(context, e),
                      onVerDetalle: (e) => _verDetalle(context, e),
                      uid: _uid,
                    ),
          ),
        ],
      ),
    );
  }
}
