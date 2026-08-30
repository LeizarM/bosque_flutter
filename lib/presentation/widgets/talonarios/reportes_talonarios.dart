import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/talonarios_provider.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/rango_fechas.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';

/// Los cuatro reportes del módulo.
///
/// **De dónde salen.** El wizard viejo tenía cuatro `.jrxml` que no eran cuatro
/// reportes: `RptTalMantFisico` y `RptTalMantEntregad` eran el mismo stored
/// procedure con la acción escrita a mano adentro del XML, y
/// `RptMntoTalGlobalV4` con `RptMntoTalSalidaGlobalV2` eran gemelos
/// estructurales. Ninguno de los cuatro tenía una sola `<variable>`: cero
/// sumas y cero conteos, con los pies de grupo vacíos.
///
/// Acá quedan cuatro preguntas distintas, cada una con sus totales.
enum _Reporte {
  inventario(
    'Inventario',
    'Qué talonarios hay, de quién son y en qué estado están.',
    Icons.inventory_2_outlined,
  ),
  trazabilidad(
    'Trazabilidad de entregas',
    'Qué se prestó, a quién y cuánto hace que no vuelve.',
    Icons.swap_horiz,
  ),
  custodia(
    'Quién tiene qué ahora',
    'Talonarios en poder de sucursales y personal, y quién los entregó.',
    Icons.assignment_ind_outlined,
  ),
  ficha(
    'Ficha de un talonario',
    'Su historial completo, para imprimir y adjuntar a un descargo.',
    Icons.description_outlined,
  ),
  conciliacion(
    'Conciliación con SAP',
    'Documentos de SAP contra los talonarios emitidos.',
    Icons.compare_arrows,
  );

  const _Reporte(this.titulo, this.detalle, this.icono);

  final String titulo;
  final String detalle;
  final IconData icono;
}

/// Abre el panel de reportes.
///
/// [talonarios] es la lista que se está viendo en pantalla. Se pasa en vez de
/// pedirla de nuevo para que el combo de la ficha ofrezca exactamente lo que
/// el usuario tiene delante, y para no disparar una segunda carga de 480 filas
/// por abrir un diálogo.
Future<void> mostrarReportesTalonarios(
  BuildContext context, {
  required List<TalonarioEntity> talonarios,
}) => showDialog<void>(
  context: context,
  builder: (_) => _PanelReportes(talonarios: talonarios),
);

class _PanelReportes extends ConsumerStatefulWidget {
  const _PanelReportes({required this.talonarios});

  final List<TalonarioEntity> talonarios;

  @override
  ConsumerState<_PanelReportes> createState() => _PanelReportesState();
}

class _PanelReportesState extends ConsumerState<_PanelReportes> {
  _Reporte _elegido = _Reporte.inventario;

  // Filtros. Todos opcionales salvo el talonario de la ficha.
  BigInt? _codTipoRecibo;
  int? _codEmpresa;
  BigInt? _codGrupo;
  int? _codEstadoActual;
  /// Dos rangos y no uno: en «Conciliados» el período es la fecha de alta del
  /// talonario en el Bosque y en «Sin talonario» es la del documento en SAP.
  /// Son universos distintos; arrastrar un rango de uno al otro da un
  /// resultado sin sentido y sin aviso.
  DateTimeRange? _periodo;
  DateTimeRange? _periodoDocSap;
  bool _incluirCerrados = false;
  BigInt? _codTalonario;
  String _origenSap = 'cobros';

  /// Custodia: 'S' sucursales, 'E' personal, null ambos.
  String? _tipoDest;

  /// Custodia: deja solo lo que lleva N o más días en poder de alguien.
  int? _diasMinimos;

  /// Custodia: con true entran también las entregas ya cerradas.
  bool _custodiaHistorica = false;
  String _accionSap = 'A';

  bool get _esSinTalonario =>
      _elegido == _Reporte.conciliacion && _accionSap == 'D';

