/// El detalle de un lote de produccion: cabecera, balance y las tres tablas
/// del corte —ingreso, salida y merma—.
///
/// Guardar cierra el lote. Es la regla del sistema anterior: un lote se corrige
/// mientras esta abierto y despues solo lo reabre quien tenga el permiso.
library;

import 'package:bosque_flutter/core/state/ver_lote_produccion_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/material_ingreso_entity.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/balance_lote.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre el detalle de [lote]. Devuelve true si se guardo algo.
Future<bool> abrirDetalleLote(
  BuildContext context, {
  required LoteProduccionEntity lote,
  required int audUsuario,
  required bool soloLectura,
}) async {
  final guardado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DetalleLoteDialog(
      lote: lote,
      audUsuario: audUsuario,
      soloLectura: soloLectura,
    ),
  );
  return guardado ?? false;
}

class DetalleLoteDialog extends ConsumerStatefulWidget {
  const DetalleLoteDialog({
    super.key,
    required this.lote,
    required this.audUsuario,
    required this.soloLectura,
  });

  final LoteProduccionEntity lote;
  final int audUsuario;

  /// El lote esta cerrado y quien mira no tiene permiso para reabrirlo.
  final bool soloLectura;

  @override
  ConsumerState<DetalleLoteDialog> createState() => _DetalleLoteDialogState();
}

class _DetalleLoteDialogState extends ConsumerState<DetalleLoteDialog> {
  DetalleLoteParams get _params =>
      (idLp: widget.lote.idLp, audUsuario: widget.audUsuario);

