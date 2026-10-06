/// «Completar»: el cheque, su historial de acciones y las cuatro acciones que
/// el servidor deja hacer hoy.
///
/// **Las cuatro acciones no se calculan aqui.** Las habilita `detalle.botones`
/// (la rama K de `p_list_Cheque`: depende de las acciones del cheque y de si hay
/// una verificacion de deposito) y el servidor las vuelve a comprobar al
/// ejecutarlas. Esta pantalla solo dibuja un boton habilitado o apagado.
///
/// «Ir atras» vuelve a la grilla sin perder filtros ni pagina: el estado de la
/// grilla vive en `grillaChequesProvider`, no aqui.
///
/// «Editar accion» existe en el legacy pero nunca guardo nada: no se dibuja.
///
/// Entre las acciones y el historial van los tres paneles satelite (notas de
/// remision, transacciones bancarias y postergaciones, `paneles_cheque.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/botones_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/utils/situacion_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/dialogos_accion_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/documento_pdf_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/paneles_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';

/// Ancho desde el cual el historial es una tabla y no tarjetas.
const double _anchoTablaHistorial = 640;

final DateFormat _formatoFechaHora = DateFormat('dd/MM/yyyy HH:mm');

String _textoFechaHora(DateTime? f) =>
    f == null ? '—' : _formatoFechaHora.format(f);

class DetalleCheque extends ConsumerWidget {
  const DetalleCheque({
    super.key,
    required this.codCheque,
    required this.onVolver,
  });

  final BigInt codCheque;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detalleChequeProvider(codCheque));

    Widget cuerpo(ChequeDetalleEntity? d) {
      if (d == null) {
        return const MensajeVacio(
          icono: Icons.search_off,
          titulo: 'No se encontró el cheque',
          detalle: 'Puede haber sido eliminado. Vuelve al listado y busca de nuevo.',
        );
      }
      return _Contenido(detalle: d);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BarraSuperior(
          onVolver: onVolver,
          onRecargar: () {
            ref.invalidate(detalleChequeProvider(codCheque));
            // Los paneles tambien: otro usuario pudo anotar algo desde otro lado.
            ref.invalidate(notasRemisionChequeProvider(codCheque));
            ref.invalidate(transaccionesChequeProvider(codCheque));
            ref.invalidate(postergacionesChequeProvider(codCheque));
          },
          cargando: async.isLoading,
        ),
        Expanded(
          child: async.when(
            skipLoadingOnRefresh: true,
            loading: () => const EsqueletoLista(filas: 4, altoFila: 88),
            error:
                (e, _) => ErrorCheques(
                  titulo: 'No se pudo cargar el cheque',
                  texto: mensajeDeErrorCheque(e),
                  onReintentar:
                      () => ref.invalidate(detalleChequeProvider(codCheque)),
                ),
            data: cuerpo,
          ),
        ),
      ],
    );
  }
}

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({
    required this.onVolver,
    required this.onRecargar,
    required this.cargando,
  });

  final VoidCallback onVolver;
  final VoidCallback onRecargar;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: Esp.xs),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onVolver,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Ir atrás'),
          ),
          const Spacer(),
          if (cargando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Esp.m),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            onPressed: onRecargar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.detalle});

  final ChequeDetalleEntity detalle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, c) {
        final margen = c.maxWidth < 600 ? Esp.m : Esp.xl;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.xxl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Ficha(
                    cheque: detalle.cheque,
                    // El mismo reloj que la grilla: inyectable en las pruebas.
                    hoy: ref.read(relojChequesProvider)(),
                  ),
                  const SizedBox(height: Esp.l),
                  _AccionesYDocumento(detalle: detalle),
                  const SizedBox(height: Esp.l),
                  // Notas de remision, transacciones bancarias y postergaciones:
                  // cada panel lee lo suyo, aparte del detalle.
                  PanelesSatelitesCheque(cheque: detalle.cheque),
                  const SizedBox(height: Esp.l),
                  _Historial(detalle: detalle),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FICHA DEL CHEQUE
// ═══════════════════════════════════════════════════════════════════════════

/// Una superficie con titulo, como las secciones del detalle.
class _Seccion extends StatelessWidget {
  const _Seccion({
    super.key,
    required this.titulo,
    required this.hijo,
    this.icono,
  });

  final String titulo;
  final Widget hijo;

  /// Un icono chico en el primario junto al titulo.
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icono != null) ...[
                  Icon(icono, size: 18, color: cs.primary),
                  const SizedBox(width: Esp.s),
                ],
                Expanded(child: Text(titulo, style: context.tituloSeccion())),
              ],
            ),
            const SizedBox(height: Esp.m),
            hijo,
          ],
        ),
      ),
    );
  }
}

