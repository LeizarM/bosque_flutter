/// Cambiar el grupo de familia y el proveedor SAP de una familia sin abrir la
/// ficha (`p_abm_producto 'F'` y `'G'`, en una transacción). Los combos arrancan
/// en lo que tiene la familia (se empareja por nombre: el listado no trae ids) y
/// se dispara la sincronización SAP de la sesión por si el grupo se creó hoy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/sincronizacion_sap.dart';

/// Devuelve true si se guardo.
Future<bool> mostrarAsignarSap(
  BuildContext context,
  FamiliaVista familia,
) async {
  final compacto = MediaQuery.sizeOf(context).width < 600;
  final contenido = _AsignarSap(familia: familia);
  final r =
      compacto
          ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => contenido,
          )
          : await showDialog<bool>(
            context: context,
            builder:
                (_) => Dialog(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: contenido,
                  ),
                ),
          );
  return r == true;
}

/// El id del catalogo cuyo nombre coincide con [descripcion]. Null si no hay
/// ninguno o si el catalogo todavia no llego.
BigInt? idPorNombre<T>(
  List<T>? catalogo,
  String descripcion,
  BigInt Function(T) id,
  List<String> Function(T) nombres,
) {
  final buscado = descripcion.trim().toLowerCase();
  if (catalogo == null || buscado.isEmpty) return null;
  for (final d in catalogo) {
    for (final n in nombres(d)) {
      if (n.trim().toLowerCase() == buscado) return id(d);
    }
  }
  return null;
}

class _AsignarSap extends ConsumerStatefulWidget {
  const _AsignarSap({required this.familia});

  final FamiliaVista familia;

  @override
  ConsumerState<_AsignarSap> createState() => _AsignarSapState();
}

class _AsignarSapState extends ConsumerState<_AsignarSap> {
  // Null = todavia no lo toco nadie: vale lo que tiene la familia.
  BigInt? _grupo;
  BigInt? _proveedor;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(sincronizacionSapProvider.notifier).asegurar();
    });
  }

  Future<void> _guardar(BigInt? grupo, BigInt? proveedor) async {
    setState(() => _guardando = true);
    try {
      await ref
          .read(preciosRepositoryProvider)
          .asignarSapFamilia(
            widget.familia.codigoFamilia,
            idGrpFamiliaSap: grupo,
            idProveedorSap: proveedor,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.familia;
    final grupos = ref.watch(gruposFamiliaSapProvider);
    final proveedores = ref.watch(proveedoresSapComboProvider);

    // Sin grupo o sin proveedor, el combo arranca en "Sin asignar".
    final grupo =
        _grupo ??
        f.idGrpFamiliaSap ??
        (f.grupoFamiliaSap.trim().isEmpty ? BigInt.zero : null) ??
        idPorNombre(
          grupos.valueOrNull,
          f.grupoFamiliaSap,
          (g) => g.idGrpFamiliaSap,
          (g) => [g.grpFam, g.alias, g.nombreVisible],
        );
    final proveedor =
        _proveedor ??
        f.idProveedorSap ??
        (f.proveedorSap.trim().isEmpty ? BigInt.zero : null) ??
        idPorNombre(
          proveedores.valueOrNull,
          f.proveedorSap,
          (p) => p.idProveedorSap,
          (p) => [p.proveedorExtSap, p.nombreLegible, p.etiquetaCompleta],
        );

    List<DropdownMenuEntry<BigInt?>> opciones<T>(
      AsyncValue<List<T>> catalogo,
      BigInt Function(T) id,
      String Function(T) rotulo,
    ) => catalogo.maybeWhen(
      data:
          (datos) => [
            DropdownMenuEntry<BigInt?>(
              value: BigInt.zero,
              label: 'Sin asignar',
            ),
            for (final d in datos)
              DropdownMenuEntry<BigInt?>(value: id(d), label: rotulo(d)),
          ],
      orElse: () => const <DropdownMenuEntry<BigInt?>>[],
    );
    // Lo que la familia tiene y el catalogo no reconoce (o todavia no llego):
    // guardar asi mandaria "sin asignar" sin que nadie lo haya pedido.
    final grupoPendiente = grupo == null && f.grupoFamiliaSap.trim().isNotEmpty;
    final proveedorPendiente =
        proveedor == null && f.proveedorSap.trim().isNotEmpty;
    String? ayuda(
      AsyncValue<Object?> catalogo,
      bool pendiente,
    ) => switch (catalogo) {
      AsyncError() => 'No se pudo cargar el catálogo',
      AsyncLoading() => 'Cargando…',
      _ => pendiente ? 'El actual no figura en el catálogo: elija uno' : null,
    };

    return PopScope(
      canPop: !_guardando,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Esp.xl,
            Esp.l,
            Esp.xl,
            Esp.l + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Grupo y proveedor SAP · familia ${f.codigoLegible}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: Peso.titulo),
              ),
              const SizedBox(height: Esp.xs),
              Text(
                'Cambia solo estos dos datos; el resto de la ficha queda igual.',
                style: context.apagado(),
              ),
              const SizedBox(height: Esp.l),
              const LineaSincronizacionSap(),
              ComboBuscable<BigInt?>(
                etiqueta: 'Grupo de familia SAP',
                valor: grupo,
                opciones: opciones(
                  grupos,
                  (g) => g.idGrpFamiliaSap,
                  (g) => g.nombreVisible,
                ),
                onElegir: (v) => setState(() => _grupo = v),
                ayuda: ayuda(grupos, grupoPendiente),
              ),
              const SizedBox(height: Esp.m),
              ComboBuscable<BigInt?>(
                etiqueta: 'Proveedor SAP',
                valor: proveedor,
                opciones: opciones(
                  proveedores,
                  (p) => p.idProveedorSap,
                  (p) => p.nombreLegible,
                ),
                onElegir: (v) => setState(() => _proveedor = v),
                ayuda: ayuda(proveedores, proveedorPendiente),
              ),
              const SizedBox(height: Esp.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _guardando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: Esp.s),
                  BotonAccion(
                    etiqueta: 'Guardar',
                    etiquetaOcupado: 'Guardando…',
                    icono: Icons.save_outlined,
                    ocupado: _guardando,
                    onPressed:
                        (_grupo == null && _proveedor == null) ||
                                grupoPendiente ||
                                proveedorPendiente
                            ? null
                            : () => _guardar(grupo, proveedor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