  @override
  void initState() {
    super.initState();
    // El lote ya viene del listado; el provider solo carga el detalle. Se pasa
    // una copia para que cancelar no deje cambios a la vista en la lista.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(detalleLoteProvider(_params).notifier)
          .setLote(widget.lote.clonar());
    });
  }

  Future<void> _guardar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_outline, size: 36),
        title: const Text('Guardar y cerrar el lote'),
        content: const Text(
          'Al guardar, el lote queda cerrado y deja de estar disponible para '
          'edicion. Solo podra reabrirlo quien tenga permiso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar y cerrar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final error = await ref.read(detalleLoteProvider(_params).notifier).guardar();
    if (!mounted) return;

    if (error != null) {
      avisar(context, error, esError: true);
      return;
    }
    avisar(context, 'Cambios guardados. El lote quedo cerrado.');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(detalleLoteProvider(_params));
    final notifier = ref.read(detalleLoteProvider(_params).notifier);
    final lote = estado.lote ?? widget.lote;

    return LayoutBuilder(
      builder: (context, restricciones) {
        final aire = Aire.de(restricciones.maxWidth);
        final margen = aire.esChico ? Esp.s : Esp.xxl;

        return Dialog(
          insetPadding: EdgeInsets.all(margen),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Cabecera(
                  lote: lote,
                  soloLectura: widget.soloLectura,
                  onCerrar: () => Navigator.pop(context, false),
                ),
                if (estado.cargando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: CircularProgressIndicator(),
                  )
                else
                  Flexible(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        aire.esChico ? Esp.m : Esp.xl,
                        Esp.l,
                        aire.esChico ? Esp.m : Esp.xl,
                        Esp.xl,
                      ),
                      children: [
                        BarraDeBalance(
                          kilosIngreso: estado.totalPesoIngreso,
                          kilosSalida: estado.totalPesoMaterial,
                          kilosMerma: estado.totalMerma,
                          diferencia: estado.difProduccion,
                          resmasContadas: estado.totalCantResma,
                          resmasEstimadas: estado.cantEstimadaResma,
                        ),
                        if (estado.salidas.isNotEmpty &&
                            estado.cantEstimadaResma <= 0) ...[
                          SizedBox(height: Esp.m),
                          const AvisoSinUtm(),
                        ],
                        SizedBox(height: Esp.xl),
                        _Identificacion(
                          lote: lote,
                          estado: estado,
                          notifier: notifier,
                          aire: aire,
                          soloLectura: widget.soloLectura,
                        ),
                        SizedBox(height: Esp.xl),
                        _SeccionIngreso(
                          estado: estado,
                          notifier: notifier,
                          aire: aire,
                          soloLectura: widget.soloLectura,
                        ),
                        SizedBox(height: Esp.xl),
                        _SeccionSalida(
                          estado: estado,
                          notifier: notifier,
                          aire: aire,
                          soloLectura: widget.soloLectura,
                        ),
                        SizedBox(height: Esp.xl),
                        _SeccionMerma(
                          estado: estado,
                          notifier: notifier,
                          aire: aire,
                          soloLectura: widget.soloLectura,
                        ),
                      ],
                    ),
                  ),
                if (!widget.soloLectura && !estado.cargando)
                  _BarraAcciones(
                    guardando: estado.guardando,
                    onCancelar: () => Navigator.pop(context, false),
                    onGuardar: _guardar,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA
// ═══════════════════════════════════════════════════════════════════════════

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.lote,
    required this.soloLectura,
    required this.onCerrar,
  });

  final LoteProduccionEntity lote;
  final bool soloLectura;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final abierto = lote.estado == 1;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(Esp.xl, Esp.l, Esp.m, Esp.l),
      color: cs.surfaceContainerHigh,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lote de produccion', style: context.apagado()),
                SizedBox(height: Esp.xs),
                Row(
                  children: [
                    Text(
                      '${lote.numLote}/${lote.anio}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: Peso.dato,
                            fontFeatures: cifrasTabulares,
                          ),
                    ),
                    SizedBox(width: Esp.m),
                    Etiqueta(
                      texto: abierto ? 'Abierto' : 'Cerrado',
                      tono: abierto
                          ? TonoEtiqueta.exito
                          : TonoEtiqueta.neutro,
                    ),
                    if (soloLectura) ...[
                      SizedBox(width: Esp.s),
                      const Etiqueta(
                        texto: 'Solo lectura',
                        tono: TonoEtiqueta.aviso,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
            onPressed: onCerrar,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// IDENTIFICACION
// ═══════════════════════════════════════════════════════════════════════════

class _Identificacion extends StatelessWidget {
  const _Identificacion({
    required this.lote,
    required this.estado,
    required this.notifier,
    required this.aire,
    required this.soloLectura,
  });

  final LoteProduccionEntity lote;
  final DetalleLoteState estado;
  final DetalleLoteNotifier notifier;
  final Aire aire;
  final bool soloLectura;

  @override
  Widget build(BuildContext context) {
    final columnas = aire.esChico ? 1 : (aire == Aire.medio ? 2 : 3);

    final campos = <Widget>[
      DropdownButtonFormField<int>(
        value: estado.maquinas.any((m) => m.idMa == lote.idMa)
            ? lote.idMa
            : null,
        decoration: const InputDecoration(
          labelText: 'Maquina',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          for (final m in estado.maquinas)
            DropdownMenuItem(value: m.idMa, child: Text(m.descripcion)),
        ],
        onChanged: soloLectura ? null : (v) => notifier.setMaquina(v ?? 0),
      ),
      _CampoFechaLote(
        fecha: lote.fecha,
        habilitado: !soloLectura,
        onCambio: notifier.setFecha,
      ),
      _CampoHora(
        etiqueta: 'Hora inicio corte',
        valor: lote.hraInicioCorte,
        habilitado: !soloLectura,
        onCambio: (v) => notifier.setHoras(inicioCorte: v),
      ),
      _CampoHora(
        etiqueta: 'Hora inicio',
        valor: lote.hraInicio,
        habilitado: !soloLectura,
        onCambio: (v) => notifier.setHoras(inicio: v),
      ),
      _CampoHora(
        etiqueta: 'Hora fin',
        valor: lote.hraFin,
        habilitado: !soloLectura,
        onCambio: (v) => notifier.setHoras(fin: v),
      ),
      _CampoTexto(
        etiqueta: 'Orden de fabricacion',
        valor: lote.docNumOrdFab == 0 ? '' : lote.docNumOrdFab.toString(),
        habilitado: !soloLectura,
        soloEnteros: true,
        onCambio: (v) => notifier.setOrdenFabricacion(int.tryParse(v) ?? 0),
      ),
      DropdownButtonFormField<int>(
        value: estado.empresas.any((e) => e.codEmpresa == lote.codEmpresa)
            ? lote.codEmpresa
            : null,
        decoration: const InputDecoration(
          labelText: 'Empresa',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          for (final e in estado.empresas)
            DropdownMenuItem(value: e.codEmpresa, child: Text(e.nombre)),
        ],
        onChanged: soloLectura ? null : (v) => notifier.setEmpresa(v ?? 0),
      ),
    ];

    return _Seccion(
      titulo: 'Identificacion',
      ayuda: 'La orden de fabricacion y la empresa vinculan el lote con SAP.',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Rejilla(columnas: columnas, hijos: campos),
          SizedBox(height: Esp.m),
          _CampoTexto(
            etiqueta: 'Observaciones',
            valor: lote.obs,
            habilitado: !soloLectura,
            lineas: 2,
            onCambio: notifier.setObservacion,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INGRESO / SALIDA / MERMA
// ═══════════════════════════════════════════════════════════════════════════

class _SeccionIngreso extends StatelessWidget {
  const _SeccionIngreso({
    required this.estado,
    required this.notifier,
    required this.aire,
    required this.soloLectura,
  });

  final DetalleLoteState estado;
  final DetalleLoteNotifier notifier;
  final Aire aire;
  final bool soloLectura;

  @override
  Widget build(BuildContext context) => _Seccion(
    titulo: 'Material de ingreso',
    ayuda:
        '${estado.ingresos.length} bobinas  ·  '
        '${fmtNumero.format(estado.totalPesoIngreso)} kg  ·  '
        'balanza ${fmtNumero.format(estado.totalBalanza)} kg',
    // Esa linea de arriba es la que contesta: agregar una bobina la mueve en el
    // acto —igual que a la barra de balance— porque los tres numeros salen de
    // la lista de filas y no de la cabecera guardada.
    accion: soloLectura
        ? null
        : OutlinedButton.icon(
            onPressed: notifier.agregarIngreso,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar bobina'),
          ),
    encabezado: _SelectorArticulo(
      etiqueta: 'Articulo de ingreso',
      valor: estado.codArticuloIngreso,
      articulos: estado.articulos,
      habilitado: !soloLectura,
      onCambio: notifier.setArticuloIngreso,
    ),
    hijo: estado.ingresos.isEmpty
        ? _SinFilas(
            texto: soloLectura
                ? 'Este lote no tiene bobinas registradas.'
                : 'Este lote no tiene bobinas registradas. '
                      'Agrega la primera con el boton de arriba.',
          )
        : _Filas(
            aire: aire,
            columnas: const ['Peso (kg)', 'Balanza (kg)', 'Nro. importacion'],
            anchos: const [1, 1, 1],
            cantidad: estado.ingresos.length,
            titulo: (i) => 'Bobina ${i + 1}',
            // Solo se puede quitar lo que todavia no viajo: el backend no tiene
            // baja para el material de ingreso —elige entre insertar y
            // actualizar segun el idMi—, asi que una bobina que ya esta en la
            // base no se borra desde aqui. Esto deshace un boton de mas.
            accionFila: soloLectura
                ? null
                : (i) => estado.ingresos[i].idMi != 0
                      ? null
                      : IconButton(
                          tooltip: 'Quitar esta bobina',
                          onPressed: () => notifier.quitarIngreso(i),
                          icon: const Icon(Icons.delete_outline, size: 18),
                        ),
            celda: (i, columna) {
              final fila = estado.ingresos[i];
              final clave = _claveDeIngreso(estado.ingresos, i);
              final nueva = fila.idMi == 0;
              return switch (columna) {
                0 => _CampoTexto(
                  key: ValueKey('mi-peso-$clave'),
                  etiqueta: aire.esChico ? 'Peso (kg)' : null,
                  valor: _valorInicial(fila.pesoKilos, nueva),
                  habilitado: !soloLectura,
                  onCambio: (v) => notifier.editarIngreso(
                    i,
                    pesoKilos: double.tryParse(v) ?? 0,
                  ),
                ),
                1 => _CampoTexto(
                  key: ValueKey('mi-balanza-$clave'),
                  etiqueta: aire.esChico ? 'Balanza (kg)' : null,
                  valor: _valorInicial(fila.balanza, nueva),
                  habilitado: !soloLectura,
                  onCambio: (v) =>
                      notifier.editarIngreso(i, balanza: double.tryParse(v) ?? 0),
                ),
                _ => _CampoTexto(
                  key: ValueKey('mi-imp-$clave'),
                  etiqueta: aire.esChico ? 'Nro. importacion' : null,
                  valor: fila.numImportacion,
                  habilitado: !soloLectura,
                  soloNumeros: false,
                  onCambio: (v) => notifier.editarIngreso(i, numImportacion: v),
                ),
              };
            },
          ),
  );
}

/// Con que se identifica una fila de ingreso entre dibujos.
///
/// `idMi` solo no alcanza desde que se pueden agregar bobinas: las filas nuevas
/// valen todas 0 hasta que se guardan, y `_CampoTexto` se queda con el texto
/// que le toco la primera vez, asi que dos campos con la misma clave terminan
/// mostrando lo mismo. Las nuevas se numeran por su orden entre las nuevas, que
/// no cambia mientras la fila exista: se agregan al final y solo se quitan las
/// que todavia no viajaron.
String _claveDeIngreso(List<MaterialIngresoEntity> filas, int indice) {
  if (filas[indice].idMi != 0) return '${filas[indice].idMi}';
  var nuevas = 0;
  for (var i = 0; i <= indice; i++) {
    if (filas[i].idMi == 0) nuevas++;
  }
  return 'nueva-$nuevas';
}

/// El texto con el que arranca un campo numerico del ingreso.
///
/// Una bobina recien agregada no pesa cero: todavia no pesa nada. Arrancar en
/// «0.0» obliga a borrarlo antes de escribir, y a quien se olvida le queda
/// «0614» cargado.
String _valorInicial(double valor, bool filaNueva) =>
    filaNueva && valor == 0 ? '' : valor.toString();

class _SeccionSalida extends StatelessWidget {
  const _SeccionSalida({
    required this.estado,
    required this.notifier,
    required this.aire,
    required this.soloLectura,
  });

  final DetalleLoteState estado;
  final DetalleLoteNotifier notifier;
  final Aire aire;
  final bool soloLectura;

  @override
  Widget build(BuildContext context) => _Seccion(
    titulo: 'Material de salida',
    ayuda:
        '${fmtEntero.format(estado.totalCantResma)} resmas  ·  '
        '${fmtEntero.format(estado.totalCantHojas)} hojas  ·  '
        '${fmtNumero.format(estado.totalPesoMaterial)} kg de material',
    encabezado: _SelectorArticulo(
      etiqueta: 'Articulo de salida',
      valor: estado.codArticuloSalida,
      articulos: estado.articulos,
      habilitado: !soloLectura,
      onCambio: notifier.setArticuloSalida,
    ),
    hijo: estado.salidas.isEmpty
        ? const _SinFilas(texto: 'Este lote no tiene paletas registradas.')
        : _Filas(
            aire: aire,
            columnas: const [
              'Nro. paleta',
              'Peso resma',
              'Peso paleta',
              'Peso material',
              'Resmas',
              'Hojas',
            ],
            anchos: const [1, 1, 1, 1, 1, 1],
            cantidad: estado.salidas.length,
            titulo: (i) => 'Paleta ${estado.salidas[i].nroPaleta}',
            celda: (i, columna) {
              final fila = estado.salidas[i];
              final k = fila.idMs;
              return switch (columna) {
                0 => _CampoTexto(
                  key: ValueKey('ms-paleta-$k'),
                  etiqueta: aire.esChico ? 'Nro. paleta' : null,
                  valor: fila.nroPaleta.toString(),
                  habilitado: !soloLectura,
                  soloEnteros: true,
                  onCambio: (v) =>
                      notifier.editarSalida(i, nroPaleta: int.tryParse(v) ?? 0),
                ),
                1 => _CampoTexto(
                  key: ValueKey('ms-presma-$k'),
                  etiqueta: aire.esChico ? 'Peso resma' : null,
                  valor: fila.pesoResma.toString(),
                  habilitado: !soloLectura,
                  onCambio: (v) => notifier.editarSalida(
                    i,
                    pesoResma: double.tryParse(v) ?? 0,
                  ),
                ),
                2 => _CampoTexto(
                  key: ValueKey('ms-ppaleta-$k'),
                  etiqueta: aire.esChico ? 'Peso paleta' : null,
                  valor: fila.pesoPaleta.toString(),
                  habilitado: !soloLectura,
                  onCambio: (v) => notifier.editarSalida(
                    i,
                    pesoPaleta: double.tryParse(v) ?? 0,
                  ),
                ),
                3 => _CampoTexto(
                  key: ValueKey('ms-pmat-$k'),
                  etiqueta: aire.esChico ? 'Peso material' : null,
                  valor: fila.pesoMaterial.toString(),
                  habilitado: !soloLectura,
                  onCambio: (v) => notifier.editarSalida(
                    i,
                    pesoMaterial: double.tryParse(v) ?? 0,
                  ),
                ),
                4 => _CampoTexto(
                  key: ValueKey('ms-resmas-$k'),
                  etiqueta: aire.esChico ? 'Resmas' : null,
                  valor: fila.cantidadResma.toString(),
                  habilitado: !soloLectura,
                  soloEnteros: true,
                  onCambio: (v) => notifier.editarSalida(
                    i,
                    cantidadResma: int.tryParse(v) ?? 0,
                  ),
                ),
                _ => _CampoTexto(
                  key: ValueKey('ms-hojas-$k'),
                  etiqueta: aire.esChico ? 'Hojas' : null,
                  valor: fila.cantidadHojas.toString(),
                  habilitado: !soloLectura,
                  soloEnteros: true,
                  onCambio: (v) => notifier.editarSalida(
                    i,
                    cantidadHojas: int.tryParse(v) ?? 0,
                  ),
                ),
              };
            },
          ),
  );
}

class _SeccionMerma extends StatelessWidget {
  const _SeccionMerma({
    required this.estado,
    required this.notifier,
    required this.aire,
    required this.soloLectura,
  });

  final DetalleLoteState estado;
  final DetalleLoteNotifier notifier;
  final Aire aire;
  final bool soloLectura;

  @override
  Widget build(BuildContext context) => _Seccion(
    titulo: 'Merma',
    ayuda: '${fmtNumero.format(estado.totalMerma)} kg en total',
    hijo: estado.mermas.isEmpty
        ? const _SinFilas(texto: 'Este lote no tiene merma registrada.')
        : _Filas(
            aire: aire,
            columnas: const ['Codigo', 'Descripcion', 'Peso (kg)'],
            anchos: const [1, 3, 1],
            cantidad: estado.mermas.length,
            titulo: (i) => estado.mermas[i].codArticulo,
            celda: (i, columna) {
              final fila = estado.mermas[i];
              return switch (columna) {
                0 => Text(fila.codArticulo, style: context.numero()),
                1 => Text(
                  fila.descripcion,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                _ => _CampoTexto(
                  key: ValueKey('me-peso-${fila.idMe}'),
                  etiqueta: aire.esChico ? 'Peso (kg)' : null,
                  valor: fila.peso.toString(),
                  habilitado: !soloLectura,
                  onCambio: (v) =>
                      notifier.editarMerma(i, double.tryParse(v) ?? 0),
                ),
              };
            },
          ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS DE ARMADO
// ═══════════════════════════════════════════════════════════════════════════

/// Una seccion con su titulo, una linea de totales y su contenido.
class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.hijo,
    this.ayuda,
    this.encabezado,
    this.accion,
  });

  final String titulo;
  final String? ayuda;

  /// Lo que se puede hacerle a la seccion entera. Va arriba a la derecha,
  /// enfrentado al titulo: es una accion sobre la tabla, no sobre una fila.
  final Widget? accion;

  final Widget? encabezado;
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      padding: EdgeInsets.all(Esp.l),
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
                    Text(titulo, style: context.tituloSeccion()),
                    if (ayuda != null) ...[
                      SizedBox(height: Esp.xs),
                      Text(ayuda!, style: context.apagado()),
                    ],
                  ],
                ),
              ),
              if (accion != null) accion!,
            ],
          ),
          if (encabezado != null) ...[
            SizedBox(height: Esp.m),
            encabezado!,
          ],
          SizedBox(height: Esp.m),
          hijo,
        ],
      ),
    );
  }
}