/// Un dato de la ficha. [hijo] reemplaza al texto cuando el valor lleva una
/// pastilla o un icono; [extra] va debajo del valor.
class _Dato {
  const _Dato(
    this.etiqueta,
    this.valor, {
    this.cifra = false,
    this.largo = false,
    this.hijo,
    this.extra,
  });

  final String etiqueta;
  final String valor;
  final bool cifra;

  /// Ocupa el renglon entero cuando solo caben dos columnas (telefono): un banco
  /// o un nombre en media columna se parte en tres lineas.
  final bool largo;
  final Widget? hijo;
  final Widget? extra;
}

class _Ficha extends StatelessWidget {
  const _Ficha({required this.cheque, required this.hoy});

  final ChequeFilaEntity cheque;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    final c = cheque;
    final t = Theme.of(context).textTheme;
    final situacion = situacionDeCheque(
      estado: c.cheque.estado,
      fechaCobrar: c.cheque.fechaCobrar,
      hoy: hoy,
    );

    final datos = <_Dato>[
      _Dato('Banco', c.nombreBanco, largo: true),
      _Dato('A la orden de', textoODash(c.cheque.aOrdenDe), largo: true),
      _Dato('Fecha del cheque', textoFecha(c.cheque.fechaCheque), cifra: true),
      _Dato(
        'Fecha de cobro',
        textoFecha(c.cheque.fechaCobrar),
        cifra: true,
        extra: TextoSituacionCheque(situacion: situacion),
      ),
      _Dato('Recepción', textoFecha(c.fechaRecepcion), cifra: true),
      _Dato('Tipo', textoTipoCheque(c), hijo: TipoCheque(c)),
      _Dato(
        'Entregado por',
        textoEntregadoPor(c),
        largo: true,
        hijo: EntregadoPorCheque(cheque: c, texto: textoEntregadoPor(c)),
      ),
      _Dato('Empresa', c.datoEmpresa, largo: true),
      _Dato(
        'Recibo manual',
        c.cheque.sinReciboManual ? '—' : c.cheque.reciboManual!,
        cifra: true,
      ),
      _Dato(
        'Talonario manual',
        c.cheque.sinTalonario ? '—' : c.cheque.nroTalonario!,
        cifra: true,
      ),
      _Dato(
        'Nro. de recibo',
        c.cheque.nroRecibo == null ? '—' : '${c.cheque.nroRecibo}',
        cifra: true,
      ),
    ];

