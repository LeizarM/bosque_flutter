import 'package:bosque_flutter/core/state/dias_no_laborables_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/data/repositories/dias_no_laborables_impl.dart';
import 'package:bosque_flutter/domain/entities/dia_no_laborable_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dias-no-laborables/dialogo_dia_no_laborable.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Codigos de tb_vistaBtn para codVista=14 ('tbDiaNoLaborable/diaNoLaborable'),
// los mismos que usaba el JSF legacy. btnEditarPEDNL (ABM por-empresa) no se
// migro, por eso no tiene equivalente aca.
const _btnNuevoDNL = 'btnNuevoDNL';
const _btnEditarDNL = 'btnEditarDNL';
const _btnEliminarDNL = 'btnEliminarDNL';

final _df = DateFormat('dd/MM/yyyy');

// Anchos de columna de la tabla (tablet/desktop) — compartidos entre el header
// y cada fila para que queden alineados.
const _colFecha = 100.0;
const _colAlcance = 150.0;
const _colAcciones = 88.0;
const _anchoMaxContenido = 960.0;

class DiasNoLaborablesScreen extends ConsumerStatefulWidget {
  const DiasNoLaborablesScreen({super.key});

  @override
  ConsumerState<DiasNoLaborablesScreen> createState() =>
      _DiasNoLaborablesScreenState();
}

