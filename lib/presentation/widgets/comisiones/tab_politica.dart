import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/formato_comision.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/politica_bond_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Administración de la política del descuento por familia.
///
/// Son tres reglas distintas que se administran juntas porque se piensan
/// juntas:
///
///   1. Qué porcentaje se paga de cada familia, y desde cuándo.
///   2. Qué vendedores quedan exentos de ese descuento.
///   3. Qué clientes no cuentan para el total de qué vendedor.
///
/// La tercera no tiene nada que ver con el descuento: vivía escrita a mano
/// dentro de p_list_paraPagar como `case when vs.idVendedor = 64` y se trajo a
/// tabla para que el próximo cliente sea una fila y no un ALTER PROCEDURE.
class TabPolitica extends ConsumerStatefulWidget {
  const TabPolitica({super.key});

  @override
  ConsumerState<TabPolitica> createState() => _TabPoliticaState();
}

enum _Seccion {
  familias('Familias', Icons.category_outlined),
  exentos('Vendedores exentos', Icons.person_off_outlined),
  clientes('Clientes excluidos', Icons.business_outlined),
  descuentos('Descuentos aplicados', Icons.receipt_long_outlined);

  const _Seccion(this.etiqueta, this.icono);
  final String etiqueta;
  final IconData icono;
}

class _TabPoliticaState extends ConsumerState<TabPolitica> {
  _Seccion _seccion = _Seccion.familias;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final esMovil = ResponsiveUtilsBosque.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Advertencia(padding: padding),
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 4, padding, 12),
          // Wrap y no Row: los tres rótulos no entran en una línea de teléfono
          // y un Row los recortaría sin avisar.
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _Seccion.values)
                ChoiceChip(
                  selected: _seccion == s,
                  onSelected: (_) => setState(() => _seccion = s),
                  avatar: Icon(s.icono, size: 18),
                  label: Text(
                    esMovil ? s.etiqueta.split(' ').first : s.etiqueta,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch (_seccion) {
            _Seccion.familias => _SeccionFamilias(padding: padding),
            _Seccion.exentos => _SeccionExentos(padding: padding),
            _Seccion.clientes => _SeccionClientes(padding: padding),
            _Seccion.descuentos => _SeccionDescuentos(padding: padding),
          },
        ),
      ],
    );
  }
}

/// Lo que hay que saber antes de tocar cualquier número de esta pantalla.
class _Advertencia extends StatelessWidget {
  const _Advertencia({required this.padding});
  final double padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.fromLTRB(padding, 12, padding, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: ComisionesTema.brControl,
      ),
      // Sin clip la barra pisaria la esquina redondeada del contenedor.
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // La barra, no el relleno, es la que dice "esto importa". Va como
            // hijo y no como Border(left:) porque un borde no uniforme con
            // borderRadius no llega a pintarse. El padding vertical vive del
            // lado del texto justamente para que la barra llegue a los bordes.
            Container(width: 3, color: cs.tertiary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: cs.tertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text:
                                  'Lo que se configura acá cambia cuánto se le paga a la '
                                  'fuerza de ventas. El porcentaje es ',
                            ),
                            const TextSpan(
                              text: 'LO QUE SE PAGA',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const TextSpan(
                              text:
                                  ': 50 % significa que ese ítem entra a la mitad, y '
                                  '100 % es no descontar nada. Rige por fecha de '
                                  'factura, así que las notas anteriores a la vigencia '
                                  'se siguen liquidando como antes.',
                            ),
                          ],
                        ),
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sección 1: familias ──────────────────────────────────────────────────────

class _SeccionFamilias extends ConsumerWidget {
  const _SeccionFamilias({required this.padding});
  final double padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(politicaFamiliasProvider);

