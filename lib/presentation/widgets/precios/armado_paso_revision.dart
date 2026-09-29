/// Paso 3 del asistente: lo que quedo armado y que sigue.
///
/// Reemplaza al pie de `dlgPropEditar` ("ENVIAR A AUTORIZAR") y de `dlgPropH`.
/// Enviar a autorizar pide el boton btnPen, igual que en el sistema anterior:
/// quien no lo tiene ve el motivo y la propuesta queda Pendiente, lista para
/// que alguien con el permiso la mande desde el listado.
///
/// **Como se lee.** Arriba, la propuesta: numero, titulo, observaciones,
/// quien la armo y su estado. Debajo, las cifras (familias, listas, articulos
/// que cambian de precio y cuanto se mueve el costo) y la tabla de lo cargado,
/// con un boton para corregir cualquier familia sin volver al paso anterior.
/// Al costado -debajo en el telefono-, los tres pasos que faltan con sus
/// botones y los fletes. Antes era una columna de renglones "rotulo: valor"
/// donde lo importante (enviar a autorizar) quedaba al final.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/armado_propuesta_provider.dart';
import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/armado_propuesta_entity.dart';
import 'package:bosque_flutter/domain/entities/articulo_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/articulo_propuesto_entity.dart';
import 'package:bosque_flutter/domain/entities/autorizacion_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/propuesta_precio_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/armado_editor_familia.dart';
import 'package:bosque_flutter/presentation/widgets/precios/armado_lote_familias.dart';
import 'package:bosque_flutter/presentation/widgets/precios/articulos_de_familia.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cifra_resumen.dart';
import 'package:bosque_flutter/presentation/widgets/precios/dialogos_propuesta.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/pdf_precios.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_detalle_piezas.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_en_autorizacion.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_propuestas.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// El boton de tb_vistaBtn que habilita mandar a autorizar.
const String _btnEnEspera = 'btnPen';

/// Ancho de la columna del costado en pantallas anchas.
const double _anchoCostado = 360;

class ArmadoPasoRevision extends ConsumerWidget {
  const ArmadoPasoRevision({
    super.key,
    required this.aire,
    required this.onTerminar,
  });

  final Aire aire;

  /// Cierra el asistente.
  final VoidCallback onTerminar;

  /// La fila del listado de esta propuesta, que es lo que piden la vista
  /// preliminar y la confirmacion. Si todavia no esta en el listado -se esta
  /// recargando- se arma con lo que sabe el asistente.
  PropuestaEnAutorizacion _fila(WidgetRef ref, EstadoArmado estado) {
    final id = estado.idPropuesta!;
    final listado = ref.watch(propuestasParaAutorizarProvider).valueOrNull;
    for (final cruda in listado ?? const <Map<String, dynamic>>[]) {
      if (idCrudo(cruda, 'idPropuesta') == id) {
        return PropuestaEnAutorizacion.desdeFila(cruda);
      }
    }
    return PropuestaEnAutorizacion(
      propuesta: PropuestaPrecioEntity(
        idPropuesta: id,
        codEmpresa: BigInt.zero,
        tipo: estado.tipo.codigo,
        titulo: estado.titulo,
        obs: estado.obs,
        estado: 0,
        audUsGenerado: BigInt.zero,
        audFecGenerado: null,
        audUsuario: BigInt.zero,
        audFecha: null,
      ),
      autorizacion: AutorizacionPrecioEntity(
        idAutorizacion: BigInt.zero,
        idPropuesta: id,
        esAprobada: 0,
        audUsuario: BigInt.zero,
        audFecha: null,
      ),
      propuestoPor: '',
      resueltoPor: '',
      generadoPor: '',
    );
  }