class _DiasNoLaborablesScreenState
    extends ConsumerState<DiasNoLaborablesScreen> {
  late int _gestion;

  @override
  void initState() {
    super.initState();
    _gestion = DateTime.now().year;
  }

  List<int> get _gestiones {
    final actual = DateTime.now().year;
    return [for (int y = 2015; y <= actual + 2; y++) y];
  }

  void _abrirDialogo({DiaNoLaborableEntity? editar, required bool compacto}) {
    final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;

    if (compacto) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DialogoDiaNoLaborable(
          gestion: _gestion,
          audUsuario: audUsuario,
          editar: editar,
        ),
      );
      return;
    }

    // Desktop/tablet: dialogo centrado de ancho fijo en vez de un bottom
    // sheet estirado de punta a punta de una pantalla de 1920px.
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Esquina.media),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DialogoDiaNoLaborable(
            gestion: _gestion,
            audUsuario: audUsuario,
            editar: editar,
            mostrarAsa: false,
          ),
        ),
      ),
    );
  }

  Future<void> _eliminar(DiaNoLaborableEntity item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar dia no laborable'),
        content: Text(
          '¿Confirma eliminar "${item.motivo}" (${_df.format(item.fecha)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
      final repo = DiasNoLaborablesImpl();
      await repo.eliminarDiaNoLaborable({
        'idDiaNoLaborable': item.idDiaNoLaborable.toInt(),
        'audUsuario': audUsuario,
      });
      if (!mounted) return;
      ref.invalidate(diasNoLaborablesProvider(_gestion));
      mostrarAviso(context, 'Dia no laborable eliminado');
    } catch (e) {
      if (!mounted) return;
      mostrarAviso(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        tono: TonoAviso.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricciones) {
          // El ancho del CAJON (LayoutBuilder), no el de la ventana: adentro
          // del dashboard el sidebar se come su parte y MediaQuery miente.
          final aire = Aire.de(restricciones.maxWidth);
          final compacto = aire == Aire.justo;
          final asyncLista = ref.watch(diasNoLaborablesProvider(_gestion));

          return Column(
            children: [
              _Header(
                compacto: compacto,
                gestion: _gestion,
                gestiones: _gestiones,
                onNuevo: () => _abrirDialogo(compacto: compacto),
                onRefrescar: () =>
                    ref.invalidate(diasNoLaborablesProvider(_gestion)),
                onGestionChange: (y) => setState(() => _gestion = y),
              ),
              const Divider(height: 1),
              Expanded(
                child: asyncLista.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Esp.xxl),
                      child: Text(
                        'Error: $e',
                        style: TextStyle(color: cs.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (lista) {
                    if (lista.isEmpty) {
                      return _EstadoVacio(gestion: _gestion, compacto: compacto);
                    }
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _anchoMaxContenido,
                        ),
                        child: compacto
                            ? _ListaMobile(
                                lista: lista,
                                onEditar: (item) => _abrirDialogo(
                                  editar: item,
                                  compacto: true,
                                ),
                                onEliminar: _eliminar,
                              )
                            : _TablaEscritorio(
                                lista: lista,
                                onEditar: (item) => _abrirDialogo(
                                  editar: item,
                                  compacto: false,
                                ),
                                onEliminar: _eliminar,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final bool compacto;
  final int gestion;
  final List<int> gestiones;
  final VoidCallback onNuevo;
  final VoidCallback onRefrescar;
  final ValueChanged<int> onGestionChange;

  const _Header({
    required this.compacto,
    required this.gestion,
    required this.gestiones,
    required this.onNuevo,
    required this.onRefrescar,
    required this.onGestionChange,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: EdgeInsets.fromLTRB(
        compacto ? Esp.l : Esp.xl,
        Esp.l,
        Esp.l,
        Esp.m,
      ),
      color: cs.surface,
      child: Wrap(
        spacing: Esp.l,
        runSpacing: Esp.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, color: cs.primary, size: 22),
              const SizedBox(width: Esp.s),
              Text(
                'Días No Laborables',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: Peso.titulo,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: Esp.l),
              const Text('Gestión'),
              const SizedBox(width: Esp.s),
              DropdownButton<int>(
                value: gestion,
                underline: const SizedBox.shrink(),
                items: gestiones
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (y) {
                  if (y != null) onGestionChange(y);
                },
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PermissionWidget(
                buttonName: _btnNuevoDNL,
                child: FilledButton.tonalIcon(
                  onPressed: onNuevo,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo'),
                ),
              ),
              const SizedBox(width: Esp.xs),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualizar',
                onPressed: onRefrescar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Estado vacio
// ═══════════════════════════════════════════════════════════════════════════

class _EstadoVacio extends StatelessWidget {
  final int gestion;
  final bool compacto;
  const _EstadoVacio({required this.gestion, required this.compacto});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: compacto ? 48 : 64,
            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: Esp.l),
          Text(
            'No hay días no laborables en la gestión $gestion',
            textAlign: TextAlign.center,
            style: context.apagado(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Lista mobile (cards)
// ═══════════════════════════════════════════════════════════════════════════

class _ListaMobile extends StatelessWidget {
  final List<DiaNoLaborableEntity> lista;
  final ValueChanged<DiaNoLaborableEntity> onEditar;
  final ValueChanged<DiaNoLaborableEntity> onEliminar;

  const _ListaMobile({
    required this.lista,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Esp.m),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: Esp.s),
      itemBuilder: (context, i) {
        final item = lista[i];
        return _CardDia(
          item: item,
          onEditar: () => onEditar(item),
          onEliminar: () => onEliminar(item),
        );
      },
    );
  }
}

class _CardDia extends StatelessWidget {
  final DiaNoLaborableEntity item;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _CardDia({
    required this.item,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primaryContainer,
              child: Icon(
                Icons.event_busy_rounded,
                size: 18,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: Esp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.motivo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: Peso.dato,
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(_df.format(item.fecha), style: context.apagado()),
                ],
              ),
            ),
            const SizedBox(width: Esp.s),
            _BadgeAlcance(alcance: item.alcance),
            _AccionesDia(
              compacto: true,
              onEditar: onEditar,
              onEliminar: onEliminar,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tabla tablet/desktop — precision tabular, ritmo de fila constante.
// ═══════════════════════════════════════════════════════════════════════════

class _TablaEscritorio extends StatelessWidget {
  final List<DiaNoLaborableEntity> lista;
  final ValueChanged<DiaNoLaborableEntity> onEditar;
  final ValueChanged<DiaNoLaborableEntity> onEliminar;

  const _TablaEscritorio({
    required this.lista,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.xl, vertical: Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilaEncabezado(cs: cs),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: Esp.xs),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const SizedBox(height: 1),
              itemBuilder: (context, i) {
                final item = lista[i];
                return _FilaDia(
                  item: item,
                  onEditar: () => onEditar(item),
                  onEliminar: () => onEliminar(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaEncabezado extends StatelessWidget {
  final ColorScheme cs;
  const _FilaEncabezado({required this.cs});

  @override
  Widget build(BuildContext context) {
    final estilo = context.tituloSeccion()?.copyWith(
      fontSize: 11,
      color: cs.onSurfaceVariant,
      letterSpacing: 0.4,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      child: Row(
        children: [
          SizedBox(width: _colFecha, child: Text('FECHA', style: estilo)),
          Expanded(child: Text('MOTIVO', style: estilo)),
          SizedBox(
            width: _colAlcance,
            child: Text('ALCANCE', style: estilo, textAlign: TextAlign.center),
          ),
          SizedBox(width: _colAcciones, child: const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _FilaDia extends StatefulWidget {
  final DiaNoLaborableEntity item;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  const _FilaDia({
    required this.item,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  State<_FilaDia> createState() => _FilaDiaState();
}

class _FilaDiaState extends State<_FilaDia> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hover
              ? cs.primaryContainer.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        padding: const EdgeInsets.symmetric(vertical: Esp.s, horizontal: Esp.xs),
        child: Row(
          children: [
            SizedBox(
              width: _colFecha,
              child: Text(
                _df.format(widget.item.fecha),
                style: TextStyle(
                  fontSize: 13,
                  fontFeatures: cifrasTabulares,
                  color: cs.onSurface,
                ),
              ),
            ),
            Expanded(
              child: Text(
                widget.item.motivo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: Peso.dato,
                  color: cs.onSurface,
                ),
              ),
            ),
            SizedBox(
              width: _colAlcance,
              child: Center(child: _BadgeAlcance(alcance: widget.item.alcance)),
            ),
            SizedBox(
              width: _colAcciones,
              child: _AccionesDia(
                compacto: false,
                onEditar: widget.onEditar,
                onEliminar: widget.onEliminar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas compartidas
// ═══════════════════════════════════════════════════════════════════════════

/// El alcance solo tiene dos familias posibles y ninguna es un problema, asi
/// que ninguna usa el rol `error`: Global va en `tertiary` (como un feriado),
/// acotado a sucursales va en `primary` (el caso mas frecuente).
class _BadgeAlcance extends StatelessWidget {
  final String alcance;
  const _BadgeAlcance({required this.alcance});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final esGlobal = alcance.toLowerCase() == 'global';
    final familia = esGlobal ? cs.tertiaryContainer : cs.primaryContainer;
    final onFamilia = esGlobal ? cs.onTertiaryContainer : cs.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 3),
      decoration: BoxDecoration(
        color: familia.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Esquina.pastilla),
      ),
      child: Text(
        alcance,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, fontWeight: Peso.dato, color: onFamilia),
      ),
    );
  }
}

/// Editar/Eliminar filtrados por permiso real (btnEditarDNL/btnEliminarDNL).
/// Compacto (mobile): un solo menu para no apretar botones chicos uno al lado
/// del otro. Ancho (tablet/desktop): dos botones, hay lugar de sobra.
class _AccionesDia extends ConsumerWidget {
  final bool compacto;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  const _AccionesDia({
    required this.compacto,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puedeEditar = tienePermisoDeBoton(ref, _btnEditarDNL);
    final puedeEliminar = tienePermisoDeBoton(ref, _btnEliminarDNL);
    if (!puedeEditar && !puedeEliminar) return const SizedBox.shrink();

    if (compacto) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, size: 20),
        onSelected: (v) => v == 'editar' ? onEditar() : onEliminar(),
        itemBuilder: (context) => [
          if (puedeEditar)
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 18),
                  SizedBox(width: Esp.s),
                  Text('Editar'),
                ],
              ),
            ),
          if (puedeEliminar)
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                  SizedBox(width: Esp.s),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
        ],
      );
    }

    final cs = context.cs;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (puedeEditar)
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            tooltip: 'Editar',
            onPressed: onEditar,
          ),
        if (puedeEliminar)
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: cs.error),
            tooltip: 'Eliminar',
            onPressed: onEliminar,
          ),
      ],
    );
  }
}
