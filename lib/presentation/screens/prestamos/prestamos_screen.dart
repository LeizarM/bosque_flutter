import 'dart:async';
import 'package:bosque_flutter/core/state/prestamo_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/prestamo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_empleados_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Widget imports ──────────────────────────────────────────────────────────
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_app_bar.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_filter_bar.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_desktop_view.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_mobile_view.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_asignacion_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_asignacion_controller.dart';

import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_detalle_sheet.dart';

export 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_constants.dart'
    show codEmpresaPrestamosProvider;

// ══════════════════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ══════════════════════════════════════════════════════════════════════════════
class PrestamosScreen extends ConsumerStatefulWidget {
  const PrestamosScreen({super.key});
  @override
  ConsumerState<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends ConsumerState<PrestamosScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _searchTimer;

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
      final emp = ref.read(codEmpresaPrestamosProvider);
      ref.read(prestamoProvider(emp).notifier).cargar(search: q, pagina: 1);
    });
  }

  void _abrirAsignacion(BuildContext ctx, PrestamoEntity e) {
    final emp = ref.read(codEmpresaPrestamosProvider);
    showPrestamoAsignacionDialog(
      ctx,
      modo: PrestamoDialogModo.asignacionSap,
      audUsuarioI: _uid,
      cabecera: e,
    ).then((_) {
      if (!mounted) return;
      ref.read(prestamoProvider(emp).notifier).cargar();
    });
  }

  void _editar(BuildContext ctx, PrestamoEntity e) {
    if (e.estadoAsignacion == 'NO ASIGNADO') {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('No se puede editar un registro no asignado.'),
        ),
      );
      return;
    }
    final emp = ref.read(codEmpresaPrestamosProvider);

    showPrestamoAsignacionDialog(
      ctx,
      modo: PrestamoDialogModo.edicionSap,
      audUsuarioI: _uid,
      cabecera: e,
    ).then((_) {
      if (!mounted) return;
      ref.read(prestamoProvider(emp).notifier).cargar();
    });
  }

  void _verDetalle(BuildContext ctx, PrestamoEntity e) {
    if (e.estadoAsignacion == 'NO ASIGNADO' || (e.codPrestamo ?? 0) == 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Este registro aún no ha sido asignado.')),
      );
      return;
    }

    final nombreAsignado = e.nombreEmpleadoAsignado ?? '';
    if (nombreAsignado.toUpperCase().startsWith('VARIOS EMPLEADOS')) {
      showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PrestamosEmpleadosSheet(prestamo: e),
      );
    } else {
      showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PrestamosDetalleSheet(prestamo: e),
      );
    }
  }

  void _anularPrestamo(BuildContext ctx, PrestamoEntity e) {
    if (e.estadoAsignacion == 'NO ASIGNADO' || (e.codPrestamo ?? 0) == 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Este registro aún no ha sido asignado.')),
      );
      return;
    }

    showDialog(
      context: ctx,
      builder: (ctxDialog) {
        return AlertDialog(
          title: const Text('Anular Préstamo'),
          content: const Text(
            '¿Está seguro de anular completamente este préstamo?',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctxDialog),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(ctx);
                Navigator.pop(ctxDialog);
                try {
                  final emp = ref.read(codEmpresaPrestamosProvider);
                  final ntf = ref.read(prestamoProvider(emp).notifier);
                  final msg = await ntf.anularPrestamo(
                    codPrestamo: e.codPrestamo!,
                    audUsuario: _uid,
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (err) {
                  // El error ya se muestra a través del listener global de SnackBar
                }
              },
              child: const Text(
                'Anular',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emp = ref.watch(codEmpresaPrestamosProvider);
    ref.listenMessages(prestamoProvider(emp), context);
    ref.listen<PrestamoState>(prestamoProvider(emp), (prev, next) {
      if (!mounted) return;
      if (next.search.isEmpty && _searchCtrl.text.isNotEmpty) {
        _searchCtrl.clear();
      }
    });

    final st = ref.watch(prestamoProvider(emp));
    final ntf = ref.read(prestamoProvider(emp).notifier);
    final cs = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.15),
      appBar: PrestamosAppBar(st: st, ntf: ntf),
      body: Column(
        children: [
          PrestamosFilterBar(
            st: st,
            ntf: ntf,
            searchCtrl: _searchCtrl,
            onSearch: _onSearch,
          ),
          Expanded(
            child:
                isDesktop
                    ? PrestamosDesktopView(
                      st: st,
                      ntf: ntf,
                      onAsignar: (e) => _abrirAsignacion(context, e),
                      onVerDetalle: (e) => _verDetalle(context, e),
                      onEditar: (e) => _editar(context, e),
                      onAnular: (e) => _anularPrestamo(context, e),
                      uid: _uid,
                    )
                    : PrestamosMobileView(
                      st: st,
                      ntf: ntf,
                      onAsignar: (e) => _abrirAsignacion(context, e),
                      onVerDetalle: (e) => _verDetalle(context, e),
                      onEditar: (e) => _editar(context, e),
                      onAnular: (e) => _anularPrestamo(context, e),
                      uid: _uid,
                    ),
          ),
        ],
      ),
    );
  }
}