/// Campos en rejilla, con el ancho repartido en [columnas].
class _Rejilla extends StatelessWidget {
  const _Rejilla({required this.columnas, required this.hijos});

  final int columnas;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, restricciones) {
      final separacion = Esp.m;
      final ancho =
          (restricciones.maxWidth - separacion * (columnas - 1)) / columnas;
      return Wrap(
        spacing: separacion,
        runSpacing: separacion,
        children: [
          for (final h in hijos) SizedBox(width: ancho, child: h),
        ],
      );
    },
  );
}

/// Las filas de una tabla del detalle.
///
/// En pantalla ancha es una tabla con encabezado; en pantalla angosta cada fila
/// se convierte en una tarjeta con sus campos etiquetados, porque seis columnas
/// de numeros no entran en un telefono sin volverse ilegibles.
class _Filas extends StatelessWidget {
  const _Filas({
    required this.aire,
    required this.columnas,
    required this.anchos,
    required this.cantidad,
    required this.titulo,
    required this.celda,
    this.accionFila,
  });

  final Aire aire;
  final List<String> columnas;
  final List<int> anchos;
  final int cantidad;
  final String Function(int fila) titulo;
  final Widget Function(int fila, int columna) celda;

  /// Lo que se puede hacerle a una fila. Devolver null deja el hueco sin
  /// dibujar; devolverlo solo para algunas filas es lo normal, porque no todas
  /// admiten lo mismo.
  final Widget? Function(int fila)? accionFila;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (aire.esChico) {
      return Column(
        children: [
          for (var i = 0; i < cantidad; i++)
            Container(
              margin: EdgeInsets.only(bottom: Esp.s),
              padding: EdgeInsets.all(Esp.m),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Esquina.chica),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo(i),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: Peso.titulo),
                        ),
                      ),
                      if (accionFila?.call(i) case final accion?) accion,
                    ],
                  ),
                  SizedBox(height: Esp.s),
                  for (var c = 0; c < columnas.length; c++)
                    Padding(
                      padding: EdgeInsets.only(bottom: Esp.s),
                      child: celda(i, c),
                    ),
                ],
              ),
            ),
        ],
      );
    }

    // El ancho se fija con un SizedBox y no con un ConstrainedBox: adentro de
    // un scroll horizontal las restricciones llegan sin tope, y un `Expanded`
    // con ancho infinito no es un desborde feo, es una excepcion en tiempo de
    // ejecucion. Con el ancho resuelto aqui, la tabla llena el hueco cuando
    // entra y scrollea cuando no.
    // El hueco de la accion se reserva de entrada, mire o no alguna fila: si
    // apareciera y desapareciera con las filas, la tabla se correria de lugar
    // cada vez que se agrega una bobina.
    final anchoAccion = accionFila == null ? 0.0 : 48.0;
    final anchoMinimo = 140.0 * columnas.length + 90 + anchoAccion;

    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth > anchoMinimo
            ? restricciones.maxWidth
            : anchoMinimo;

        return ScrollConfiguration(
          behavior: const ArrastreLateral(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: ancho,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: Esp.s),
                    child: Row(
                      children: [
                        const SizedBox(width: 90),
                        for (var c = 0; c < columnas.length; c++)
                          Expanded(
                            flex: anchos[c],
                            child: Padding(
                              padding: EdgeInsets.only(right: Esp.m),
                              child: Text(
                                columnas[c],
                                style: context.apagado(),
                              ),
                            ),
                          ),
                        if (accionFila != null) SizedBox(width: anchoAccion),
                      ],
                    ),
                  ),
                  for (var i = 0; i < cantidad; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: Esp.s),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(
                              titulo(i),
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: Peso.titulo),
                            ),
                          ),
                          for (var c = 0; c < columnas.length; c++)
                            Expanded(
                              flex: anchos[c],
                              child: Padding(
                                padding: EdgeInsets.only(right: Esp.m),
                                child: celda(i, c),
                              ),
                            ),
                          if (accionFila != null)
                            SizedBox(
                              width: anchoAccion,
                              child: accionFila!(i),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SinFilas extends StatelessWidget {
  const _SinFilas({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: Esp.m),
    child: Text(texto, style: context.apagado()),
  );
}

/// El articulo que se aplica a todas las filas de una tabla.
///
/// **Por que no un `DropdownMenu`.** El catalogo tiene 2.356 articulos y
/// `DropdownMenu` no es una lista perezosa: arma y mide un boton por entrada
/// cada vez que se abre y en cada tecla del filtro. Con `Autocomplete` la lista
/// de resultados es un `ListView.builder`, asi que solo se construye lo que se
/// ve. Es el mismo componente que usa la pantalla de registro.
///
/// La lista llega ya ordenada desde `articulosProduccionProvider`: ordenarla
/// aqui costaba un sort de 2.356 elementos por cada tecla escrita en cualquier
/// campo del formulario, porque el dialogo entero se redibuja.
class _SelectorArticulo extends StatelessWidget {
  const _SelectorArticulo({
    required this.etiqueta,
    required this.valor,
    required this.articulos,
    required this.habilitado,
    required this.onCambio,
  });

  final String etiqueta;
  final String valor;
  final List<LoteProduccionEntity> articulos;
  final bool habilitado;
  final ValueChanged<String> onCambio;

  String? get _textoActual {
    for (final a in articulos) {
      if (a.codArticulo == valor) return a.articulo;
    }
    return valor.isEmpty ? null : valor;
  }

  @override
  Widget build(BuildContext context) {
    if (!habilitado) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          isDense: true,
          enabled: false,
        ),
        child: Text(_textoActual ?? '--', overflow: TextOverflow.ellipsis),
      );
    }

    return Autocomplete<LoteProduccionEntity>(
      displayStringForOption: (a) => a.articulo,
      initialValue: TextEditingValue(text: _textoActual ?? ''),
      optionsMaxHeight: 320,
      // Se materializa con toList(): `Autocomplete` consulta length y elementAt
      // por cada fila visible, y sobre un iterable perezoso eso vuelve a filtrar
      // el catalogo entero cada vez.
      optionsBuilder: (valor) {
        final q = valor.text.trim().toLowerCase();
        if (q.isEmpty) return articulos;
        return articulos
            .where(
              (a) =>
                  a.codArticulo.toLowerCase().contains(q) ||
                  a.articulo.toLowerCase().contains(q),
            )
            .toList();
      },
      onSelected: (a) => onCambio(a.codArticulo),
      fieldViewBuilder: (ctx, control, foco, _) => TextField(
        controller: control,
        focusNode: foco,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 18),
        ),
      ),
    );
  }
}