  /// El período que corresponde al modo activo.
  DateTimeRange? get _periodoActivo =>
      _esSinTalonario ? _periodoDocSap : _periodo;

  bool _ocupado = false;
  Object? _error;

  // ── Generación ────────────────────────────────────────────────────────────

  Future<void> _generar() async {
    if (_elegido == _Reporte.ficha && _codTalonario == null) {
      setState(
        () => _error = 'Elija el talonario del que quiere la ficha.',
      );
      return;
    }

    setState(() {
      _ocupado = true;
      _error = null;
    });

    try {
      final repo = ref.read(talonariosRepositoryProvider);
      final Uint8List bytes;

      switch (_elegido) {
        case _Reporte.inventario:
          bytes = await repo.reporteInventario(
            codTipoRecibo: _codTipoRecibo,
            codEmpresa: _codEmpresa == null ? null : BigInt.from(_codEmpresa!),
            codGrupo: _codGrupo,
            codEstadoActual: _codEstadoActual,
            desde: _periodo?.start,
            hasta: _periodo?.end,
            incluirCerrados: _incluirCerrados,
          );
        case _Reporte.trazabilidad:
          bytes = await repo.reporteTrazabilidad(
            codTipoRecibo: _codTipoRecibo,
            codEmpresa: _codEmpresa == null ? null : BigInt.from(_codEmpresa!),
            desde: _periodo?.start,
            hasta: _periodo?.end,
          );
        case _Reporte.custodia:
          bytes = await repo.reporteCustodia(
            codTipoRecibo: _codTipoRecibo,
            codEmpresa: _codEmpresa == null ? null : BigInt.from(_codEmpresa!),
            tipoDestinatario: _tipoDest,
            diasMinimos: _diasMinimos,
            desde: _periodo?.start,
            hasta: _periodo?.end,
            incluirCerrados: _custodiaHistorica,
          );
        case _Reporte.ficha:
          bytes = await repo.reporteFicha(_codTalonario!);
        case _Reporte.conciliacion:
          // En «Sin talonario» empresa y tipo no viajan: el backend los
          // ignora igual, y mandarlos haría que el subtítulo del PDF
          // anunciara un recorte que no ocurre.
          bytes = await repo.reporteConciliacionSap(
            origen: _origenSap,
            accionSap: _accionSap,
            codEmpresa:
                _codEmpresa == null ? null : BigInt.from(_codEmpresa!),
            codTipoRecibo: _esSinTalonario ? null : _codTipoRecibo,
            desde: _periodoActivo?.start,
            hasta: _periodoActivo?.end,
          );
      }

      if (!mounted) return;
      setState(() => _ocupado = false);
      await mostrarPdf(
        context,
        bytes: bytes,
        titulo: _elegido.titulo,
        nombreArchivo: _nombreArchivo(),
      );
    } catch (e) {
      // El panel se queda abierto con los filtros puestos: rearmarlos después
      // de un error de red sería castigar al usuario por algo que no hizo.
      if (!mounted) return;
      setState(() {
        _error = e;
        _ocupado = false;
      });
    }
  }

  /// El backend manda los bytes pelados, sin `Content-Disposition`: el nombre
  /// lo pone el front, que es quien sabe con qué filtros se pidió.
  String _nombreArchivo() {
    final hoy = DateTime.now();
    final sello =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-'
        '${hoy.day.toString().padLeft(2, '0')}';
    final base = switch (_elegido) {
      _Reporte.inventario => 'talonarios-inventario',
      _Reporte.trazabilidad => 'talonarios-trazabilidad',
      _Reporte.custodia => 'talonarios-custodia',
      _Reporte.ficha => 'talonario-ficha',
      _Reporte.conciliacion => 'talonarios-sap-$_origenSap',
    };
    return '$base-$sello.pdf';
  }