    return _Seccion(
      titulo: 'Datos del cheque',
      icono: Icons.receipt_long_outlined,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // La cabecera: el banco, el cheque, su estado y su plazo de cobro, y
          // el monto grande. Es lo primero que se busca al abrir un cheque.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonogramaBanco(c.nombreBanco, tam: 46),
              const SizedBox(width: Esp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Esp.m,
                      runSpacing: Esp.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Cheque ${c.cheque.nrocheque}',
                          style: context.cifraCheque(fuerte: true, tam: 18),
                        ),
                        EtiquetaEstadoCheque(
                          estado: c.cheque.estado,
                          texto: c.descEstado,
                        ),
                        if (situacion.tienePlazo)
                          PastillaSituacionCheque(situacion: situacion),
                      ],
                    ),
                    const SizedBox(height: Esp.xs),
                    Text(textoODash(c.datoCliente), style: t.titleSmall),
                    const SizedBox(height: Esp.s),
                    ImporteCheque(
                      cheque: c,
                      tam: 28,
                      alineacion: Alignment.centerLeft,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Esp.l),
          Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: Esp.l),
          LayoutBuilder(
            builder: (context, box) {
              // Dos columnas como minimo: en el telefono las fechas y las
              // cifras van de a dos.
              final columnas = ((box.maxWidth + Esp.l) / (170 + Esp.l))
                  .floor()
                  .clamp(2, 4);
              final ancho =
                  ((box.maxWidth - Esp.l * (columnas - 1)) / columnas)
                      .floorToDouble();
              return Wrap(
                spacing: Esp.l,
                runSpacing: Esp.m,
                children: [
                  for (final d in datos)
                    SizedBox(
                      width: d.largo && columnas == 2 ? box.maxWidth : ancho,
                      child:
                          d.hijo != null
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(d.etiqueta, style: context.apagado()),
                                  const SizedBox(height: 2),
                                  d.hijo!,
                                ],
                              )
                              : DatoCheque(
                                etiqueta: d.etiqueta,
                                valor: d.valor,
                                cifra: d.cifra,
                                extra: d.extra,
                              ),
                    ),
                ],
              );
            },
          ),
          if ((c.observacion ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: Esp.m),
            DatoCheque(etiqueta: 'Observación', valor: c.observacion!),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LAS CUATRO ACCIONES
// ═══════════════════════════════════════════════════════════════════════════

/// Si [tipo] esta habilitada: el flag que corresponde de la rama K.
bool _habilitada(BotonesChequeEntity b, TipoAccionCheque tipo) => switch (tipo) {
  TipoAccionCheque.fechaCobro => b.fechaCobro,
  TipoAccionCheque.devolver => b.devolver,
  TipoAccionCheque.cerrarConVerificacion => b.cerrarConVerificacion,
  TipoAccionCheque.cerrarSinVerificacion => b.cerrarSinVerificacion,
};

class _Acciones extends StatelessWidget {
  const _Acciones({required this.detalle});

  final ChequeDetalleEntity detalle;

  @override
  Widget build(BuildContext context) {
    final b = detalle.botones;

    return _Seccion(
      titulo: 'Acciones',
      icono: Icons.touch_app_outlined,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.s,
            children: [
              for (final tipo in TipoAccionCheque.values)
                _BotonAccion(
                  tipo: tipo,
                  // Solo lo que dice el servidor. Quien llega al detalle tiene
                  // `btnDetalleCH`, que ya basta para las cuatro.
                  habilitada: _habilitada(b, tipo),
                  onPressed:
                      () => abrirAccionCheque(
                        context,
                        cheque: detalle.cheque,
                        tipo: tipo,
                      ),
                ),
            ],
          ),
          if (!b.hayAlguno)
            NotaDelDato(
              texto:
                  detalle.cheque.estaCerrado
                      ? 'El cheque está cerrado: no admite más acciones.'
                      : 'Por ahora no hay acciones disponibles para este '
                          'cheque. Aparecen cuando el historial lo permite.',
            ),
        ],
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    required this.tipo,
    required this.habilitada,
    required this.onPressed,
  });

  final TipoAccionCheque tipo;
  final bool habilitada;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final boton = FilledButton.tonalIcon(
      key: ValueKey('accion-${tipo.name}'),
      onPressed: habilitada ? onPressed : null,
      icon: Icon(tipo.icono, size: 18),
      label: Text(tipo.etiqueta),
    );
    return habilitada
        ? boton
        : Tooltip(
          message: 'No disponible para este cheque en su estado actual.',
          child: boton,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DOCUMENTO PDF
// ═══════════════════════════════════════════════════════════════════════════

/// Las acciones y el documento PDF. Con ancho van lado a lado (el PDF no suma
/// altura a una pantalla que ya es larga) y con poco ancho, uno sobre otro.
class _AccionesYDocumento extends StatelessWidget {
  const _AccionesYDocumento({required this.detalle});

  final ChequeDetalleEntity detalle;

  /// Ancho desde el cual caben las dos tarjetas lado a lado.
  static const double _anchoLadoALado = 900;

  @override
  Widget build(BuildContext context) {
    final acciones = _Acciones(detalle: detalle);
    final pdf = _DocumentoPdf(cheque: detalle.cheque);
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < _anchoLadoALado) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [acciones, const SizedBox(height: Esp.l), pdf],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: acciones),
              const SizedBox(width: Esp.l),
              Expanded(flex: 2, child: pdf),
            ],
          ),
        );
      },
    );
  }
}