/// Un campo de texto que no se pisa a si mismo mientras se escribe.
///
/// El controlador se crea una sola vez: si se recrea en cada rebuild —y el
/// provider rebuildea con cada tecla— el cursor salta al principio.
class _CampoTexto extends StatefulWidget {
  const _CampoTexto({
    super.key,
    this.etiqueta,
    required this.valor,
    required this.habilitado,
    required this.onCambio,
    this.soloNumeros = true,
    this.soloEnteros = false,
    this.lineas = 1,
  });

  final String? etiqueta;
  final String valor;
  final bool habilitado;
  final ValueChanged<String> onCambio;
  final bool soloNumeros;
  final bool soloEnteros;
  final int lineas;

  @override
  State<_CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<_CampoTexto> {
  late final TextEditingController _control = TextEditingController(
    text: widget.valor,
  );

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _control,
    enabled: widget.habilitado,
    maxLines: widget.lineas,
    style: widget.soloNumeros
        ? context.numero(fuerte: true)
        : Theme.of(context).textTheme.bodyMedium,
    keyboardType: widget.soloNumeros
        ? TextInputType.numberWithOptions(decimal: !widget.soloEnteros)
        : TextInputType.text,
    inputFormatters: widget.soloNumeros
        ? [
            FilteringTextInputFormatter.allow(
              widget.soloEnteros ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
            ),
          ]
        : null,
    decoration: InputDecoration(
      labelText: widget.etiqueta,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    onChanged: widget.onCambio,
  );
}

/// Hora en formato HH:mm. Se guarda como texto, igual que en la base.
class _CampoHora extends StatelessWidget {
  const _CampoHora({
    required this.etiqueta,
    required this.valor,
    required this.habilitado,
    required this.onCambio,
  });