  // ── Armado ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tam = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: EdgeInsets.all(tam.width < 600 ? Esp.s : Esp.xl),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: tam.height * 0.9,
        ),
        child: LayoutBuilder(
          builder: (context, caja) {
            // El aire se mide sobre la caja del diálogo y no sobre la ventana:
            // adentro de un Dialog con maxWidth, MediaQuery miente.
            final aire = Aire.de(caja.maxWidth);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _cabecera(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Esp.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _selectorDeReporte(aire),
                        const SizedBox(height: Esp.l),
                        const Divider(height: 1),
                        const SizedBox(height: Esp.l),
                        Text('Filtros', style: context.tituloSeccion()),
                        const SizedBox(height: Esp.m),
                        ..._filtrosDelReporte(aire),
                        if (_error != null) ...[
                          const SizedBox(height: Esp.m),
                          MensajeError(error: _error, compacto: true),
                        ],
                      ],
                    ),
                  ),
                ),
                _pie(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cabecera() {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Esp.l,
        vertical: Esp.m,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        children: [
          Icon(Icons.summarize_outlined, color: cs.onPrimaryContainer),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Text(
              'Reportes de talonarios',
              style: TextStyle(
                fontWeight: Peso.titulo,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          // Se puede cerrar aunque esté generando: la conciliación con SAP
          // puede tardar minutos y dejar a alguien encerrado esperando un PDF
          // que quizá ya no quiere es peor que descartar el resultado. Si
          // termina después, el `mounted` de _generar corta antes de mostrarlo.
          IconButton(
            icon: const Icon(Icons.close),
            color: cs.onPrimaryContainer,
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Los cuatro siempre a la vista. Un asistente de dos pasos para una acción
  /// que se hace de una sola vez obliga a volver atrás solo para comparar.
  Widget _selectorDeReporte(Aire aire) => Column(
    children: [
      for (final r in _Reporte.values) ...[
        _TarjetaReporte(
          reporte: r,
          elegido: _elegido == r,
          compacto: aire.esChico,
          onElegir:
              _ocupado
                  ? null
                  : () => setState(() {
                    _elegido = r;
                    _error = null;
                  }),
        ),
        if (r != _Reporte.values.last) const SizedBox(height: Esp.s),
      ],
    ],
  );

  List<Widget> _filtrosDelReporte(Aire aire) => switch (_elegido) {
    _Reporte.inventario => [
      _comboTipo(),
      const SizedBox(height: Esp.m),
      _comboEmpresa(),
      const SizedBox(height: Esp.m),
      _comboGrupo(),
      const SizedBox(height: Esp.m),
      _comboEstado(),
      const SizedBox(height: Esp.m),
      _selectorPeriodo('Fecha de alta del talonario'),
      const SizedBox(height: Esp.s),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _incluirCerrados,
        title: const Text('Incluir los cerrados'),
        subtitle: Text(
          'Son estado terminal y hoy son más de la mitad de las filas.',
          style: context.apagado(),
        ),
        onChanged:
            _ocupado ? null : (v) => setState(() => _incluirCerrados = v),
      ),
    ],
    _Reporte.trazabilidad => [
      const NotaDelDato(
        texto:
            'Una fila por entrega, agrupadas por quien la recibió. Las que '
            'siguen sin devolver salen resaltadas.',
      ),
      const SizedBox(height: Esp.m),
      _comboTipo(),
      const SizedBox(height: Esp.m),
      _comboEmpresa(),
      const SizedBox(height: Esp.m),
      _selectorPeriodo('Fecha de la entrega'),
    ],
    _Reporte.custodia => [
      const NotaDelDato(
        texto:
            'Por defecto lista solo lo que sigue en poder de alguien, de lo más '
            'antiguo a lo más nuevo: es el orden en que conviene reclamar.',
      ),
      const SizedBox(height: Esp.m),
      Text('Quiénes', style: context.tituloSeccion()),
      const SizedBox(height: Esp.xs),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'T', label: Text('Todos')),
          ButtonSegment(value: 'S', label: Text('Sucursales')),
          ButtonSegment(value: 'E', label: Text('Personal')),
        ],
        selected: {_tipoDest ?? 'T'},
        onSelectionChanged:
            _ocupado
                ? null
                : (v) => setState(
                  () => _tipoDest = v.first == 'T' ? null : v.first,
                ),
      ),
      const SizedBox(height: Esp.m),
      // El corte por antigüedad es lo que vuelve accionable el reporte: hoy
      // 328 de las 364 custodias llevan más de un año, así que sin filtro
      // todo se ve igual de urgente.
      Text('Antigüedad mínima', style: context.tituloSeccion()),
      const SizedBox(height: Esp.xs),
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('Toda')),
          ButtonSegment(value: 180, label: Text('+6 meses')),
          ButtonSegment(value: 365, label: Text('+1 año')),
        ],
        selected: {_diasMinimos ?? 0},
        onSelectionChanged:
            _ocupado
                ? null
                : (v) => setState(
                  () => _diasMinimos = v.first == 0 ? null : v.first,
                ),
      ),
      const SizedBox(height: Esp.m),
      _comboEmpresa(),
      const SizedBox(height: Esp.m),
      _comboTipo(),
      const SizedBox(height: Esp.m),
      _selectorPeriodo('Fecha de la entrega'),
      const SizedBox(height: Esp.s),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _custodiaHistorica,
        title: const Text('Incluir lo ya devuelto o cerrado'),
        subtitle: Text(
          'Suma el historial completo de cada responsable, no solo lo pendiente.',
          style: context.apagado(),
        ),
        onChanged:
            _ocupado ? null : (v) => setState(() => _custodiaHistorica = v),
      ),
    ],
    _Reporte.ficha => [
      ComboBuscable<BigInt>(
        etiqueta: 'Talonario *',
        valor: _codTalonario,
        ayuda: 'Se listan los que están cargados en la pantalla.',
        opciones:
            widget.talonarios
                .map(
                  (t) => DropdownMenuEntry(
                    value: t.codTalonario,
                    label: '${t.nroTalonario} — ${t.estadoActual}',
                  ),
                )
                .toList(),
        onElegir:
            _ocupado
                ? (_) {}
                : (v) => setState(() {
                  _codTalonario = v;
                  _error = null;
                }),
      ),
    ],
    _Reporte.conciliacion => [
      Text('Qué documentos', style: context.tituloSeccion()),
      const SizedBox(height: Esp.xs),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'cobros', label: Text('Cobros')),
          ButtonSegment(value: 'salidas', label: Text('Salidas')),
        ],
        selected: {_origenSap},
        onSelectionChanged:
            _ocupado ? null : (s) => setState(() => _origenSap = s.first),
      ),
      const SizedBox(height: Esp.m),
      Text('Qué mostrar', style: context.tituloSeccion()),
      const SizedBox(height: Esp.xs),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'A', label: Text('Conciliados')),
          ButtonSegment(value: 'D', label: Text('Sin talonario')),
        ],
        selected: {_accionSap},
        onSelectionChanged:
            _ocupado ? null : (s) => setState(() => _accionSap = s.first),
      ),
      const SizedBox(height: Esp.m),

      // Los dos modos no admiten los mismos filtros, y no es que a uno le
      // falte implementarlos: en «Sin talonario» las filas no tienen
      // talonario, así que empresa y tipo —que son atributos del talonario—
      // no tienen sobre qué aplicarse. Se ocultan en vez de deshabilitarse:
      // un combo gris con un valor adentro se lee como filtro aplicado.
      if (_esSinTalonario) ...[
        const NotaDelDato(
          texto:
              'Estos documentos todavía no tienen talonario asignado, así que '
              'no se pueden acotar por tipo de recibo —el tipo es un dato del '
              'talonario—. Empresa y fechas sí, pero salen de SAP.',
        ),
        const SizedBox(height: Esp.m),
        // Se filtra por el NOMBRE que manda SAP y no por el código: en esta
        // rama el codEmpresa de las filas es un centinela. Si SAP escribe el
        // nombre distinto que el Bosque no va a matchear, y por eso la
        // etiqueta lo dice en vez de prometer una empresa a secas.
        _comboEmpresa(etiqueta: 'Empresa (según SAP)'),
        const SizedBox(height: Esp.m),
        // Ojo que es otra fecha: la del documento en SAP, no la del alta del
        // talonario en el Bosque.
        _selectorPeriodo('Fecha del documento en SAP'),
      ] else ...[
        const NotaDelDato(
          texto:
              'Lee SAP en vivo y recorre folio por folio, así que sin acotar no '
              'termina. Filtrá por empresa, tipo o fechas: se admiten hasta 80 '
              'talonarios por reporte.',
          tono: TonoNota.aviso,
        ),
        const SizedBox(height: Esp.m),
        _comboEmpresa(),
        const SizedBox(height: Esp.m),
        _comboTipo(),
        const SizedBox(height: Esp.m),
        _selectorPeriodo('Fecha de alta del talonario'),
      ],
    ],
  };

  // ── Piezas de filtro ──────────────────────────────────────────────────────

  Widget _comboTipo() {
    final tipos = ref.watch(tiposReciboProvider);
    return tipos.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error:
          (e, _) => MensajeError(
            error: e,
            compacto: true,
            onReintentar: () => ref.invalidate(tiposReciboProvider),
          ),
      data:
          (lista) => ComboBuscable<BigInt>(
            etiqueta: 'Tipo de recibo',
            valor: _codTipoRecibo,
            ayuda: 'Vacío: todos los tipos.',
            opciones:
                lista
                    .map(
                      (x) => DropdownMenuEntry(
                        value: x.codTipoRecibo,
                        label: '${x.sigla} — ${x.nombre}',
                      ),
                    )
                    .toList(),
            onElegir:
                _ocupado
                    ? (_) {}
                    : (v) => setState(() => _codTipoRecibo = v),
          ),
    );
  }

  Widget _comboEmpresa({String etiqueta = 'Empresa'}) {
    final empresas = ref.watch(empresasProvider);
    return empresas.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error:
          (e, _) => MensajeError(
            error: e,
            compacto: true,
            onReintentar: () => ref.invalidate(empresasProvider),
          ),
      data:
          (lista) => ComboBuscable<int>(
            etiqueta: etiqueta,
            valor: _codEmpresa,
            ayuda: 'Vacío: todas. El reporte agrupa por empresa igual.',
            opciones:
                lista
                    .map(
                      (e) => DropdownMenuEntry(
                        value: e.codEmpresa,
                        label: e.nombre,
                      ),
                    )
                    .toList(),
            onElegir:
                _ocupado ? (_) {} : (v) => setState(() => _codEmpresa = v),
          ),
    );
  }

  Widget _comboGrupo() {
    final grupos = ref.watch(talonarioGruposProvider);
    return grupos.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error:
          (e, _) => MensajeError(
            error: e,
            compacto: true,
            onReintentar: () => ref.invalidate(talonarioGruposProvider),
          ),
      data:
          (lista) => ComboBuscable<BigInt>(
            etiqueta: 'Grupo',
            valor: _codGrupo,
            ayuda: 'Vacío: todos los grupos.',
            opciones:
                lista
                    .map(
                      (g) => DropdownMenuEntry(
                        value: g.codGrupo,
                        label: g.nombre,
                      ),
                    )
                    .toList(),
            onElegir:
                _ocupado ? (_) {} : (v) => setState(() => _codGrupo = v),
          ),
    );
  }

  Widget _comboEstado() => ComboBuscable<int>(
    etiqueta: 'Estado',
    valor: _codEstadoActual,
    ayuda: 'Vacío: todos. El reporte desglosa por estado igual.',
    opciones: const [
      DropdownMenuEntry(value: 1, label: 'Adquirido'),
      DropdownMenuEntry(value: 2, label: 'Entregado'),
      DropdownMenuEntry(value: 3, label: 'Devuelto'),
      DropdownMenuEntry(value: 4, label: 'Cerrado'),
    ],
    onElegir:
        _ocupado ? (_) {} : (v) => setState(() => _codEstadoActual = v),
  );

  Widget _selectorPeriodo(String ayuda) {
    final p = _periodoActivo;
    void guardar(DateTimeRange? r) => setState(() {
      if (_esSinTalonario) {
        _periodoDocSap = r;
      } else {
        _periodo = r;
      }
    });
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Período',
        helperText: ayuda,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              p == null
                  ? 'Sin límite de fechas'
                  : '${fechaCorta(p.start)} — ${fechaCorta(p.end)}',
              style: const TextStyle(fontFeatures: cifrasTabulares),
            ),
          ),
          if (p != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Quitar el período',
              onPressed: _ocupado ? null : () => guardar(null),
            ),
          IconButton(
            icon: const Icon(Icons.date_range, size: 20),
            tooltip: 'Elegir período',
            onPressed:
                _ocupado
                    ? null
                    : () async {
                      final r = await pedirRangoDeFechas(
                        context,
                        titulo: 'Período',
                        explicacion: ayuda,
                        desde: p?.start,
                        hasta: p?.end,
                        minima: DateTime(2019),
                        maxima: DateTime.now(),
                        textoAceptar: 'Aplicar',
                        iconoAceptar: Icons.filter_alt_outlined,
                      );
                      if (r != null && mounted) {
                        guardar(
                          DateTimeRange(start: r.desde, end: r.hasta),
                        );
                      }
                    },
          ),
        ],
      ),
    );
  }

  Widget _pie() => Padding(
    padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.m),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        const SizedBox(width: Esp.s),
        BotonAccion(
          etiqueta: 'Ver PDF',
          etiquetaOcupado: 'Generando…',
          ocupado: _ocupado,
          onPressed: _generar,
        ),
      ],
    ),
  );
}

