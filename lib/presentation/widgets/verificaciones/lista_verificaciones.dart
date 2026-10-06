/// La lista principal de «Verificar Cheques»: una tabla con una columna por dato
/// en escritorio y tarjetas en movil. No conoce el estado ni abre nada: las
/// acciones de cada fila llegan por [AlElegirAccionVerificacion] y la
/// paginacion, ya construida.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/verificacion_fila_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/piezas_verificacion.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/tabla_verificaciones.dart';

/// Lo que se puede hacer con una verificacion desde la lista.
enum AccionFilaVerificacion {
  /// Cambiar el banco, la fecha o la observacion. No cambia el estado.
  editar('Editar', Icons.edit_outlined),

  /// «Cancelar» del legacy: pasa la verificacion a Anulada. No la borra.
  anular('Cancelar verificación', Icons.block_outlined);

  const AccionFilaVerificacion(this.etiqueta, this.icono);

  final String etiqueta;
  final IconData icono;
}

/// Las acciones de [fila]: editar siempre (el legacy la ofrecia tambien en una
/// anulada, donde el estado se conserva) y cancelar solo si todavia vale: anular
/// lo ya anulado no cambia nada.
List<AccionFilaVerificacion> accionesDeVerificacion(VerificacionFilaEntity fila) =>
    [
      AccionFilaVerificacion.editar,
      if (!fila.estaAnulada) AccionFilaVerificacion.anular,
    ];

typedef AlElegirAccionVerificacion =
    void Function(AccionFilaVerificacion accion, VerificacionFilaEntity fila);

/// Ancho de un icono de accion en la tabla.
const double _anchoIconoAccion = 28;

/// Las acciones de una fila: dos iconos (lo maximo que hay) y, por lo menos, lo que
/// necesita el rotulo «Acciones» de la cabecera.
const double _anchoAcciones = 84;

/// Las columnas, en el orden en que se dibujan. Las de `descarte` se van
/// ocultando, de mayor a menor, cuando el area no alcanza: primero el numero de
/// fila y la observacion, al final lo esencial (cheque, monto, banco y fecha de
/// verificacion y su estado).
const List<ColumnaTabla> _columnas = [
  ColumnaTabla('num', '#', ancho: 40, descarte: 5),
  ColumnaTabla('nro', 'Nro. cheque', ancho: 104),
  ColumnaTabla('monto', 'Monto', ancho: 132, derecha: true),
  ColumnaTabla('bancoCheque', 'Banco del cheque', flex: 2, descarte: 3),
  ColumnaTabla('fcobranza', 'F. cobranza', ancho: 96, descarte: 2),
  ColumnaTabla('estadoCheque', 'Estado cheque', ancho: 112, descarte: 4),
  ColumnaTabla('bancoVerif', 'Banco verificado', flex: 2),
  ColumnaTabla('fverif', 'F. verificación', ancho: 104),
  ColumnaTabla('estadoVerif', 'Verificación', ancho: 116),
  ColumnaTabla('obs', 'Observación', flex: 2, descarte: 1),
];

/// Elige tabla o tarjetas segun el ancho que hay. [pie] (la paginacion) va dentro
/// de la tabla y debajo de las tarjetas.
class ListaVerificaciones extends StatelessWidget {
  const ListaVerificaciones({
    super.key,
    required this.filas,
    required this.onAccion,
    required this.pie,
  });