  Future<void> _enviar(
    BuildContext context,
    WidgetRef ref,
    PropuestaEnAutorizacion fila,
  ) async {
    if (!await confirmarEnviarAEspera(context, fila)) return;
    if (!context.mounted) return;

    final notifier = ref.read(propuestaProvider.notifier);
    final ok = await notifier.marcarEnEspera(fila.idPropuesta);
    if (!context.mounted) return;
    if (ok) {
      avisar(context, 'Propuesta ${fila.numero} enviada a autorizar.');
      onTerminar();
      return;
    }
    avisar(
      context,
      ref.read(propuestaProvider).error ??
          'No se pudo enviar a autorizar. Intente de nuevo.',
      esError: true,
    );
    notifier.limpiarError();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(armadoProvider);
    if (!estado.existe) {
      return const MensajeVacio(
        icono: Icons.inventory_2_outlined,
        titulo: 'Todavía no hay propuesta',
        detalle:
            'La propuesta se crea al guardar la primera familia o el primer '
            'artículo. Vuelva al paso anterior.',
      );
    }

    final fila = _fila(ref, estado);
    final puedeEnviar = tienePermisoDeBoton(ref, _btnEnEspera);
    final enviando = ref.watch(propuestaProvider.select((e) => e.cargando));
    final chico = aire.esChico;
    final amplio = aire == Aire.amplio;
    final margen = chico ? Esp.m : Esp.xl;

    final cabecera = _Cabecera(fila: fila, estado: estado, compacto: chico);
    final contenido =
        estado.esPorFamilia
            ? _Familias(
              idPropuesta: estado.idPropuesta!,
              compacto: !amplio,
              chico: chico,
            )
            : _Articulos(
              idPropuesta: estado.idPropuesta!,
              compacto: !amplio,
              chico: chico,
            );
    final queSigue = _QueSigue(
      puedeEnviar: puedeEnviar,
      enviando: enviando,
      onVista:
          () => abrirDetallePropuesta(context, fila: fila, preliminar: true),
      onPdf: () => verPdfDePropuesta(context, ref, fila),
      onEnviar: () => _enviar(context, ref, fila),
    );
    final fletes =
        estado.esPorFamilia ? _Fletes(fletes: estado.fletesGuardados) : null;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child:
              amplio
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cabecera,
                      const SizedBox(height: Esp.l),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: contenido),
                          const SizedBox(width: Esp.l),
                          SizedBox(
                            width: _anchoCostado,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                queSigue,
                                if (fletes != null) ...[
                                  const SizedBox(height: Esp.l),
                                  fletes,
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                  // Angosto: lo que se hace primero. Los pasos que siguen van
                  // antes del detalle, que es para revisar.
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cabecera,
                      const SizedBox(height: Esp.m),
                      queSigue,
                      const SizedBox(height: Esp.m),
                      contenido,
                      if (fletes != null) ...[
                        const SizedBox(height: Esp.m),
                        fletes,
                      ],
                    ],
                  ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA
// ═══════════════════════════════════════════════════════════════════════════

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.fila,
    required this.estado,
    required this.compacto,
  });

  final PropuestaEnAutorizacion fila;
  final EstadoArmado estado;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final obs =
        fila.propuesta.obs.trim().isNotEmpty
            ? fila.propuesta.obs.trim()
            : estado.obs.trim();
    final quien = fila.propuestoPor.trim();

    final hechos = [
      _Hecho(
        icono:
            estado.esPorFamilia
                ? Icons.inventory_2_outlined
                : Icons.category_outlined,
        texto: estado.tipo.etiqueta,
      ),
      if (quien.isNotEmpty)
        _Hecho(icono: Icons.person_outline, texto: 'Armada por $quien'),
      if (fila.propuesta.audFecha != null)
        _Hecho(icono: Icons.event_outlined, texto: fila.fechaPropuesta),
    ];

    return Container(
      padding: EdgeInsets.all(compacto ? Esp.m : Esp.l),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          cs.primary.withValues(alpha: 0.07),
          cs.surfaceContainerLowest,
        ),
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compacto) ...[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.request_quote_outlined,
                color: cs.onPrimary,
                size: 26,
              ),
            ),
            const SizedBox(width: Esp.l),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROPUESTA N.º ${fila.idPropuesta}',
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: Peso.titulo,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fila.titulo,
                  style: (compacto ? tt.titleMedium : tt.titleLarge)?.copyWith(
                    fontWeight: Peso.dato,
                  ),
                ),
                if (obs.isNotEmpty) ...[
                  const SizedBox(height: Esp.xs),
                  Text(
                    obs,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: Esp.s),
                Wrap(spacing: Esp.l, runSpacing: Esp.xs, children: hechos),
              ],
            ),
          ),
          const SizedBox(width: Esp.s),
          ChipEstadoPropuesta(autorizacion: fila.autorizacion),
        ],
      ),
    );
  }
}