  final String etiqueta;
  final String valor;
  final bool habilitado;
  final ValueChanged<String> onCambio;

  @override
  Widget build(BuildContext context) => _CampoTexto(
    key: ValueKey('hora-$etiqueta'),
    etiqueta: etiqueta,
    valor: valor,
    habilitado: habilitado,
    soloNumeros: false,
    onCambio: onCambio,
  );
}

class _CampoFechaLote extends StatelessWidget {
  const _CampoFechaLote({
    required this.fecha,
    required this.habilitado,
    required this.onCambio,
  });

  final DateTime fecha;
  final bool habilitado;
  final ValueChanged<DateTime> onCambio;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: habilitado
        ? () async {
            final hoy = DateTime.now();
            final elegida = await showDatePicker(
              context: context,
              initialDate: fecha,
              firstDate: DateTime(hoy.year - 5),
              lastDate: DateTime(hoy.year + 1, 12, 31),
            );
            if (elegida != null) onCambio(elegida);
          }
        : null,
    borderRadius: BorderRadius.circular(Esquina.chica),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Fecha',
        border: const OutlineInputBorder(),
        isDense: true,
        enabled: habilitado,
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      child: Text(fechaCorta(fecha), style: context.numero(fuerte: true)),
    ),
  );
}

class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones({
    required this.guardando,
    required this.onCancelar,
    required this.onGuardar,
  });

  final bool guardando;
  final VoidCallback onCancelar;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Esp.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: guardando ? null : onCancelar,
            child: const Text('Cancelar'),
          ),
          SizedBox(width: Esp.s),
          FilledButton.icon(
            onPressed: guardando ? null : onGuardar,
            icon: guardando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(guardando ? 'Guardando…' : 'Guardar y cerrar'),
          ),
        ],
      ),
    );
  }
}