/// Una opción del selector. Card plano a propósito: la sombra de elevación por
/// tarjeta es cara en Flutter Web y acá hay cuatro siempre visibles.
class _TarjetaReporte extends StatelessWidget {
  const _TarjetaReporte({
    required this.reporte,
    required this.elegido,
    required this.compacto,
    required this.onElegir,
  });

  final _Reporte reporte;
  final bool elegido;
  final bool compacto;
  final VoidCallback? onElegir;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: elegido ? cs.secondaryContainer : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(Esquina.media),
      child: InkWell(
        onTap: onElegir,
        borderRadius: BorderRadius.circular(Esquina.media),
        child: Container(
          padding: const EdgeInsets.all(Esp.m),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Esquina.media),
            // Sin borde cuando no está elegido, en vez de uno transparente: el
            // proyecto no usa Colors.* en ningún lado para que los nueve
            // colores de marca y el modo oscuro sigan mandando.
            border:
                elegido
                    ? Border.all(color: cs.primary, width: 1.5)
                    : null,
          ),
          child: Row(
            children: [
              Icon(
                reporte.icono,
                size: 20,
                color:
                    elegido ? cs.onSecondaryContainer : cs.onSurfaceVariant,
              ),
              const SizedBox(width: Esp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reporte.titulo,
                      style: TextStyle(
                        fontWeight: elegido ? Peso.dato : Peso.titulo,
                        color:
                            elegido
                                ? cs.onSecondaryContainer
                                : cs.onSurface,
                      ),
                    ),
                    if (!compacto) ...[
                      const SizedBox(height: 2),
                      Text(reporte.detalle, style: context.apagado()),
                    ],
                  ],
                ),
              ),
              if (elegido)
                Icon(Icons.check_circle, size: 18, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}