class _Hecho extends StatelessWidget {
  const _Hecho({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icono,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: Esp.xs),
      Flexible(child: Text(texto, style: context.apagado())),
    ],
  );
}

/// Las cifras en una fila; en pantallas angostas, de a dos.
class _Cifras extends StatelessWidget {
  const _Cifras({required this.cifras, required this.compacto});

  final List<Widget> cifras;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final porFila = compacto ? 2 : cifras.length;
    final filas = <Widget>[];
    for (var i = 0; i < cifras.length; i += porFila) {
      final tramo = cifras.sublist(i, math.min(i + porFila, cifras.length));
      filas.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < porFila; j++) ...[
              if (j > 0) const SizedBox(width: Esp.s),
              Expanded(child: j < tramo.length ? tramo[j] : const SizedBox()),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < filas.length; i++) ...[
          if (i > 0) const SizedBox(height: Esp.s),
          filas[i],
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FAMILIAS
// ═══════════════════════════════════════════════════════════════════════════

/// Una familia de la propuesta con lo que el catalogo dice de ella.
@immutable
class _Cargada {
  const _Cargada({required this.armada, this.familia, this.articulos});

  final FamiliaArmadaEntity armada;

  /// Null si ya no figura entre las activas.
  final FamiliaVista? familia;

  /// Null mientras se leen.
  final List<ArticuloPrecioEntity>? articulos;

  int get codigo => armada.codigoFamilia;

  String get descripcion =>
      familia?.descripcion ?? 'Ya no figura entre las familias activas';

  String get proveedor => familia?.proveedorSap ?? '';

  double? get costoActual =>
      familia == null || familia!.sinCosto ? null : familia!.costoTM;

  double? get variacion {
    final a = costoActual;
    final p = armada.costoSug;
    if (a == null || p == null || a <= 0) return null;
    return (p - a) / a * 100;
  }
}

class _Familias extends ConsumerWidget {
  const _Familias({
    required this.idPropuesta,
    required this.compacto,
    required this.chico,
  });

  final BigInt idPropuesta;

  /// Sin la columna del costado: tarjetas en vez de tabla.
  final bool compacto;
  final bool chico;

  Future<void> _editar(BuildContext context, _Cargada f) async {
    final guardada = await abrirEditorFamilia(
      context,
      codigoFamilia: f.codigo,
      familia: f.familia,
    );
    if (guardada == null || !context.mounted) return;
    avisar(context, 'Familia ${f.codigo} guardada en la propuesta.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final armadas = ref.watch(familiasArmadasProvider(idPropuesta));
    final catalogo =
        ref
            .watch(familiasProvider(const FiltroFamilias(estado: 1)))
            .valueOrNull;
    final porCodigo = <int, FamiliaVista>{
      for (final f in (catalogo ?? const <Map<String, dynamic>>[]).map(
        FamiliaVista.deMapa,
      ))
        f.codigoFamilia: f,
    };
    final codigos = [
      for (final a in armadas.valueOrNull ?? const <FamiliaArmadaEntity>[])
        a.codigoFamilia,
    ];
    final articulos =
        ref
            .watch(articulosPorFamiliasProvider(ClaveFamilias(codigos)))
            .whenData(articulosPorFamilia)
            .valueOrNull;

    return armadas.when(
      // Con alto fijo: este paso scrollea entero y el esqueleto es una lista,
      // que sin alto dispara el assert de viewport sin limite.
      loading:
          () => const SizedBox(
            height: 260,
            child: EsqueletoLista(filas: 4, altoFila: 56),
          ),
      error:
          (e, _) => MensajeError(
            error: e,
            onReintentar:
                () => ref.invalidate(familiasArmadasProvider(idPropuesta)),
          ),
      data: (lista) {
        if (lista.isEmpty) {
          return const NotaDelDato(
            texto:
                'La propuesta todavía no tiene familias. Vuelva al paso '
                'anterior para cargarlas.',
            tono: TonoNota.aviso,
          );
        }
        final filas = [
          for (final a in lista)
            _Cargada(
              armada: a,
              familia: porCodigo[a.codigoFamilia],
              articulos:
                  articulos == null
                      ? null
                      : (articulos[a.codigoFamilia] ??
                          const <ArticuloPrecioEntity>[]),
            ),
        ];

        final listas = lista.fold<int>(0, (s, f) => s + f.lineas);
        final totalArticulos =
            articulos == null
                ? null
                : filas.fold<int>(0, (s, f) => s + (f.articulos?.length ?? 0));
        final variaciones = [
          for (final f in filas)
            if (f.variacion != null) f.variacion!,
        ];
        final media =
            variaciones.isEmpty
                ? null
                : variaciones.reduce((a, b) => a + b) / variaciones.length;
        final cs = Theme.of(context).colorScheme;

        final cifras = _Cifras(
          compacto: compacto,
          cifras: [
            CifraResumen(
              compacto: chico,
              matiz: matizAzul,
              icono: Icons.inventory_2_outlined,
              rotulo: 'Familias',
              valor: '${lista.length}',
              detalle: 'en la propuesta',
            ),
            CifraResumen(
              compacto: chico,
              matiz: matizVioleta,
              icono: Icons.price_change_outlined,
              rotulo: 'Listas',
              valor: '$listas',
              detalle: 'con precio propuesto',
            ),
            CifraResumen(
              compacto: chico,
              matiz: matizNaranja,
              icono: Icons.sell_outlined,
              rotulo: 'Artículos',
              valor: totalArticulos == null ? '…' : '$totalArticulos',
              detalle: 'cambian de precio',
            ),
            CifraResumen(
              compacto: chico,
              matiz: media == null ? cs.outline : colorVariacion(cs, media),
              icono:
                  media == null
                      ? Icons.trending_flat_rounded
                      : iconoVariacion(media),
              rotulo: 'Costo',
              valor: media == null ? '--' : variacionLegible(media),
              colorValor: media == null ? null : colorVariacion(cs, media),
              detalle: 'contra el actual',
            ),
          ],
        );

        final detalle =
            compacto
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final f in filas)
                      _TarjetaFamilia(
                        fila: f,
                        onEditar: () => _editar(context, f),
                        onArticulos:
                            () => mostrarArticulosDeFamilia(
                              context,
                              codigoFamilia: f.codigo,
                              descripcion: f.descripcion,
                              articulos: f.articulos ?? const [],
                            ),
                      ),
                  ],
                )
                : SizedBox(
                  // La tabla es de alto fijo: se le da el de sus filas, con un
                  // tope a partir del cual se recorre por dentro.
                  height: 24 + 40 + math.min(filas.length, 10) * 52 + 12,
                  child: TablaPropuesta<_Cargada>(
                    filas: filas,
                    columnas: [
                      ColumnaPropuesta(
                        'Código',
                        76,
                        (c, f) => celdaNumero(c, '${f.codigo}', fuerte: true),
                        alinear: Alignment.centerLeft,
                      ),
                      ColumnaPropuesta(
                        'Familia y proveedor',
                        240,
                        (c, f) => _CeldaFamilia(fila: f),
                        alinear: Alignment.centerLeft,
                      ),
                      ColumnaPropuesta(
                        'Artículos',
                        112,
                        (c, f) => BotonArticulos(
                          articulos: f.articulos,
                          onVer:
                              () => mostrarArticulosDeFamilia(
                                c,
                                codigoFamilia: f.codigo,
                                descripcion: f.descripcion,
                                articulos: f.articulos ?? const [],
                              ),
                        ),
                        alinear: Alignment.centerLeft,
                      ),
                      ColumnaPropuesta(
                        'Actual',
                        92,
                        (c, f) => celdaNumero(
                          c,
                          f.costoActual == null
                              ? '--'
                              : fmtMonto.format(f.costoActual!),
                        ),
                        banda: 'Costo por tonelada (USD)',
                      ),
                      ColumnaPropuesta(
                        'Propuesto',
                        100,
                        (c, f) => celdaNumero(
                          c,
                          f.armada.costoSug == null
                              ? 'Sin costo'
                              : fmtMonto.format(f.armada.costoSug!),
                          fuerte: true,
                        ),
                        banda: 'Costo por tonelada (USD)',
                      ),
                      ColumnaPropuesta(
                        'Variación',
                        88,
                        (c, f) => CeldaVariacion(variacion: f.variacion),
                        banda: 'Costo por tonelada (USD)',
                      ),
                      ColumnaPropuesta(
                        'Listas',
                        56,
                        (c, f) => celdaNumero(c, '${f.armada.lineas}'),
                      ),
                      ColumnaPropuesta(
                        '',
                        52,
                        (c, f) => _BotonEditar(onPressed: () => _editar(c, f)),
                        alinear: Alignment.center,
                      ),
                    ],
                  ),
                );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cifras,
            const SizedBox(height: Esp.l),
            BloquePanel(
              titulo: 'Familias de la propuesta',
              icono: Icons.price_change_outlined,
              subtitulo:
                  'Para cambiar el costo o el % de utilidad de una, toque '
                  'Editar: se guarda sin volver al paso anterior.',
              hijo: detalle,
            ),
          ],
        );
      },
    );
  }
}