    return datos.when(
      loading:
          () => EstadoVista.cargando(context, mensaje: 'Cargando políticas'),
      error:
          (e, _) => EstadoVista.error(
            context,
            error: e,
            alReintentar: () => ref.invalidate(politicaFamiliasProvider),
          ),
      data: (lista) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BarraAccion(
              padding: padding,
              rotulo: '${lista.length} política(s)',
              textoBoton: 'Agregar familia',
              alAgregar: () => _abrirDialogo(context, ref, null),
            ),
            Expanded(
              child:
                  lista.isEmpty
                      ? EstadoVista.vacio(
                        context,
                        titulo: 'Sin políticas',
                        indicacion:
                            'Nadie está recibiendo descuento por familia. '
                            'Agregue una para empezar a aplicarlo.',
                        icono: Icons.category_outlined,
                      )
                      : ListView.separated(
                        padding: EdgeInsets.fromLTRB(padding, 0, padding, 24),
                        itemCount: lista.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final f = lista[i];
                          return _Ficha(
                            titulo: f.grpFam,
                            activa: f.estaActiva,
                            chips: [
                              ChipEstado(
                                texto:
                                    '${FormatoComision.monto.format(f.porcentajePago)} % se paga',
                                tono: TonoChip.acento,
                              ),
                              if (!f.sinEfecto)
                                ChipEstado(
                                  texto:
                                      'descuenta ${FormatoComision.monto.format(f.porcentajeDescuento)} %',
                                ),
                              ChipEstado(texto: 'desde ${_f(f.vigenteDesde)}'),
                              if (f.vigenteHasta != null)
                                ChipEstado(
                                  texto: 'hasta ${_f(f.vigenteHasta)}',
                                ),
                              if (f.sinEfecto)
                                ChipEstado(
                                  texto: 'sin efecto',
                                  tono: TonoChip.alerta,
                                ),
                            ],
                            alEditar: () => _abrirDialogo(context, ref, f),
                            alDesactivar:
                                f.estaActiva
                                    ? () => _desactivar(context, ref, f)
                                    : null,
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _abrirDialogo(
    BuildContext context,
    WidgetRef ref,
    FamiliaPoliticaEntity? actual,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _DialogoFamilia(actual: actual),
    );
  }

  Future<void> _desactivar(
    BuildContext context,
    WidgetRef ref,
    FamiliaPoliticaEntity f,
  ) async {
    final ok = await _confirmar(
      context,
      'Desactivar la política de ${f.grpFam}',
      'Deja de descontarse desde ahora. No se borra: el preliminar de un '
          'período viejo tiene que seguir siendo reconstruible con la política '
          'que regía entonces.',
    );
    if (!ok || !context.mounted) return;

    final uid = ref.read(userProvider)?.codUsuario ?? 0;
    final exito = await ref
        .read(comisionesAccionesProvider.notifier)
        .eliminarPoliticaFamilia(f, uid);
    if (context.mounted) _avisar(context, ref, exito, 'Política desactivada.');
  }
}

// ── Sección 2: vendedores exentos ────────────────────────────────────────────

class _SeccionExentos extends ConsumerWidget {
  const _SeccionExentos({required this.padding});
  final double padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(vendedoresExentosProvider);

    return datos.when(
      loading: () => EstadoVista.cargando(context, mensaje: 'Cargando exentos'),
      error:
          (e, _) => EstadoVista.error(
            context,
            error: e,
            alReintentar: () => ref.invalidate(vendedoresExentosProvider),
          ),
      data: (lista) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BarraAccion(
              padding: padding,
              rotulo: '${lista.length} exento(s)',
              textoBoton: 'Eximir vendedor',
              alAgregar:
                  () => showDialog<void>(
                    context: context,
                    builder: (_) => const _DialogoExento(),
                  ),
            ),
            Expanded(
              child:
                  lista.isEmpty
                      ? EstadoVista.vacio(
                        context,
                        titulo: 'Sin exentos',
                        indicacion:
                            'A todos se les aplica el descuento por familia.',
                        icono: Icons.person_off_outlined,
                      )
                      : ListView.separated(
                        padding: EdgeInsets.fromLTRB(padding, 0, padding, 24),
                        itemCount: lista.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = lista[i];
                          return _Ficha(
                            titulo: e.nomVenSAP ?? 'Vendedor ${e.idVendedor}',
                            subtitulo: e.motivo,
                            activa: e.estaActiva,
                            chips: [
                              ChipEstado(texto: 'desde ${_f(e.vigenteDesde)}'),
                              if (e.vigenteHasta != null)
                                ChipEstado(
                                  texto: 'hasta ${_f(e.vigenteHasta)}',
                                ),
                            ],
                            alDesactivar:
                                e.estaActiva
                                    ? () async {
                                      final ok = await _confirmar(
                                        context,
                                        'Quitar la exención',
                                        'A ${e.nomVenSAP ?? "este vendedor"} '
                                            'se le va a empezar a aplicar el '
                                            'descuento.',
                                      );
                                      if (!ok || !context.mounted) return;
                                      final uid =
                                          ref.read(userProvider)?.codUsuario ??
                                          0;
                                      final exito = await ref
                                          .read(
                                            comisionesAccionesProvider.notifier,
                                          )
                                          .eliminarVendedorExento(e, uid);
                                      if (context.mounted) {
                                        _avisar(
                                          context,
                                          ref,
                                          exito,
                                          'Exención quitada.',
                                        );
                                      }
                                    }
                                    : null,
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}

// ── Sección 3: clientes excluidos ────────────────────────────────────────────

class _SeccionClientes extends ConsumerWidget {
  const _SeccionClientes({required this.padding});
  final double padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(clientesExcluidosProvider);

    return datos.when(
      loading:
          () => EstadoVista.cargando(context, mensaje: 'Cargando clientes'),
      error:
          (e, _) => EstadoVista.error(
            context,
            error: e,
            alReintentar: () => ref.invalidate(clientesExcluidosProvider),
          ),
      data: (lista) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BarraAccion(
              padding: padding,
              rotulo: '${lista.length} exclusión(es)',
              textoBoton: 'Excluir cliente',
              alAgregar:
                  () => showDialog<void>(
                    context: context,
                    builder: (_) => const _DialogoCliente(),
                  ),
            ),
            Expanded(
              child:
                  lista.isEmpty
                      ? EstadoVista.vacio(
                        context,
                        titulo: 'Sin exclusiones',
                        indicacion:
                            'Todas las notas cuentan para el total de su vendedor.',
                        icono: Icons.business_outlined,
                      )
                      : ListView.separated(
                        padding: EdgeInsets.fromLTRB(padding, 0, padding, 24),
                        itemCount: lista.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final c = lista[i];
                          return _Ficha(
                            titulo: c.cardCode,
                            subtitulo:
                                'No cuenta para '
                                '${c.nomVenSAP ?? "vendedor ${c.idVendedor}"}'
                                '${c.motivo != null ? " · ${c.motivo}" : ""}',
                            activa: c.estaActiva,
                            chips: [
                              ChipEstado(texto: c.empresa),
                              ChipEstado(texto: 'desde ${_f(c.vigenteDesde)}'),
                              if (c.vigenteHasta != null)
                                ChipEstado(
                                  texto: 'hasta ${_f(c.vigenteHasta)}',
                                ),
                            ],
                            alDesactivar:
                                c.estaActiva
                                    ? () async {
                                      final ok = await _confirmar(
                                        context,
                                        'Quitar la exclusión',
                                        'Las notas de ${c.cardCode} van a '
                                            'volver a contar para el total de '
                                            '${c.nomVenSAP ?? "ese vendedor"}.',
                                      );
                                      if (!ok || !context.mounted) return;
                                      final uid =
                                          ref.read(userProvider)?.codUsuario ??
                                          0;
                                      final exito = await ref
                                          .read(
                                            comisionesAccionesProvider.notifier,
                                          )
                                          .eliminarClienteExcluido(c, uid);
                                      if (context.mounted) {
                                        _avisar(
                                          context,
                                          ref,
                                          exito,
                                          'Exclusión quitada.',
                                        );
                                      }
                                    }
                                    : null,
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}

// ── Diálogos ─────────────────────────────────────────────────────────────────

class _DialogoFamilia extends ConsumerStatefulWidget {
  const _DialogoFamilia({this.actual});
  final FamiliaPoliticaEntity? actual;

  @override
  ConsumerState<_DialogoFamilia> createState() => _DialogoFamiliaState();
}

class _DialogoFamiliaState extends ConsumerState<_DialogoFamilia> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pct;
  int? _idFamilia;
  late DateTime _desde;
  DateTime? _hasta;

  bool get _esNueva => widget.actual == null;

  @override
  void initState() {
    super.initState();
    final a = widget.actual;
    _pct = TextEditingController(
      text: a == null ? '50' : FormatoComision.monto.format(a.porcentajePago),
    );
    _idFamilia = a?.idGrpFamiliaSap;
    _desde = a?.vigenteDesde ?? DateTime.now();
    _hasta = a?.vigenteHasta;
  }

  @override
  void dispose() {
    _pct.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = ref.watch(familiasSapDisponiblesProvider);

    return AlertDialog(
      title: Text(_esNueva ? 'Nueva política' : widget.actual!.grpFam),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_esNueva)
                  disponibles.when(
                    loading:
                        () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    error: (e, _) => Text('$e'),
                    data:
                        (lista) => DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _idFamilia,
                          decoration: const InputDecoration(
                            labelText: 'Familia',
                            helperText:
                                'Solo se listan las que aún no tienen política',
                          ),
                          items: [
                            for (final f in lista)
                              DropdownMenuItem(
                                value: f.idGrpFamiliaSap,
                                child: Text(f.grpFam),
                              ),
                          ],
                          validator:
                              (v) => v == null ? 'Elija una familia' : null,
                          onChanged: (v) => setState(() => _idFamilia = v),
                        ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pct,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Porcentaje que SE PAGA',
                    suffixText: '%',
                    helperText:
                        '50 = se paga la mitad. 100 = no se descuenta nada.',
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (n == null) return 'Ingrese un número';
                    if (n < 0 || n > 100) return 'Debe estar entre 0 y 100';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _CampoFecha(
                  rotulo: 'Vigente desde',
                  valor: _desde,
                  ayuda:
                      'Se aplica a las notas con fecha de factura desde este día',
                  alCambiar: (f) => setState(() => _desde = f),
                ),
                const SizedBox(height: 12),
                _CampoFecha(
                  rotulo: 'Vigente hasta (opcional)',
                  valor: _hasta,
                  ayuda: 'Vacío = sin fecha de fin',
                  alCambiar: (f) => setState(() => _hasta = f),
                  alLimpiar: () => setState(() => _hasta = null),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final pct = double.parse(_pct.text.replaceAll(',', '.'));
    final uid = ref.read(userProvider)?.codUsuario ?? 0;

    final mb =
        _esNueva
            ? FamiliaPoliticaEntity(
              idFamPolitica: 0,
              idGrpFamiliaSap: _idFamilia!,
              grpFam: '',
              porcentajePago: pct,
              vigenteDesde: _desde,
              vigenteHasta: _hasta,
              activo: 1,
            )
            : widget.actual!.copyWith(
              porcentajePago: pct,
              vigenteDesde: _desde,
              vigenteHasta: _hasta,
              limpiarVigenteHasta: _hasta == null,
            );

    final exito = await ref
        .read(comisionesAccionesProvider.notifier)
        .guardarPoliticaFamilia(mb, uid);

    if (!mounted) return;
    if (exito) {
      ref.invalidate(familiasSapDisponiblesProvider);
      Navigator.of(context).pop();
    }
    _avisar(context, ref, exito, 'Política guardada.');
  }
}

class _DialogoExento extends ConsumerStatefulWidget {
  const _DialogoExento();

  @override
  ConsumerState<_DialogoExento> createState() => _DialogoExentoState();
}

class _DialogoExentoState extends ConsumerState<_DialogoExento> {
  final _formKey = GlobalKey<FormState>();
  final _motivo = TextEditingController();
  int? _idVendedor;
  DateTime _desde = DateTime.now();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendedores = ref.watch(vendedoresComisionProvider);

    return AlertDialog(
      title: const Text('Eximir vendedor del descuento'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                vendedores.when(
                  loading:
                      () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  error: (e, _) => Text('$e'),
                  data:
                      (lista) => DropdownButtonFormField<int>(
                        value: _idVendedor,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Vendedor',
                          helperText:
                              'Para los supervisores se evalúa sobre quien cobra, '
                              'no sobre el vendedor de la nota',
                        ),
                        items: [
                          for (final v in lista)
                            DropdownMenuItem(
                              value: v.idVendedor.toInt(),
                              child: Text(
                                v.nomVenSap,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        validator:
                            (v) => v == null ? 'Elija un vendedor' : null,
                        onChanged: (v) => setState(() => _idVendedor = v),
                      ),
                ),
                const SizedBox(height: 12),
                _CampoFecha(
                  rotulo: 'Vigente desde',
                  valor: _desde,
                  alCambiar: (f) => setState(() => _desde = f),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _motivo,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    helperText:
                        'Por qué queda exento. Se lee dentro de un año.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final uid = ref.read(userProvider)?.codUsuario ?? 0;
            final exito = await ref
                .read(comisionesAccionesProvider.notifier)
                .guardarVendedorExento(
                  VendedorExentoEntity(
                    idVenExento: 0,
                    idVendedor: _idVendedor!,
                    vigenteDesde: _desde,
                    activo: 1,
                    motivo:
                        _motivo.text.trim().isEmpty
                            ? null
                            : _motivo.text.trim(),
                  ),
                  uid,
                );
            if (!mounted) return;
            if (exito) Navigator.of(context).pop();
            _avisar(context, ref, exito, 'Exención registrada.');
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _DialogoCliente extends ConsumerStatefulWidget {
  const _DialogoCliente();

  @override
  ConsumerState<_DialogoCliente> createState() => _DialogoClienteState();
}

class _DialogoClienteState extends ConsumerState<_DialogoCliente> {
  final _formKey = GlobalKey<FormState>();
  final _cardCode = TextEditingController();
  final _motivo = TextEditingController();
  int? _idVendedor;
  String? _origen;
  DateTime _desde = DateTime.now();

  /// Las tres empresas con las que trabaja el módulo. null = todas.
  static const _empresas = ['IMPEXPAP', 'ESPPAPEL', 'PRODUCTIVA PAPEL'];

  @override
  void dispose() {
    _cardCode.dispose();
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendedores = ref.watch(vendedoresComisionProvider);

    return AlertDialog(
      title: const Text('Excluir cliente del total de un vendedor'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                vendedores.when(
                  loading:
                      () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  error: (e, _) => Text('$e'),
                  data:
                      (lista) => DropdownButtonFormField<int>(
                        value: _idVendedor,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Vendedor',
                        ),
                        items: [
                          for (final v in lista)
                            DropdownMenuItem(
                              value: v.idVendedor.toInt(),
                              child: Text(
                                v.nomVenSap,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        validator:
                            (v) => v == null ? 'Elija un vendedor' : null,
                        onChanged: (v) => setState(() => _idVendedor = v),
                      ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cardCode,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Código de cliente (cardCode)',
                    helperText: 'Tal como figura en SAP, p. ej. ED00779',
                  ),
                  validator:
                      (v) =>
                          (v ?? '').trim().isEmpty ? 'Ingrese el código' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  isExpanded: true,
                  value: _origen,
                  decoration: const InputDecoration(
                    labelText: 'Empresa',
                    helperText:
                        'Vacío = en todas. El mismo código puede existir en varias.',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    for (final e in _empresas)
                      DropdownMenuItem(value: e, child: Text(e)),
                  ],
                  onChanged: (v) => setState(() => _origen = v),
                ),
                const SizedBox(height: 12),
                _CampoFecha(
                  rotulo: 'Vigente desde',
                  valor: _desde,
                  alCambiar: (f) => setState(() => _desde = f),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _motivo,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Motivo'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final uid = ref.read(userProvider)?.codUsuario ?? 0;
            final exito = await ref
                .read(comisionesAccionesProvider.notifier)
                .guardarClienteExcluido(
                  ClienteExcluidoEntity(
                    idVenCliExc: 0,
                    idVendedor: _idVendedor!,
                    cardCode: _cardCode.text.trim().toUpperCase(),
                    origen: _origen,
                    vigenteDesde: _desde,
                    activo: 1,
                    motivo:
                        _motivo.text.trim().isEmpty
                            ? null
                            : _motivo.text.trim(),
                  ),
                  uid,
                );
            if (!mounted) return;
            if (exito) Navigator.of(context).pop();
            _avisar(context, ref, exito, 'Cliente excluido.');
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ── Piezas compartidas ───────────────────────────────────────────────────────

class _BarraAccion extends StatelessWidget {
  const _BarraAccion({
    required this.padding,
    required this.rotulo,
    required this.textoBoton,
    required this.alAgregar,
  });

  final double padding;
  final String rotulo;
  final String textoBoton;
  final VoidCallback alAgregar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            rotulo,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          FilledButton.icon(
            onPressed: alAgregar,
            icon: const Icon(Icons.add, size: 18),
            label: Text(textoBoton),
          ),
        ],
      ),
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({
    required this.titulo,
    this.subtitulo,
    required this.activa,
    required this.chips,
    this.alEditar,
    this.alDesactivar,
  });

  final String titulo;
  final String? subtitulo;
  final bool activa;
  final List<Widget> chips;
  final VoidCallback? alEditar;
  final VoidCallback? alDesactivar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: ComisionesTema.brControl,
        // Las inactivas se ven distinto pero no se esconden: son el historial.
        color:
            activa ? null : cs.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: activa ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
              if (alEditar != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Editar',
                  onPressed: alEditar,
                ),
              if (alDesactivar != null)
                IconButton(
                  icon: const Icon(Icons.block, size: 20),
                  tooltip: 'Desactivar',
                  onPressed: alDesactivar,
                ),
            ],
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitulo!,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: chips),
        ],
      ),
    );
  }
}

class _CampoFecha extends StatelessWidget {
  const _CampoFecha({
    required this.rotulo,
    required this.valor,
    required this.alCambiar,
    this.ayuda,
    this.alLimpiar,
  });

  final String rotulo;
  final DateTime? valor;
  final String? ayuda;
  final ValueChanged<DateTime> alCambiar;
  final VoidCallback? alLimpiar;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: rotulo, helperText: ayuda),
      child: Row(
        children: [
          Expanded(child: Text(valor == null ? '—' : _f(valor))),
          if (valor != null && alLimpiar != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Quitar',
              onPressed: alLimpiar,
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            onPressed: () async {
              final f = await showDatePicker(
                context: context,
                initialDate: valor ?? DateTime.now(),
                firstDate: DateTime(2019),
                lastDate: DateTime(2100),
              );
              if (f != null) alCambiar(f);
            },
          ),
        ],
      ),
    );
  }
}

String _f(DateTime? d) => d == null ? '—' : FormatoComision.fecha.format(d);

Future<bool> _confirmar(
  BuildContext context,
  String titulo,
  String detalle,
) async {
  final r = await showDialog<bool>(
    context: context,
    builder:
        (_) => AlertDialog(
          title: Text(titulo),
          content: Text(detalle),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
  );
  return r ?? false;
}

void _avisar(BuildContext context, WidgetRef ref, bool exito, String textoOk) {
  // El backend manda el mensaje del SP listo para mostrar: si falló, se muestra
  // ese y no uno genérico, que es lo único que le sirve al usuario.
  final estado = ref.read(comisionesAccionesProvider);
  avisar(
    context,
    exito ? textoOk : (estado.error ?? 'No se pudo guardar.'),
    esError: !exito,
  );
  ref.read(comisionesAccionesProvider.notifier).limpiar();
}

// ── Seccion 4: descuentos aplicados ──────────────────────────────────────────

/// Que se esta descontando, item por item.
///
/// Va en esta pantalla y no en el preliminar porque responde otra pregunta: el
/// preliminar dice cuanto se le paga a cada vendedor, esto dice de donde salio
/// el descuento. Mezclarlas obligaria a poner dos granularidades -vendedor y
/// linea de factura- en la misma hoja.
class _SeccionDescuentos extends ConsumerStatefulWidget {
  const _SeccionDescuentos({required this.padding});
  final double padding;

  @override
  ConsumerState<_SeccionDescuentos> createState() => _SeccionDescuentosState();
}

class _SeccionDescuentosState extends ConsumerState<_SeccionDescuentos> {
  late FiltroDescuento _filtro;

  /// Las tres empresas del modulo. null = todas.
  static const _empresas = ['IMPEXPAP', 'ESPPAPEL', 'PRODUCTIVA PAPEL'];

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _filtro = FiltroDescuento(accion: 'P', mes: hoy.month, anio: hoy.year);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final esMovil = ResponsiveUtilsBosque.isMobile(context);
    final datos = ref.watch(descuentoDetalleProvider(_filtro));
    final resumen = ref.watch(
      descuentoDetalleProvider(_filtro.copyWith(accion: 'R')),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Filtros(
          padding: widget.padding,
          filtro: _filtro,
          empresas: _empresas,
          alCambiar: (f) => setState(() => _filtro = f),
        ),
        // El resumen solo tiene sentido sobre el periodo abierto: en el
        // historico los porcentajes son los que quedaron congelados, y
        // reagruparlos por la politica de hoy mezclaria dos cosas.
        if (_filtro.accion == 'P')
          resumen.maybeWhen(
            data:
                (r) =>
                    r.isEmpty
                        ? const SizedBox.shrink()
                        : _Resumen(datos: r, padding: widget.padding),
            orElse: () => const SizedBox.shrink(),
          ),
        const Divider(height: 1),
        Expanded(
          child: datos.when(
            loading:
                () => EstadoVista.cargando(
                  context,
                  mensaje: 'Buscando descuentos',
                ),
            error:
                (e, _) => EstadoVista.error(
                  context,
                  error: e,
                  alReintentar:
                      () => ref.invalidate(descuentoDetalleProvider(_filtro)),
                ),
            data: (lista) {
              if (lista.isEmpty) {
                return EstadoVista.vacio(
                  context,
                  titulo: 'Sin descuentos',
                  indicacion:
                      _filtro.accion == 'P'
                          ? 'Ninguna nota del periodo tiene items de las familias '
                              'con politica.'
                          : 'No hay notas pagadas con descuento en ese periodo.',
                  icono: Icons.receipt_long_outlined,
                );
              }
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  widget.padding,
                  12,
                  widget.padding,
                  24,
                ),
                itemCount: lista.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final d = lista[i];
                  return _FichaDescuento(detalle: d, esMovil: esMovil);
                },
              );
            },
          ),
        ),
        if (datos.hasValue && datos.value!.isNotEmpty)
          Container(
            padding: EdgeInsets.fromLTRB(widget.padding, 8, widget.padding, 10),
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            child: Text(
              '${datos.value!.length} linea(s)  ·  total descontado '
              '${FormatoComision.monto.format(datos.value!.fold<double>(0, (a, d) => a + (d.descuentoBs ?? 0)))} Bs',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.padding,
    required this.filtro,
    required this.empresas,
    required this.alCambiar,
  });

  final double padding;
  final FiltroDescuento filtro;
  final List<String> empresas;
  final ValueChanged<FiltroDescuento> alCambiar;

  static const _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    final anioActual = DateTime.now().year;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
      // Wrap para que en un telefono los cuatro controles bajen de linea en vez
      // de recortarse.
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'P', label: Text('Por pagar')),
              ButtonSegment(value: 'H', label: Text('Ya pagado')),
            ],
            selected: {filtro.accion},
            onSelectionChanged:
                (v) => alCambiar(filtro.copyWith(accion: v.first)),
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              value: filtro.mes,
              decoration: const InputDecoration(
                labelText: 'Mes',
                isDense: true,
              ),
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(value: m, child: Text(_meses[m - 1])),
              ],
              onChanged:
                  (v) => v == null ? null : alCambiar(filtro.copyWith(mes: v)),
            ),
          ),
          SizedBox(
            width: 110,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              value: filtro.anio,
              decoration: const InputDecoration(
                labelText: 'Ano',
                isDense: true,
              ),
              items: [
                for (var a = anioActual - 4; a <= anioActual + 1; a++)
                  DropdownMenuItem(value: a, child: Text('$a')),
              ],
              onChanged:
                  (v) => v == null ? null : alCambiar(filtro.copyWith(anio: v)),
            ),
          ),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String?>(
              isExpanded: true,
              value: filtro.origen,
              decoration: const InputDecoration(
                labelText: 'Empresa',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                for (final e in empresas)
                  DropdownMenuItem(value: e, child: Text(e)),
              ],
              onChanged:
                  (v) => alCambiar(
                    v == null
                        ? filtro.copyWith(limpiarOrigen: true)
                        : filtro.copyWith(origen: v),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.datos, required this.padding});

  final List<DescuentoDetalleEntity> datos;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.fromLTRB(padding, 0, padding, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: ComisionesTema.brControl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen por vendedor y familia', style: tt.titleSmall),
          const SizedBox(height: 8),
          for (final r in datos)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${r.nombreVen ?? "-"}  ·  ${r.grupoFamilia ?? "-"}  ·  '
                      '${r.notas ?? 0} nota(s), ${r.items ?? 0} item(s)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-${FormatoComision.monto.format(r.descuentoBs ?? 0)}',
                    style: ComisionesTema.numeroApoyo(context, fuerte: true),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FichaDescuento extends StatelessWidget {
  const _FichaDescuento({required this.detalle, required this.esMovil});

  final DescuentoDetalleEntity detalle;
  final bool esMovil;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final d = detalle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: ComisionesTema.brControl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.itemName ?? d.itemCode ?? 'Item',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.itemCode ?? "-"}  ·  ${d.grupoFamilia ?? "-"}'
                      '${d.codGrupoSap != null ? " (SAP ${d.codGrupoSap})" : ""}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-${FormatoComision.monto.format(d.descuentoBs ?? 0)}',
                    style: ComisionesTema.numeroTotal(
                      context,
                    )?.copyWith(color: cs.error),
                  ),
                  if (d.porcentajeDescuento != null)
                    Text(
                      '${FormatoComision.monto.format(d.porcentajeDescuento)} % de descuento',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (d.docNum != null) ChipEstado(texto: 'Nota ${d.docNum}'),
              if (d.empresa != null) ChipEstado(texto: d.empresa!),
              if (d.nombreVen != null) ChipEstado(texto: d.nombreVen!),
              if (d.cardCode != null)
                ChipEstado(texto: 'Cliente ${d.cardCode}'),
              if (d.fechaDoc != null) ChipEstado(texto: _f(d.fechaDoc)),
              if (d.cantidad != null)
                ChipEstado(
                  texto: '${FormatoComision.monto.format(d.cantidad)} un',
                ),
              if (d.montoItemBs != null)
                ChipEstado(
                  texto:
                      'item ${FormatoComision.monto.format(d.montoItemBs)} Bs',
                  tono: TonoChip.acento,
                ),
              if (d.porcentajePago != null)
                ChipEstado(
                  texto:
                      'paga ${FormatoComision.monto.format(d.porcentajePago)} %',
                ),
              // El descuento se calcula igual para poder auditarlo, pero a este
              // vendedor no se le aplica.
              if (d.vendedorExento)
                ChipEstado(texto: 'vendedor exento', tono: TonoChip.alerta),
            ],
          ),
          if (d.montoBaseNotaBs != null || d.montoNotaAjustadoBs != null) ...[
            const SizedBox(height: 8),
            Text(
              'Nota: base ${FormatoComision.monto.format(d.montoBaseNotaBs ?? 0)} Bs'
              '  →  ajustada ${FormatoComision.monto.format(d.montoNotaAjustadoBs ?? 0)} Bs'
              '${d.comisionBs != null ? "  ·  comisión ${FormatoComision.monto.format(d.comisionBs)} Bs" : ""}',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          if (d.esHistorico && d.detalleBond != null) ...[
            const SizedBox(height: 6),
            Text(
              d.detalleBond!,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