/// El PDF del cheque: su estado a la vista («Hay un PDF cargado · 120 KB · ...» o
/// «Este cheque no tiene PDF todavía») y el acceso al dialogo para verlo,
/// descargarlo, cargarlo o reemplazarlo. Sin permiso de boton, como en el
/// legacy.
class _DocumentoPdf extends StatelessWidget {
  const _DocumentoPdf({required this.cheque});

  final ChequeFilaEntity cheque;

  @override
  Widget build(BuildContext context) {
    return _Seccion(
      key: const ValueKey('seccion-documento-pdf'),
      titulo: 'Documento PDF',
      icono: Icons.picture_as_pdf_outlined,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EstadoPdfCheque(codCheque: cheque.codCheque),
          const SizedBox(height: Esp.m),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              key: const ValueKey('boton-documento-pdf'),
              onPressed: () => abrirDocumentoPdfCheque(context, cheque: cheque),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Abrir documento'),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HISTORIAL
// ═══════════════════════════════════════════════════════════════════════════

class _Historial extends ConsumerWidget {
  const _Historial({required this.detalle});

  final ChequeDetalleEntity detalle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogos = ref.watch(catalogosChequeProvider).valueOrNull;
    final puedeEliminar = ref.watch(permisosChequeProvider).puedeEliminarAccion;
    final acciones = detalle.acciones;

    String nombre(AccionChequeEntity a) =>
        a.descripcion.trim().isNotEmpty
            ? a.descripcion.trim()
            : (catalogos?.nombreEstadoAccion(a.estado) ?? a.estado);

    return _Seccion(
      titulo: 'Historial (${acciones.length})',
      icono: Icons.history,
      hijo:
          acciones.isEmpty
              ? Text('Este cheque todavía no tiene acciones.', style: context.apagado())
              : LayoutBuilder(
                builder: (context, c) {
                  final tabla = c.maxWidth >= _anchoTablaHistorial;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (tabla) const _CabeceraHistorial(),
                      for (final a in acciones)
                        tabla
                            ? _FilaHistorial(
                              accion: a,
                              nombre: nombre(a),
                              puedeEliminar: puedeEliminar,
                              onEliminar: () => eliminarAccionCheque(context, ref, a, nombre(a)),
                            )
                            : _TarjetaHistorial(
                              accion: a,
                              nombre: nombre(a),
                              puedeEliminar: puedeEliminar,
                              onEliminar: () => eliminarAccionCheque(context, ref, a, nombre(a)),
                            ),
                    ],
                  );
                },
              ),
    );
  }
}

const double _anchoNro = 40;
const double _anchoFecha = 132;
const double _anchoSap = 120;
const double _anchoEliminar = 48;

class _CabeceraHistorial extends StatelessWidget {
  const _CabeceraHistorial();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: Peso.dato,
      color: cs.onSurface,
    );
    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          cs.primary.withValues(alpha: 0.10),
          cs.surfaceContainerLow,
        ),
        border: Border(
          bottom: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      child: Row(
        children: [
          SizedBox(width: _anchoNro, child: Text('#', style: estilo)),
          SizedBox(width: _anchoFecha, child: Text('Fecha', style: estilo)),
          Expanded(flex: 2, child: Text('Acción', style: estilo)),
          SizedBox(width: _anchoSap, child: Text('Nro. SAP', style: estilo)),
          Expanded(flex: 3, child: Text('Observación', style: estilo)),
          const SizedBox(width: _anchoEliminar),
        ],
      ),
    );
  }
}

class _FilaHistorial extends StatelessWidget {
  const _FilaHistorial({
    required this.accion,
    required this.nombre,
    required this.puedeEliminar,
    required this.onEliminar,
  });