class _CeldaFamilia extends StatelessWidget {
  const _CeldaFamilia({required this.fila});

  final _Cargada fila;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fila.descripcion,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(
            fontWeight: Peso.titulo,
            color: fila.familia == null ? cs.error : cs.onSurface,
          ),
        ),
        if (fila.proveedor.trim().isNotEmpty)
          Text(
            fila.proveedor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// Editar una familia desde la revision, en el ambar de "Editar" del modulo.
class _BotonEditar extends StatelessWidget {
  const _BotonEditar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = AccionDePropuesta.editar.tonos(Theme.of(context).colorScheme);
    return IconButton(
      tooltip: 'Editar: costo y % de utilidad',
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: t.fondo,
        foregroundColor: t.icono,
        minimumSize: const Size(34, 34),
        maximumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Esquina.chica),
          side: BorderSide(color: t.icono.withValues(alpha: 0.35)),
        ),
      ),
    );
  }
}

class _TarjetaFamilia extends StatelessWidget {
  const _TarjetaFamilia({
    required this.fila,
    required this.onEditar,
    required this.onArticulos,
  });

  final _Cargada fila;
  final VoidCallback onEditar;
  final VoidCallback onArticulos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final f = fila;

    return Container(
      margin: const EdgeInsets.only(bottom: Esp.s),
      padding: const EdgeInsets.fromLTRB(Esp.m, Esp.s, Esp.xs, Esp.s),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Esquina.chica),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Familia ${f.codigo}',
                      style: tt.titleSmall?.copyWith(fontWeight: Peso.titulo),
                    ),
                    Text(
                      f.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(
                        color:
                            f.familia == null ? cs.error : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _BotonEditar(onPressed: onEditar),
            ],
          ),
          const SizedBox(height: Esp.s),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            f.armada.costoSug == null
                                ? 'Sin costo'
                                : 'USD ${fmtMonto.format(f.armada.costoSug!)}',
                        style: context.numero(fuerte: true),
                      ),
                      TextSpan(
                        text:
                            f.costoActual == null
                                ? ''
                                : '  antes ${fmtMonto.format(f.costoActual!)}',
                        style: context.apagado(),
                      ),
                    ],
                  ),
                ),
              ),
              CeldaVariacion(variacion: f.variacion),
              const SizedBox(width: Esp.s),
            ],
          ),
          Row(
            children: [
              Text(
                '${f.armada.lineas} ${f.armada.lineas == 1 ? 'lista' : 'listas'}',
                style: context.apagado(),
              ),
              const Spacer(),
              BotonArticulos(articulos: f.articulos, onVer: onArticulos),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ARTICULOS (propuesta por articulo)
// ═══════════════════════════════════════════════════════════════════════════

class _Articulos extends ConsumerWidget {
  const _Articulos({
    required this.idPropuesta,
    required this.compacto,
    required this.chico,
  });

  final BigInt idPropuesta;
  final bool compacto;
  final bool chico;

  /// Mas que esto es una lista para recorrer, no un resumen: el resto se ve en
  /// la vista preliminar.
  static const int _maximo = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articulos = ref.watch(articulosArmadosProvider(idPropuesta));

    return articulos.when(
      // Con alto fijo: este paso scrollea entero y el esqueleto es una lista,
      // que sin alto dispara el assert de viewport sin limite.
      loading:
          () => const SizedBox(
            height: 260,
            child: EsqueletoLista(filas: 4, altoFila: 56),
          ),
      error:
          (e, _) => MensajeError(
            error: e,
            onReintentar:
                () => ref.invalidate(articulosArmadosProvider(idPropuesta)),
          ),
      data: (lista) {
        if (lista.isEmpty) {
          return const NotaDelDato(
            texto:
                'La propuesta todavía no tiene artículos. Vuelva al paso '
                'anterior para agregarlos.',
            tono: TonoNota.aviso,
          );
        }
        final ordenados = [...lista]
          ..sort((a, b) => a.codArticulo.compareTo(b.codArticulo));
        final familias = {for (final a in lista) a.codigoFamilia}.length;
        final visibles = ordenados.take(_maximo).toList();

        final cifras = _Cifras(
          compacto: compacto,
          cifras: [
            CifraResumen(
              compacto: chico,
              matiz: matizNaranja,
              icono: Icons.sell_outlined,
              rotulo: 'Artículos',
              valor: '${lista.length}',
              detalle: 'con precio propuesto',
            ),
            CifraResumen(
              compacto: chico,
              matiz: matizAzul,
              icono: Icons.inventory_2_outlined,
              rotulo: 'Familias',
              valor: '$familias',
              detalle: 'de las que toman precio',
            ),
          ],
        );

        final Widget detalle =
            compacto
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final a in visibles) _RenglonArticulo(articulo: a),
                  ],
                )
                : SizedBox(
                  height: 40 + math.min(visibles.length, 10) * 52 + 12,
                  child: TablaPropuesta<ArticuloPropuestoEntity>(
                    filas: visibles,
                    columnas: [
                      ColumnaPropuesta(
                        'Código',
                        180,
                        (c, a) => celdaTexto(c, a.codArticulo, fuerte: true),
                        alinear: Alignment.centerLeft,
                      ),
                      ColumnaPropuesta(
                        'Descripción',
                        360,
                        (c, a) => celdaTexto(
                          c,
                          a.datoArticulo.trim().isEmpty
                              ? 'Sin descripción'
                              : a.datoArticulo.trim(),
                          maxLineas: 2,
                        ),
                        alinear: Alignment.centerLeft,
                      ),
                      ColumnaPropuesta(
                        'Familia',
                        80,
                        (c, a) => celdaNumero(c, '${a.codigoFamilia}'),
                      ),
                      ColumnaPropuesta(
                        'Stock',
                        88,
                        (c, a) => celdaNumero(c, fmtCantidad.format(a.stock)),
                      ),
                    ],
                  ),
                );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cifras,
            const SizedBox(height: Esp.l),
            BloquePanel(
              titulo: 'Artículos de la propuesta',
              icono: Icons.sell_outlined,
              subtitulo:
                  ordenados.length > _maximo
                      ? 'Los primeros $_maximo de ${ordenados.length}; el '
                          'resto está en la vista preliminar.'
                      : 'Cada uno toma el precio por tonelada de su familia '
                          'dividido por su UTM.',
              hijo: detalle,
            ),
          ],
        );
      },
    );
  }
}