  final List<VerificacionFilaEntity> filas;
  final AlElegirAccionVerificacion onAccion;
  final Widget pie;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= anchoMinimoTablaVerificacion) {
          return TablaVerificaciones(
            key: const ValueKey('lista-tabla'),
            columnas: _columnas,
            anchoAcciones: _anchoAcciones,
            cantidad: filas.length,
            pie: pie,
            filaDe:
                (plan, i) => _FilaVerificacion(
                  key: ValueKey('fila-${filas[i].codvd}'),
                  indice: i,
                  fila: filas[i],
                  plan: plan,
                  onAccion: onAccion,
                ),
          );
        }
        return _Tarjetas(
          key: const ValueKey('lista-tarjetas'),
          ancho: constraints.maxWidth,
          filas: filas,
          onAccion: onAccion,
          pie: pie,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TABLA
// ═══════════════════════════════════════════════════════════════════════════

class _FilaVerificacion extends StatelessWidget {
  const _FilaVerificacion({
    super.key,
    required this.indice,
    required this.fila,
    required this.plan,
    required this.onAccion,
  });

  final int indice;
  final VerificacionFilaEntity fila;
  final PlanTabla plan;
  final AlElegirAccionVerificacion onAccion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final cifras = context.cifraCheque();
    final c = fila.cheque;
    final v = fila.verificacion;

    Widget celda(ColumnaTabla col) => switch (col.id) {
      'num' => Text(
        '${fila.fila}',
        style: cifras.copyWith(color: cs.onSurfaceVariant),
        maxLines: 1,
      ),
      'nro' => TextoCelda(
        textoODash(c.nroCheque),
        estilo: context.cifraCheque(fuerte: true),
      ),
      'monto' => ImporteVerificacion(cheque: c),
      'bancoCheque' => BancoCheque(c.datoBancoCheque),
      'fcobranza' => Text(
        textoFecha(c.fechaCobrarCheque),
        style: cifras,
        maxLines: 1,
      ),
      'estadoCheque' => EtiquetaEstadoCheque(
        estado: c.chequeCerrado ? 'CER' : 'PEN',
        texto: c.datoEstadoCheque,
      ),
      'bancoVerif' => BancoCheque(fila.datoBanco),
      'fverif' => Text(textoFecha(v.fechaBanco), style: cifras, maxLines: 1),
      'estadoVerif' => PastillaVerificacion(
        estado: v.estado,
        textoDelServidor: fila.datoEstado,
      ),
      'obs' => TextoCelda(
        textoODash(v.observacion),
        estilo: t.bodyMedium,
        lineas: 3,
      ),
      _ => const SizedBox.shrink(),
    };

    return FilaTablaVerificacion(
      indice: indice,
      franja: colorFranjaVerificacion(context, v.estado),
      plan: plan,
      celda: celda,
      acciones:
          (sobre) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in accionesDeVerificacion(fila))
                IconButton(
                  tooltip: a.etiqueta,
                  onPressed: () => onAccion(a, fila),
                  icon: Icon(a.icono, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: sobre ? cs.primary : cs.onSurfaceVariant,
                    minimumSize: const Size.square(_anchoIconoAccion),
                    maximumSize: const Size.square(_anchoIconoAccion),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETAS
// ═══════════════════════════════════════════════════════════════════════════

class _Tarjetas extends StatelessWidget {
  const _Tarjetas({
    super.key,
    required this.ancho,
    required this.filas,
    required this.onAccion,
    required this.pie,
  });

  final double ancho;
  final List<VerificacionFilaEntity> filas;
  final AlElegirAccionVerificacion onAccion;
  final Widget pie;

  @override
  Widget build(BuildContext context) {
    final diseno = disenoDeTarjetas(ancho);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Esp.m,
          runSpacing: Esp.m,
          children: [
            for (final f in filas)
              SizedBox(
                key: ValueKey('fila-${f.codvd}'),
                width: diseno.ancho,
                child: _Tarjeta(fila: f, onAccion: onAccion),
              ),
          ],
        ),
        const SizedBox(height: Esp.m),
        pie,
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.fila, required this.onAccion});

  final VerificacionFilaEntity fila;
  final AlElegirAccionVerificacion onAccion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final c = fila.cheque;
    final v = fila.verificacion;
    final acciones = accionesDeVerificacion(fila);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contornoSuperficie(cs),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.l + 4, Esp.m, Esp.xs, Esp.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: Esp.s,
                        runSpacing: Esp.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          InsigniaFila('#${fila.fila}'),
                          PastillaVerificacion(
                            estado: v.estado,
                            textoDelServidor: fila.datoEstado,
                          ),
                          EtiquetaEstadoCheque(
                            estado: c.chequeCerrado ? 'CER' : 'PEN',
                            texto: c.datoEstadoCheque,
                          ),
                        ],
                      ),
                    ),
                    MenuAccionesCheque(
                      opciones: [
                        for (final a in acciones)
                          OpcionMenuCheque(
                            a.etiqueta,
                            a.icono,
                            () => onAccion(a, fila),
                          ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: Esp.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cheque ${textoODash(c.nroCheque)}',
                        style: context.cifraCheque(fuerte: true, tam: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Esp.s),
                      Row(
                        children: [
                          MonogramaBanco(c.datoBancoCheque),
                          const SizedBox(width: Esp.s),
                          Expanded(
                            child: Text(
                              textoODash(c.datoBancoCheque),
                              style: t.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Esp.m),
                      ImporteVerificacion(
                        cheque: c,
                        tam: 22,
                        alineacion: Alignment.centerLeft,
                      ),
                      const SizedBox(height: Esp.m),
                      Divider(height: 1, color: cs.outlineVariant),
                      const SizedBox(height: Esp.s),
                      Wrap(
                        spacing: Esp.l,
                        runSpacing: Esp.s,
                        children: [
                          _MiniFecha(
                            'Fecha de cobranza',
                            textoFecha(c.fechaCobrarCheque),
                          ),
                          _MiniFecha(
                            'Fecha de verificación',
                            textoFecha(v.fechaBanco),
                          ),
                        ],
                      ),
                      const SizedBox(height: Esp.s),
                      _Campo(
                        'Verificado en',
                        textoODash(fila.datoBanco),
                        hijo: Row(
                          children: [
                            MonogramaBanco(fila.datoBanco, tam: 22),
                            const SizedBox(width: Esp.s),
                            Expanded(
                              child: Text(
                                textoODash(fila.datoBanco),
                                style: t.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((v.observacion ?? '').trim().isNotEmpty)
                        _Campo('Observación', v.observacion!.trim()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: FranjaCheque(color: colorFranjaVerificacion(context, v.estado)),
          ),
        ],
      ),
    );
  }
}

/// Una fecha de la tarjeta: la etiqueta chica arriba y la cifra en mono debajo.
class _MiniFecha extends StatelessWidget {
  const _MiniFecha(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta, style: context.apagado()),
        const SizedBox(height: 2),
        Text(valor, style: context.cifraCheque(), maxLines: 1),
      ],
    );
  }
}

/// Fila «etiqueta: valor» de la tarjeta. Con texto muy grande la etiqueta pasa
/// arriba del valor: lado a lado se tocarian o el valor quedaria en una columna
/// de tres letras.
class _Campo extends StatelessWidget {
  const _Campo(this.etiqueta, this.valor, {this.hijo});

  final String etiqueta;
  final String valor;
  final Widget? hijo;

  @override
  Widget build(BuildContext context) {
    final valorTexto = Text(
      valor,
      style: Theme.of(context).textTheme.bodyMedium,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
    final apilado = MediaQuery.textScalerOf(context).scale(1) > 1.25;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child:
          apilado
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta, style: context.apagado()),
                  hijo ?? valorTexto,
                ],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(etiqueta, style: context.apagado()),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: hijo ?? valorTexto,
                    ),
                  ),
                ],
              ),
    );
  }
}