  final AccionChequeEntity accion;
  final String nombre;
  final bool puedeEliminar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final cifras = context.cifraCheque();
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      constraints: const BoxConstraints(minHeight: 48),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.m,
              vertical: Esp.xs,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: _anchoNro,
                  child: Text(
                    '${accion.nro}',
                    style: cifras.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                SizedBox(
                  width: _anchoFecha,
                  child: Text(_textoFechaHora(accion.fecha), style: cifras),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PastillaAccionCheque(
                      estado: accion.estado,
                      nombre: nombre,
                    ),
                  ),
                ),
                SizedBox(
                  width: _anchoSap,
                  child: Text(textoODash(accion.nroSAP), style: cifras),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    textoODash(accion.observacion),
                    style: t.bodyMedium,
                  ),
                ),
                SizedBox(
                  width: _anchoEliminar,
                  child:
                      puedeEliminar
                          ? IconButton(
                            tooltip: 'Eliminar acción',
                            onPressed: onEliminar,
                            icon: Icon(Icons.delete_outline, color: cs.error),
                          )
                          : null,
                ),
              ],
            ),
          ),
          // Una franja por estado: el color de `semanticaDeAccion`.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: FranjaCheque(
              ancho: 3,
              color: ChequesColores.pleno(
                context,
                semanticaDeAccion(accion.estado),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaHistorial extends StatelessWidget {
  const _TarjetaHistorial({
    required this.accion,
    required this.nombre,
    required this.puedeEliminar,
    required this.onEliminar,
  });

  final AccionChequeEntity accion;
  final String nombre;
  final bool puedeEliminar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.s + 3, Esp.s, 0, Esp.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${accion.nro}',
                    style: context.cifraCheque(
                      color: cs.onSurfaceVariant,
                      tam: 11.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PastillaAccionCheque(
                        estado: accion.estado,
                        nombre: nombre,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _textoFechaHora(accion.fecha),
                        style: context.cifraCheque(
                          color: cs.onSurfaceVariant,
                          tam: 11.5,
                        ),
                      ),
                      if ((accion.nroSAP ?? '').trim().isNotEmpty)
                        Text(
                          'Nro. SAP ${accion.nroSAP!.trim()}',
                          style: context.cifraCheque(tam: 11.5),
                        ),
                      if ((accion.observacion ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: Esp.xs),
                          child: Text(
                            accion.observacion!.trim(),
                            style: t.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                if (puedeEliminar)
                  IconButton(
                    tooltip: 'Eliminar acción',
                    onPressed: onEliminar,
                    icon: Icon(Icons.delete_outline, color: cs.error),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: FranjaCheque(
              ancho: 3,
              color: ChequesColores.pleno(
                context,
                semanticaDeAccion(accion.estado),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pide confirmacion y da de baja una accion del historial.
///
/// El servidor, como el legacy, deja eliminar cualquiera —tambien las del
/// circuito (recepcion, traspaso, custodia) y con el cheque cerrado—: aqui solo
/// se avisa lo que eso provoca.
Future<void> eliminarAccionCheque(
  BuildContext context,
  WidgetRef ref,
  AccionChequeEntity accion,
  String nombre,
) async {
  final consecuencia = switch (accion.estado) {
    AccionChequeEntity.recibido =>
      ' Es la recepción: si la eliminas, el cheque deja de aparecer en el '
          'listado.',
    AccionChequeEntity.traspaso || AccionChequeEntity.custodia =>
      ' Es una acción del circuito: eliminarla cambia las acciones que se '
          'pueden hacer con el cheque.',
    _ => '',
  };
  final seguro = await confirmar(
    context,
    titulo: '¿Eliminar esta acción?',
    detalle: '$nombre del ${textoFecha(accion.fecha)}.$consecuencia',
    textoConfirmar: 'Eliminar acción',
    destructiva: true,
  );
  if (!seguro || !context.mounted) return;

  final ops = ref.read(operacionesChequesProvider.notifier);
  final r = await ops.eliminarAccion(accion.codAccion);
  if (!context.mounted) return;
  if (r == null) {
    avisar(
      context,
      ref.read(operacionesChequesProvider).error ??
          'No se pudo eliminar la acción.',
      esError: true,
    );
    ops.limpiarError();
    return;
  }
  avisar(context, 'Acción eliminada.');
}