class _RenglonArticulo extends StatelessWidget {
  const _RenglonArticulo({required this.articulo});

  final ArticuloPropuestoEntity articulo;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            articulo.codArticulo,
            style: tt.bodyMedium?.copyWith(fontWeight: Peso.titulo),
          ),
          Text(
            articulo.datoArticulo.trim().isEmpty
                ? 'Sin descripción'
                : articulo.datoArticulo.trim(),
            style: tt.bodySmall,
          ),
          Text(
            'Familia ${articulo.codigoFamilia} · Stock '
            '${fmtCantidad.format(articulo.stock)}',
            style: context.apagado(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// QUE SIGUE Y FLETES
// ═══════════════════════════════════════════════════════════════════════════

/// Los pasos que faltan, cada uno con su boton. El principal -enviar a
/// autorizar- es el unico lleno.
class _QueSigue extends StatelessWidget {
  const _QueSigue({
    required this.puedeEnviar,
    required this.enviando,
    required this.onVista,
    required this.onPdf,
    required this.onEnviar,
  });

  final bool puedeEnviar;
  final bool enviando;
  final VoidCallback onVista;
  final VoidCallback onPdf;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    return BloquePanel(
      titulo: 'Qué sigue',
      icono: Icons.flag_outlined,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Paso(
            numero: 1,
            matiz: matizAzul,
            titulo: 'Revise los precios',
            detalle: 'Como los verá quien autoriza.',
            hijo: Wrap(
              spacing: Esp.s,
              runSpacing: Esp.s,
              children: [
                OutlinedButton.icon(
                  onPressed: onVista,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Vista preliminar'),
                ),
                OutlinedButton.icon(
                  onPressed: onPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('PDF'),
                ),
              ],
            ),
          ),
          _Paso(
            numero: 2,
            matiz: matizVioleta,
            titulo: 'Envíela a autorizar',
            detalle:
                'Pasa a En espera y ya no se edita. Mientras esté Pendiente '
                'puede seguir armándola con «Editar» desde el listado.',
            hijo:
                puedeEnviar
                    ? SizedBox(
                      width: double.infinity,
                      child: BotonAccion(
                        etiqueta: 'Enviar a autorizar',
                        etiquetaOcupado: 'Enviando',
                        icono: Icons.send_rounded,
                        ocupado: enviando,
                        onPressed: onEnviar,
                      ),
                    )
                    : const NotaDelDato(
                      texto:
                          'No tiene el permiso para enviar propuestas a '
                          'autorizar. Quien lo tenga puede mandarla desde el '
                          'listado de propuestas.',
                    ),
          ),
          const _Paso(
            numero: 3,
            matiz: matizVerde,
            titulo: 'Quien autoriza la aprueba o la rechaza',
            detalle:
                'Al aprobarla, los precios propuestos pasan a ser los '
                'vigentes.',
            ultimo: true,
          ),
        ],
      ),
    );
  }
}

/// Un paso numerado, unido al siguiente por una linea.
class _Paso extends StatelessWidget {
  const _Paso({
    required this.numero,
    required this.matiz,
    required this.titulo,
    required this.detalle,
    this.hijo,
    this.ultimo = false,
  });

  final int numero;
  final Color matiz;
  final String titulo;
  final String detalle;
  final Widget? hijo;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = tonosDeMatiz(matiz, cs);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.icono,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$numero',
                  style: tt.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: Peso.dato,
                  ),
                ),
              ),
              if (!ultimo)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: Esp.xs),
                    color: cs.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultimo ? 0 : Esp.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      titulo,
                      style: tt.titleSmall?.copyWith(fontWeight: Peso.titulo),
                    ),
                  ),
                  Text(detalle, style: context.apagado()),
                  if (hijo != null) ...[const SizedBox(height: Esp.s), hijo!],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fletes extends StatelessWidget {
  const _Fletes({required this.fletes});

  final List<FleteArmadoEntity> fletes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BloquePanel(
      titulo: 'Flete por sucursal',
      icono: Icons.local_shipping_outlined,
      subtitulo: 'USD por tonelada: se suma al precio de cada lista.',
      hijo:
          fletes.isEmpty
              ? const NotaDelDato(
                texto: 'La propuesta no tiene fletes guardados.',
                tono: TonoNota.aviso,
              )
              : Column(
                children: [
                  for (final (i, f) in fletes.indexed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Esp.s,
                        vertical: Esp.s,
                      ),
                      decoration: BoxDecoration(
                        color: i.isOdd ? cs.surfaceContainerLow : null,
                        borderRadius: BorderRadius.circular(Esquina.chica),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: Esp.s),
                          Expanded(
                            child: Text(
                              f.nombreSucursal.isEmpty
                                  ? 'Sucursal ${f.codSucursal}'
                                  : f.nombreSucursal,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            montoLegible(f.valor, moneda: 'USD'),
                            style: context.numero(
                              fuerte: f.valor > 0,
                              color: f.valor > 0 ? null : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
    );
  }
}
