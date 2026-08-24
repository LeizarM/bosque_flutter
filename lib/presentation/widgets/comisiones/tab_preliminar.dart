import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/utils/formato_comision.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/preliminar_export_service.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/validadores_comision.dart';
import 'package:bosque_flutter/domain/entities/comision_por_rango_entity.dart';
import 'package:bosque_flutter/domain/entities/preliminar_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cambio_comision_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/barra_comparativa.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/reportes_pagadas.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/dialogo_items_pagados.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/dialogo_notas_fila.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Vista preliminar de comisiones antes de ejecutar el pago.
///
/// Las cuatro modalidades llaman al SP p_list_paraPagar heredado de Bosque v2,
/// así que los importes coinciden con los del sistema anterior.
///
/// Se ofrece en dos lecturas. El gráfico responde "quién se lleva cuánto", que
/// es lo que se mira primero; la tabla queda para cuando hay que verificar una
/// fila concreta. La misma información, dos preguntas distintas.
class TabPreliminar extends ConsumerStatefulWidget {
  const TabPreliminar({super.key, required this.modalidades});

  /// Solo las modalidades que el usuario tiene habilitadas en tb_vistaBtn.
  final List<ModalidadPreliminar> modalidades;

  @override
  ConsumerState<TabPreliminar> createState() => _TabPreliminarState();
}

enum _Vista { grafico, tabla }

class _TabPreliminarState extends ConsumerState<TabPreliminar> {
  _Vista _vista = _Vista.grafico;

  /// El tipo de cambio sugerido se aplica una sola vez, al abrir la pestana.
  /// Despues manda lo que haya escrito el usuario.
  bool _tcSembrado = false;

  /// Mientras se traen las notas de SAP no se muestra la tabla.
  ///
  /// Podria dejarse la tabla anterior visible y refrescarla al terminar, que es
  /// mas suave, pero seria mostrar numeros viejos sin decirlo justo cuando
  /// alguien entro a ver los de ahora. Peor: se leen, se anotan, y cambian
  /// solos dos segundos despues.
  bool _sincronizando = true;

  @override
  void initState() {
    super.initState();
    _traerNotasDeSap();
  }

  /// Le pide a SAP las notas nuevas al abrir la pestana, una sola vez.
  ///
  /// La carga real vive detras de p_abm_tcom_SincronizarNotas, que decide si
  /// hace falta: si los datos tienen menos de diez minutos no toca nada, y si
  /// ya hay otra carga en curso tampoco. Sin eso seria reescribir el 82 % de
  /// tcom_noPagado cada vez que alguien entra, y el proc de carga no tiene
  /// candado propio -su guardia contra duplicados es leer y despues insertar-.
  ///
  /// Si falla no se avisa ni se corta: la pestana igual muestra lo que haya en
  /// la tabla, que es lo que mostraba antes de que esto existiera. Que no se
  /// pueda hablar con SAP no es razon para dejar al vendedor sin su preliminar.
  Future<void> _traerNotasDeSap() async {
    try {
      final cargo =
          await ref.read(comisionesRepositoryProvider).sincronizarNotas();
      if (cargo && mounted) {
        ref.invalidate(preliminarProvider);
      }
    } catch (_) {
      // Silencio a proposito: ver el comentario de arriba.
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var filtro = ref.watch(filtroPreliminarProvider);

    final sugerido = ref.watch(tipoCambioSugeridoProvider).valueOrNull;
    if (sugerido != null && !_tcSembrado) {
      _tcSembrado = true;
      if (sugerido.tipoCambio != filtro.tc) {
        // Se aplica ya al filtro local para que la primera consulta salga con
        // el valor correcto y no haya que pedirla dos veces.
        filtro = filtro.copyWith(tc: sugerido.tipoCambio);
        final f = filtro;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(filtroPreliminarProvider.notifier).state = f;
        });
      }
    }

    // El filtro arranca en 'interno', que puede no estar entre las permitidas.
    // Se corrige antes de consultar para no pedir una rama sin permiso.
    if (!widget.modalidades.contains(filtro.modalidad)) {
      filtro = filtro.copyWith(modalidad: widget.modalidades.first);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(filtroPreliminarProvider.notifier).state = filtro;
      });
    }

    final datos = ref.watch(preliminarProvider(filtro));
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);

    // Si el periodo ya se ejecuto. Hace falta para explicar una pantalla
    // vacia: sin esto, un mes ya pagado y un mes sin notas se ven igual.
    final estado =
        ref
            .watch(
              estadoPeriodoProvider(
                ClavePeriodo(
                  mes: filtro.mes,
                  anio: filtro.anio,
                  esInterno: filtro.modalidad.esInterno,
                ),
              ),
            )
            .valueOrNull;
    final yaEjecutado = estado?.yaEjecutado ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BarraFiltros(padding: padding, modalidades: widget.modalidades),
        const Divider(height: 1),
        // Los reportes de comisiones pagadas viven aca ademas de en
        // Pendientes: esa pestania la abren solo los administradores, y el
        // vendedor necesita poder contrastar el preliminar contra lo que ya
        // se le pago. Arranca en el mismo periodo que esta mirando.
        // Sin Mes/Ano propios: los toma de los de arriba. Tener dos combos
        // iguales, uno debajo del otro y con el mismo valor, no se entiende.
        BarraReportesPagadas(
          padding: padding,
          alcance: AlcanceReportes.pagadas,
          mesInicial: filtro.mes,
          anioInicial: filtro.anio,
          periodoPropio: false,
        ),
        const Divider(height: 1),
        Expanded(
          child:
              _sincronizando
                  ? EstadoVista.cargando(
                    context,
                    mensaje: 'Trayendo notas de SAP',
                  )
                  : datos.when(
                    loading:
                        () => EstadoVista.cargandoTabla(
                          context,
                          columnas: 7,
                          filas: 8,
                        ),
                    error:
                        (e, _) => EstadoVista.error(
                          context,
                          error: e,
                          alReintentar:
                              () => ref.invalidate(preliminarProvider(filtro)),
                        ),
                    data: (filas) {
                      final detalle =
                          filas.where((f) => !f.esTotal).toList()
                            ..sort((a, b) => b.bsAPagar.compareTo(a.bsAPagar));

                      // Se mira `detalle` y no `filas`: el SP devuelve la fila
                      // de total aunque no haya ni un vendedor, asi que
                      // `filas.isEmpty` daba false y la pantalla pintaba un
                      // resumen en cero con el grafico en blanco.
                      if (detalle.isEmpty) {
                        return yaEjecutado
                            ? _PeriodoYaEjecutado(
                              periodo: estado!.periodo,
                              fecha: estado.fechaEjecucion,
                              modalidad: filtro.modalidad,
                              mes: filtro.mes,
                              anio: filtro.anio,
                            )
                            : EstadoVista.vacio(
                              context,
                              titulo: 'Sin comisiones para este período',
                              indicacion:
                                  'Pruebe con otro mes, o revise que las notas estén cerradas y sin pagar.',
                              icono: Icons.calculate_outlined,
                            );
                      }

                      return CustomScrollView(
                        slivers: [
                          // Con filas Y el periodo pagado, lo que se ve son
                          // notas posteriores al pago. Sin este aviso se lee
                          // como el mes entero, y el numero no cuadra contra
                          // la planilla que ya se firmo.
                          if (yaEjecutado)
                            SliverToBoxAdapter(
                              child: _AvisoYaEjecutado(
                                periodo: estado!.periodo,
                                padding: padding,
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: _Resumen(detalle: detalle, padding: padding),
                          ),
                          SliverToBoxAdapter(
                            child: _SelectorVista(
                              padding: padding,
                              vista: _vista,
                              alCambiar: (v) => setState(() => _vista = v),
                              filas: filas,
                              filtro: filtro,
                            ),
                          ),
                          if (_vista == _Vista.grafico)
                            _Grafico(detalle: detalle, padding: padding)
                          else
                            SliverToBoxAdapter(
                              child: _Tabla(
                                filas: filas,
                                padding: padding,
                                modalidad: filtro.modalidad,
                              ),
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 28)),
                        ],
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

/// Lo que se ve al abrir el preliminar de un periodo que ya se pago.
///
/// No es un "no hay datos": es que el preliminar, por definicion, lista notas
/// CERRADAS Y SIN PAGAR. Cuando el periodo se ejecuta, esas notas pasan a
/// tcom_pagado y el preliminar queda -correctamente- en cero. Lo que se pago
/// vive en el reporte, y a eso se manda.
class _PeriodoYaEjecutado extends StatelessWidget {
  const _PeriodoYaEjecutado({
    required this.periodo,
    required this.fecha,
    required this.modalidad,
    required this.mes,
    required this.anio,
  });

  final String periodo;
  final DateTime? fecha;
  final ModalidadPreliminar modalidad;

  /// El periodo en numeros. `periodo` ya es mm/aaaa, pero para pedirle algo al
  /// backend hacen falta los dos enteros, no la cadena armada.
  final int mes;
  final int anio;

  @override
  Widget build(BuildContext context) {
    final cuando =
        fecha == null ? '' : ' el ${FormatoComision.fecha.format(fecha!)}';

    return EstadoVista.vacio(
      context,
      // El mismo candado que usa la pestania Ejecutar para decir lo mismo.
      icono: Icons.lock_outline,
      titulo: 'El período $periodo ya fue ejecutado',
      indicacion:
          'El preliminar solo muestra notas cerradas y sin pagar, y este '
          'período se pagó$cuando: por eso no queda nada acá. Para ver lo que '
          'se pagó, use «${modalidad.reportePagadas}» en la barra de arriba.',
      // El segundo camino, el que el reporte no da: el reporte imprime lo
      // pagado, pero no dice que quedo FUERA del descuento ni por que. Esa
      // pregunta se responde con el detalle congelado, y este vacio es donde
      // la gente la hace: esta mirando un cero de un mes que si se pago.
      textoAccion: 'Ver qué quedó fuera del descuento',
      iconoAccion: Icons.rule_folder_outlined,
      alPulsarAccion:
          () => showDialog<void>(
            context: context,
            builder:
                (_) => DialogoItemsPagados(
                  filtro: FiltroItemsPagados(
                    mes: mes,
                    anio: anio,
                    esInterno: modalidad.esInterno,
                  ),
                  subtitulo:
                      'Período $periodo, ${modalidad.esInterno == 1 ? 'internos' : 'externos'}'
                      '${fecha == null ? '' : ', ejecutado$cuando'}',
                ),
          ),
    );
  }
}

/// Franja para el caso mixto: el periodo ya se pago, pero hay notas.
class _AvisoYaEjecutado extends StatelessWidget {
  const _AvisoYaEjecutado({required this.periodo, required this.padding});

  final String periodo;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.fromLTRB(padding, 12, padding, 0),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: ComisionesTema.brControl,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: cs.tertiary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, size: 18, color: cs.tertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El período $periodo ya fue ejecutado. Lo que sigue '
                        'son notas que entraron después del pago, no el mes '
                        'completo: el total pagado está en el reporte.',
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

// ── Resumen ───────────────────────────────────────────────────────────

class _Resumen extends StatelessWidget {
  const _Resumen({required this.detalle, required this.padding});

  final List<PreliminarComisionEntity> detalle;
  final double padding;

  @override
  Widget build(BuildContext context) {
    // Solo el detalle: el SP ya emite filas de total y sumarlas contaría doble.
    final totalBs = detalle.fold<double>(0, (a, f) => a + f.bsAPagar);
    final totalUsd = detalle.fold<double>(0, (a, f) => a + f.usdAPagar);
    final vendedores = detalle.map((f) => f.nombreVen).toSet().length;
    final mayor = detalle.isEmpty ? null : detalle.first;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 8),
      child: FranjaCifras(
        cifras: [
          TarjetaCifra(
            rotulo: 'Total a pagar',
            valor: 'Bs ${FormatoComision.monto.format(totalBs)}',
            detalle: 'USD ${FormatoComision.monto.format(totalUsd)}',
            icono: Icons.payments_outlined,
            destacada: true,
          ),
          TarjetaCifra(
            rotulo: 'Vendedores',
            valor: '$vendedores',
            detalle: '${detalle.length} líneas de detalle',
            icono: Icons.groups_outlined,
          ),
          if (mayor != null)
            TarjetaCifra(
              rotulo: 'Mayor comisión',
              valor: 'Bs ${FormatoComision.monto.format(mayor.bsAPagar)}',
              detalle:
                  mayor.nombreVen.isEmpty ? mayor.etiqueta : mayor.nombreVen,
              icono: Icons.trending_up,
            ),
        ],
      ),
    );
  }
}

class _SelectorVista extends StatelessWidget {
  const _SelectorVista({
    required this.padding,
    required this.vista,
    required this.alCambiar,
    required this.filas,
    required this.filtro,
  });

  final double padding;
  final _Vista vista;
  final ValueChanged<_Vista> alCambiar;
  final List<PreliminarComisionEntity> filas;
  final FiltroPreliminar filtro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 4, padding, 8),
      // Wrap y no Row: en un teléfono el selector y el botón no entran en una
      // línea, y un Row los recortaría sin avisar.
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<_Vista>(
            segments: const [
              ButtonSegment(
                value: _Vista.grafico,
                icon: Icon(Icons.bar_chart, size: 18),
                label: Text('Gráfico'),
              ),
              ButtonSegment(
                value: _Vista.tabla,
                icon: Icon(Icons.table_rows_outlined, size: 18),
                label: Text('Tabla'),
              ),
            ],
            selected: {vista},
            showSelectedIcon: false,
            onSelectionChanged: (s) => alCambiar(s.first),
          ),
          _BotonExportar(filas: filas, filtro: filtro),
        ],
      ),
    );
  }
}

/// Exporta a Excel lo que está viendo el usuario, con la misma modalidad,
/// período y tipo de cambio de la pantalla.
class _BotonExportar extends StatefulWidget {
  const _BotonExportar({required this.filas, required this.filtro});

  final List<PreliminarComisionEntity> filas;
  final FiltroPreliminar filtro;

  @override
  State<_BotonExportar> createState() => _BotonExportarState();
}

class _BotonExportarState extends State<_BotonExportar> {
  bool _generando = false;

  Future<void> _exportar() async {
    setState(() => _generando = true);
    try {
      final guardado = await PreliminarExportService.exportar(
        filas: widget.filas,
        filtro: widget.filtro,
      );
      if (!mounted) return;
      // Solo se avisa cuando hubo archivo: en el teléfono el diálogo se puede
      // cancelar, y decir "listo" ahí manda a buscar algo que no existe.
      if (guardado) {
        avisar(context, 'Planilla generada.');
      }
    } catch (e) {
      if (!mounted) return;
      avisar(context, 'No se pudo generar la planilla. $e', esError: true);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _generando || widget.filas.isEmpty ? null : _exportar,
      icon:
          _generando
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.table_view_outlined, size: 18),
      label: Text(_generando ? 'Generando...' : 'Exportar a Excel'),
    );
  }
}

// ── Gráfico ───────────────────────────────────────────────────────────

class _Grafico extends StatelessWidget {
  const _Grafico({required this.detalle, required this.padding});

  /// Filas de detalle: una por vendedor, tipo, tasa y periodo.
  final List<PreliminarComisionEntity> detalle;
  final double padding;

  @override
  Widget build(BuildContext context) {
    // Antes habia una barra por FILA, asi que un vendedor con ventas en dos
    // meses o en dos tramos aparecia varias veces y competia consigo mismo en
    // el ranking. Se agrupa por vendedor: el puesto sale del total, que es la
    // pregunta que responde el preliminar.
    final ranking = _agrupar(detalle);
    final maximo = ranking.isEmpty ? 0.0 : ranking.first.total;
    final total = ranking.fold<double>(0, (a, v) => a + v.total);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      sliver: SliverList.separated(
        itemCount: ranking.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final v = ranking[i];
          return _FilaVendedor(
            puesto: i + 1,
            vendedor: v,
            maximo: maximo,
            participacion: total <= 0 ? 0.0 : (v.total / total) * 100,
          );
        },
      ),
    );
  }

  /// Un elemento por vendedor, ordenado por total descendente. Adentro, una
  /// linea por combinacion de tipo y tasa: los periodos se juntan ahi porque
  /// dos meses con la misma tasa son el mismo concepto de pago.
  static List<_VendedorAgregado> _agrupar(
    List<PreliminarComisionEntity> filas,
  ) {
    final porVendedor = <String, _VendedorAgregado>{};

    for (final f in filas) {
      final clave = f.idVendedor?.toString() ?? f.nombreVen;
      final v = porVendedor.putIfAbsent(
        clave,
        () => _VendedorAgregado(f.nombreVen),
      );
      v.total += f.bsAPagar;
      v.montoBase += f.montoBase;

      final claveLinea = '${f.etiqueta}|${f.comision}';
      final linea = v.lineas.putIfAbsent(
        claveLinea,
        () => _LineaAgregada(f.etiqueta, f.comisionVisual),
      );
      linea.monto += f.bsAPagar;
      if (f.periodo.isNotEmpty) linea.periodos.add(f.periodo);
    }

    final lista = porVendedor.values.toList();
    for (final v in lista) {
      v.ordenadas =
          v.lineas.values.toList()..sort((a, b) => b.monto.compareTo(a.monto));
    }
    lista.sort((a, b) => b.total.compareTo(a.total));
    return lista;
  }
}

/// Un vendedor con su total y su desglose.
class _VendedorAgregado {
  _VendedorAgregado(this.nombre);

  final String nombre;
  double total = 0;
  double montoBase = 0;

  final Map<String, _LineaAgregada> lineas = {};
  List<_LineaAgregada> ordenadas = const [];
}

/// Una combinacion de tipo y tasa dentro de un vendedor.
class _LineaAgregada {
  _LineaAgregada(this.etiqueta, this.comisionVisual);

  final String etiqueta;
  final double comisionVisual;
  double monto = 0;

  /// Los meses que aporta esta combinacion. SplayTreeSet para que salgan
  /// ordenados y sin repetir, sin tener que ordenarlos despues.
  final SplayTreeSet<String> periodos = SplayTreeSet<String>();
}

class _FilaVendedor extends StatelessWidget {
  const _FilaVendedor({
    required this.puesto,
    required this.vendedor,
    required this.maximo,
    required this.participacion,
  });

  final int puesto;
  final _VendedorAgregado vendedor;
  final double maximo;
  final double participacion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final esMovil = ResponsiveUtilsBosque.isMobile(context);

    // El desglose se muestra cuando agrega algo: varias combinaciones de tipo
    // y tasa, o una sola pero repartida en mas de un mes. Con una combinacion
    // y un mes solo repetiria el importe que ya esta arriba.
    final mostrarDesglose =
        vendedor.ordenadas.length > 1 ||
        (vendedor.ordenadas.isNotEmpty &&
            vendedor.ordenadas.first.periodos.length > 1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Puesto(numero: puesto),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        vendedor.nombre.isEmpty ? '—' : vendedor.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight:
                              puesto == 1 ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          FormatoComision.monto.format(vendedor.total),
                          style: ComisionesTema.numeroCelda(
                            context,
                            fuerte: true,
                          ),
                        ),
                        Text(
                          '${participacion.toStringAsFixed(1)} % del total',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value:
                        maximo <= 0
                            ? 0.0
                            : (vendedor.total / maximo).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      puesto == 1
                          ? cs.primary
                          : cs.primary.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                if (mostrarDesglose) ...[
                  const SizedBox(height: 8),
                  for (final l in vendedor.ordenadas)
                    _LineaDesglose(linea: l, esMovil: esMovil),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// El numero de puesto. Los tres primeros van con el color de acento porque el
/// podio es lo que se mira primero; del cuarto en adelante, neutro.
class _Puesto extends StatelessWidget {
  const _Puesto({required this.numero});
  final int numero;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final podio = numero <= 3;

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            podio
                ? cs.primary.withValues(alpha: numero == 1 ? 1.0 : 0.18)
                : cs.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$numero',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color:
              numero == 1
                  ? cs.onPrimary
                  : podio
                  ? cs.primary
                  : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LineaDesglose extends StatelessWidget {
  const _LineaDesglose({required this.linea, required this.esMovil});

  final _LineaAgregada linea;
  final bool esMovil;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final partes = <String>[
      if (linea.etiqueta.isNotEmpty) linea.etiqueta,
      if (linea.comisionVisual > 0)
        '${linea.comisionVisual.toStringAsFixed(2)} %',
      // En movil se omiten los meses: la linea ya no entra, y ese dato esta en
      // la pestana Tabla, que es donde se concilia.
      if (!esMovil && linea.periodos.isNotEmpty) linea.periodos.join(', '),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              partes.join('  ·  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            FormatoComision.monto.format(linea.monto),
            style: ComisionesTema.numeroApoyo(
              context,
            )?.copyWith(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ── Filtros ───────────────────────────────────────────────────────────

class _BarraFiltros extends ConsumerWidget {
  const _BarraFiltros({required this.padding, required this.modalidades});

  final double padding;
  final List<ModalidadPreliminar> modalidades;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroPreliminarProvider);
    final notifier = ref.read(filtroPreliminarProvider.notifier);
    final anioActual = DateTime.now().year;

    final seleccion =
        modalidades.contains(filtro.modalidad)
            ? filtro.modalidad
            : modalidades.first;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scroll horizontal: con cuatro modalidades el botón segmentado no
          // entra en un teléfono y Flutter lo recortaría sin avisar.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ModalidadPreliminar>(
              segments: [
                for (final m in modalidades)
                  ButtonSegment(value: m, label: Text(m.etiqueta)),
              ],
              selected: {seleccion},
              showSelectedIcon: false,
              onSelectionChanged:
                  (s) => notifier.state = filtro.copyWith(modalidad: s.first),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            seleccion.detalle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<int>(
                  value: filtro.mes,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mes',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (var i = 1; i <= 12; i++)
                      DropdownMenuItem(value: i, child: Text(_meses[i - 1])),
                  ],
                  onChanged:
                      (v) =>
                          v == null
                              ? null
                              : notifier.state = filtro.copyWith(mes: v),
                ),
              ),
              SizedBox(
                width: 130,
                child: DropdownButtonFormField<int>(
                  value: filtro.anio,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Año',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (var a = anioActual - 6; a <= anioActual + 1; a++)
                      DropdownMenuItem(value: a, child: Text('$a')),
                  ],
                  onChanged:
                      (v) =>
                          v == null
                              ? null
                              : notifier.state = filtro.copyWith(anio: v),
                ),
              ),
              SizedBox(width: 160, child: _CampoTipoCambio(filtro: filtro)),
            ],
          ),
        ],
      ),
    );
  }
}

/// El tipo de cambio se aplica al salir del campo, no en cada tecla: si se
/// recalculara al tipear, cada dígito dispararía una consulta al backend.
class _CampoTipoCambio extends ConsumerStatefulWidget {
  const _CampoTipoCambio({required this.filtro});

  final FiltroPreliminar filtro;

  @override
  ConsumerState<_CampoTipoCambio> createState() => _CampoTipoCambioState();
}

class _CampoTipoCambioState extends ConsumerState<_CampoTipoCambio> {
  late final TextEditingController _ctrl;
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _texto(widget.filtro.tc));
  }

  @override
  void didUpdateWidget(covariant _CampoTipoCambio anterior) {
    super.didUpdateWidget(anterior);
    // El valor puede cambiar desde afuera cuando llega el sugerido del backend.
    // Se refleja salvo que el usuario esté escribiendo en ese momento.
    if (widget.filtro.tc != anterior.filtro.tc && !_foco.hasFocus) {
      _ctrl.text = _texto(widget.filtro.tc);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  static String _texto(double v) => v
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');

  void _aplicar() {
    final valor = ValidadoresComision.aDouble(_ctrl.text);
    if (valor == null || valor <= 0) {
      _ctrl.text = _texto(widget.filtro.tc);
      return;
    }
    if (valor == widget.filtro.tc) return;
    ref.read(filtroPreliminarProvider.notifier).state = widget.filtro.copyWith(
      tc: valor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sugerido = ref.watch(tipoCambioSugeridoProvider);

    return Focus(
      onFocusChange: (tiene) {
        if (!tiene) _aplicar();
      },
      child: TextField(
        controller: _ctrl,
        focusNode: _foco,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}([.,]\d{0,4})?$')),
        ],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _aplicar(),
        decoration: InputDecoration(
          labelText: 'Tipo de cambio',
          isDense: true,
          helperText: sugerido.when(
            loading: () => 'Consultando el del día...',
            error: (_, __) => 'No se pudo consultar; se usa el valor anterior',
            data: _origen,
          ),
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
          suffixIcon: sugerido.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            error: (_, __) => null,
            data:
                (tc) =>
                    tc.tipoCambio == widget.filtro.tc
                        ? null
                        : IconButton(
                          tooltip:
                              'Volver al del día (${_texto(tc.tipoCambio)})',
                          icon: const Icon(Icons.restore, size: 18),
                          onPressed: () {
                            _ctrl.text = _texto(tc.tipoCambio);
                            _aplicar();
                          },
                        ),
          ),
        ),
      ),
    );
  }

  static String _origen(TipoCambioComisionEntity tc) {
    switch (tc.origen) {
      case 'SAP':
        return tc.fecha == null
            ? 'Cotización de SAP'
            : 'SAP, ${FormatoComision.fecha.format(tc.fecha!)}';
      case 'HISTORICO':
        return tc.fecha == null
            ? 'Último registrado'
            : 'Último registrado: ${FormatoComision.fecha.format(tc.fecha!)}';
      default:
        return 'Valor por defecto: no hay cotización disponible';
    }
  }
}

// ── Tabla ─────────────────────────────────────────────────────────────

class _Tabla extends ConsumerWidget {
  const _Tabla({
    required this.filas,
    required this.padding,
    required this.modalidad,
  });

  final List<PreliminarComisionEntity> filas;
  final double padding;

  /// La pestana en la que se esta parado. Viaja al backend con el pedido de
  /// notas: es lo que le dice con que boton del ACL autorizar.
  final ModalidadPreliminar modalidad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    // Dos filas del mismo vendedor con el mismo tipo y el mismo periodo no son
    // un duplicado: son tramos distintos de tcom_comisionPorRango, y lo unico
    // que las separa es la tasa. La tasa sola no se lo explica a nadie, asi que
    // se le agrega al lado los dias de cobro que la originan.
    final etiquetaTramo = <String, String>{};
    ref.watch(rangosComisionProvider).whenData((lista) {
      final porTasa = <String, List<ComisionPorRangoEntity>>{};
      for (final r in lista) {
        porTasa.putIfAbsent(_claveTasa(r.tipo, r.comision), () => []).add(r);
      }
      porTasa.forEach((clave, tramos) {
        // Solo se etiqueta cuando la tasa identifica un unico tramo. En Contado
        // el 0,8% cubre dos (0 a 4 dias y pago anticipado): ahi el dato no
        // desambigua nada y mostrarlo seria afirmar algo que no se sabe.
        if (tramos.length == 1) {
          etiquetaTramo[clave] = tramos.first.rangoLegible;
        }
      });
    });

    String? tramoDe(PreliminarComisionEntity f) =>
        f.esTotal || f.comision == 0
            ? null
            : etiquetaTramo[_claveTasa(f.etiqueta, f.comision)];

    // Color por tasa y por periodo. El indice se calcula sobre los valores
    // ORDENADOS, no sobre el orden de aparicion, para que un mismo porcentaje
    // salga siempre del mismo color aunque cambie el mes consultado o el
    // vendedor que encabeza la lista.
    final tasas =
        filas
            .where((f) => !f.esTotal && f.comision != 0)
            .map((f) => f.comision)
            .toSet()
            .toList()
          ..sort();
    final periodos =
        filas
            .where((f) => !f.esTotal && f.periodo.isNotEmpty)
            .map((f) => f.periodo)
            .toSet()
            .toList()
          ..sort();

    // Un grupo son las filas de detalle de un vendedor mas su total. El SP las
    // entrega en ese orden, asi que el total cierra el grupo; si alguna rama
    // viniera sin total, el cambio de vendedor tambien lo corta.
    //
    // Con el nombre repetido a color pleno en cada fila, cinco lineas del mismo
    // vendedor se leian como el mismo registro cargado cinco veces. Se pinta el
    // nombre una sola vez por grupo y se alterna el fondo entre grupos.
    final abreGrupo = <bool>[];
    final indiceGrupo = <int>[];
    var grupo = 0;
    var grupoCerrado = true;
    String? vendedorAnterior;
    for (final f in filas) {
      final vendedor = f.idVendedor?.toString() ?? f.nombreVen;
      final abre = grupoCerrado || (!f.esTotal && vendedor != vendedorAnterior);
      if (abre && indiceGrupo.isNotEmpty) grupo++;
      abreGrupo.add(abre);
      indiceGrupo.add(grupo);
      grupoCerrado = f.esTotal;
      if (!f.esTotal) vendedorAnterior = vendedor;
    }

    // El SP deja bsAPagar y usdAPagar en NULL en la fila TOTAL de la modalidad
    // vigente —rama K: «Select 9999 as idv, ..., null, null, 3 as ord»— y por
    // eso llegaba como 0,00. La suma se hace aca sin inventar nada: son las
    // mismas filas de detalle que ya estan en pantalla.
    //
    // Suma SOLO el detalle de vendedores (ord 1). Las filas de supervision que
    // el SP agrega despues (ord 4, «Gerente de Ventas» y los supervisores) se
    // calculan sobre esa misma base y son otro concepto: sumarlas aca dejaria
    // la fila incoherente con su propio monto base, que tambien es solo de
    // vendedores.
    var sumaBs = 0.0;
    var sumaUsd = 0.0;
    for (final f in filas) {
      if (f.ord == 1) {
        sumaBs += f.bsAPagar;
        sumaUsd += f.usdAPagar;
      }
    }

    /// La fila TOTAL que el SP dejo sin sumar. 9999 es el idv literal que usa
    /// la rama K para marcarla. Se exige ademas que venga en cero para que, si
    /// algun dia el SP la calcula, mande el dato del servidor y no este parche.
    bool totalSinSumar(PreliminarComisionEntity f) =>
        f.esTotal && f.idVendedor == 9999 && f.bsAPagar == 0;

    // Solo se explica el tramo si en esta vista efectivamente hay alguno: en
    // las modalidades que no usan la escala por dias la nota sobraria.
    final hayTramos = filas.any((f) => tramoDe(f) != null);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hayTramos)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Un vendedor puede aparecer en varias filas del mismo tipo '
                      'y periodo: no estan repetidas, es la venta partida por '
                      'tramo segun los dias que tardo el cobro. Cada tramo paga '
                      'un porcentaje distinto.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: ComisionesTema.brContenedor,
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: ComisionesTema.brContenedor,
              child: LayoutBuilder(
                builder:
                    (context, limites) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        // La tabla ocupa todo el ancho disponible. Con un minimo fijo
                        // quedaba una franja vacia a la derecha en pantallas anchas.
                        // El ancho se mide FUERA del scroll horizontal: adentro
                        // limites.maxWidth es infinito, math.max lo propaga y el
                        // layout muere con "BoxConstraints forces an infinite width".
                        constraints: BoxConstraints(
                          minWidth: math.max(820, limites.maxWidth),
                        ),
                        child: DataTable(
                          headingRowColor: ComisionesTema.encabezadoTabla(
                            context,
                          ),
                          columnSpacing: ComisionesTema.separacionColumnas,
                          dataRowMinHeight: ComisionesTema.altoFila,
                          dataRowMaxHeight: ComisionesTema.altoFila,
                          headingRowHeight: ComisionesTema.altoEncabezado,
                          columns: const [
                            DataColumn(label: Text('Vendedor')),
                            DataColumn(label: Text('Grupo / Tipo')),
                            DataColumn(label: Text('Período')),
                            DataColumn(label: Text('Comisión'), numeric: true),
                            DataColumn(
                              label: Text('Monto base'),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text('Bs a pagar'),
                              numeric: true,
                            ),
                            DataColumn(label: Text('USD'), numeric: true),
                            // Sin rotulo: el icono ya dice que hace y ahorra
                            // ancho, que en esta tabla es lo que escasea.
                            DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (final (i, f) in filas.indexed)
                              DataRow(
                                onLongPress: () {},
                                color: WidgetStateProperty.resolveWith((
                                  estados,
                                ) {
                                  if (f.esTotal) {
                                    return cs.primaryContainer.withValues(
                                      alpha: 0.28,
                                    );
                                  }
                                  // El hover gana a la banda de grupo: la
                                  // banda dice a que vendedor pertenece la
                                  // fila -que no cambia-, el hover dice cual
                                  // se esta mirando ahora.
                                  if (estados.contains(WidgetState.hovered)) {
                                    return null;
                                  }
                                  return indiceGrupo[i].isEven
                                      ? null
                                      : cs.surfaceContainerHighest.withValues(
                                        alpha: 0.35,
                                      );
                                }),
                                cells: [
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Barra de acento: marca de un vistazo
                                        // donde empieza y termina el bloque de un
                                        // vendedor. Llena en la fila que lo abre y
                                        // en el total, tenue en las del medio.
                                        Container(
                                          width: 4,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            // Un color por vendedor: dos
                                            // bloques seguidos nunca comparten
                                            // barra.
                                            color: _colorVendedor(
                                              indiceGrupo[i],
                                            ).withValues(
                                              alpha:
                                                  f.esTotal || abreGrupo[i]
                                                      ? 1.0
                                                      : 0.40,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // El nombre se escribe UNA sola vez por
                                        // bloque. Repetido en cada fila hacia que
                                        // dos tramos del mismo vendedor, que solo
                                        // difieren en el porcentaje, se leyeran
                                        // como el mismo registro cargado dos veces.
                                        Text(
                                          f.esTotal || abreGrupo[i]
                                              ? (f.nombreVen.isEmpty
                                                  ? '—'
                                                  : f.nombreVen)
                                              : '',
                                          style: TextStyle(
                                            fontWeight:
                                                f.esTotal
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Builder(
                                      builder: (_) {
                                        final tramo = tramoDe(f);
                                        if (f.etiqueta.isEmpty) {
                                          return const Text('—');
                                        }
                                        if (tramo == null) {
                                          return Text(f.etiqueta);
                                        }
                                        return Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(text: f.etiqueta),
                                              TextSpan(
                                                text: '  ·  $tramo',
                                                style: TextStyle(
                                                  color: cs.onSurfaceVariant,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    f.periodo.isEmpty
                                        ? const Text('—')
                                        : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Punto por periodo: en las
                                            // modalidades que arrastran meses
                                            // anteriores distingue 06/2026 de
                                            // 07/2026 sin leer el numero.
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: _colorPeriodo(
                                                  periodos.indexOf(f.periodo),
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(f.periodo),
                                          ],
                                        ),
                                  ),
                                  DataCell(
                                    f.comision == 0
                                        ? const Text('—')
                                        : Builder(
                                          builder: (_) {
                                            final (fondo, texto) = _tonoTasa(
                                              context,
                                              tasas.indexOf(f.comision),
                                              tasas.length,
                                            );
                                            return ChipPorcentaje(
                                              valor: f.comisionVisual,
                                              fondoTono: fondo,
                                              textoTono: texto,
                                            );
                                          },
                                        ),
                                  ),
                                  DataCell(_Numero(valor: f.montoBase)),
                                  DataCell(
                                    _Numero(
                                      valor:
                                          totalSinSumar(f)
                                              ? sumaBs
                                              : f.bsAPagar,
                                      destacado: f.esTotal,
                                      nota:
                                          totalSinSumar(f)
                                              ? 'Suma de los vendedores. No '
                                                  'incluye las filas de '
                                                  'supervisión, que se calculan '
                                                  'aparte sobre este mismo monto.'
                                              : null,
                                    ),
                                  ),
                                  DataCell(
                                    _Numero(
                                      valor:
                                          totalSinSumar(f)
                                              ? sumaUsd
                                              : f.usdAPagar,
                                      destacado: f.esTotal,
                                      nota:
                                          totalSinSumar(f)
                                              ? 'Suma de los vendedores. No '
                                                  'incluye las filas de '
                                                  'supervisión, que se calculan '
                                                  'aparte sobre este mismo monto.'
                                              : null,
                                    ),
                                  ),
                                  DataCell(
                                    // Solo en las filas de detalle: el total es
                                    // una suma, no tiene notas propias que ver.
                                    f.esTotal || f.idVendedor == null
                                        ? const SizedBox.shrink()
                                        : IconButton(
                                          icon: const Icon(
                                            Icons.receipt_long_outlined,
                                            size: 20,
                                          ),
                                          tooltip: 'Ver notas a pagar',
                                          onPressed:
                                              () => showDialog<void>(
                                                context: context,
                                                builder:
                                                    (_) => DialogoNotasFila(
                                                      filtro:
                                                          FiltroNotaPreliminar(
                                                            idVendedor:
                                                                f.idVendedor!,
                                                            mes: f.mes ?? 0,
                                                            anio: f.anio ?? 0,
                                                            comision:
                                                                f.comision,
                                                            modalidad:
                                                                modalidad,
                                                          ),
                                                      nombreVendedor:
                                                          f.nombreVen,
                                                      etiqueta: f.etiqueta,
                                                      periodo: f.periodo,
                                                      comisionVisual:
                                                          f.comisionVisual,
                                                      tramo: tramoDe(f),
                                                    ),
                                              ),
                                        ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({required this.valor, this.destacado = false, this.nota});

  final double valor;
  final bool destacado;

  /// Aclaracion al pasar el cursor, para los importes que la pantalla calcula
  /// en vez de recibirlos del SP.
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final texto = Text(
      FormatoComision.monto.format(valor),
      style: ComisionesTema.numeroCelda(context, fuerte: destacado),
    );
    return nota == null ? texto : Tooltip(message: nota!, child: texto);
  }
}

/// Clave para cruzar una fila del preliminar con su tramo de comision. El tipo
/// se normaliza porque el SP lo devuelve capitalizado y la tabla de tramos no
/// siempre; la tasa se redondea porque viaja como float y 0.005 no siempre
/// vuelve identico.
String _claveTasa(String tipo, double comision) =>
    '${tipo.trim().toLowerCase()}|${comision.toStringAsFixed(6)}';

// ── Paletas del preliminar ──────────────────────────────────────────────────
//
// Tres codificaciones distintas conviven en la misma fila, asi que cada una
// usa su propia familia y su propia forma para que no se lean cruzadas:
//   vendedor -> barra vertical a la izquierda
//   periodo  -> punto redondo
//   tasa     -> chip relleno
// Los indices de vendedor y periodo se toman modulo el largo: si hay mas
// vendedores que colores el ciclo se repite, pero nunca en bloques contiguos.
// La tasa no usa lista de colores; ver _baseTasa.

/// Barra del bloque de cada vendedor.
const _coloresVendedor = <Color>[
  Color(0xFF2E7D32),
  Color(0xFF1565C0),
  Color(0xFF6A1B9A),
  Color(0xFFEF6C00),
  Color(0xFF00838F),
  Color(0xFFAD1457),
  Color(0xFF4E342E),
  Color(0xFF37474F),
];

/// Punto del periodo.
const _coloresPeriodo = <Color>[
  Color(0xFF1E88E5),
  Color(0xFFF4511E),
  Color(0xFF43A047),
  Color(0xFF8E24AA),
  Color(0xFF00ACC1),
  Color(0xFFFB8C00),
];

/// Chip de la tasa: un solo color, y la magnitud viaja en el alpha.
///
/// La rampa anterior eran seis matices -indigo, teal, lima, amarillo, naranja,
/// rojo- que recorrian 230 grados de tono. Se leia el orden, pero al costo de
/// meter un semaforo donde no hay nada bueno ni malo: una tasa alta no es una
/// alerta, y el rojo del modulo tiene que seguir queriendo decir "esto fallo".
///
/// Tampoco sirve reemplazarla por un mismo tono "de claro a oscuro". El chip
/// fija la lightness del texto en un valor unico por tema y pinta el fondo con
/// alpha, o sea descarta la lightness del color base: seis violetas de distinto
/// brillo saldrian como seis chips identicos. Por eso lo que recorre la escala
/// aca es el ALPHA del fondo, que es lo unico que sobrevive a esa cuenta.
const _baseTasa = Color(0xFF4527A0);

Color _colorVendedor(int i) => _coloresVendedor[i % _coloresVendedor.length];

Color _colorPeriodo(int i) =>
    i < 0 ? _coloresPeriodo.first : _coloresPeriodo[i % _coloresPeriodo.length];

(Color, Color) _tonoTasa(BuildContext context, int i, int n) {
  final oscuro = Theme.of(context).brightness == Brightness.dark;
  final t = (i < 0 || n <= 1) ? 0.0 : i.clamp(0, n - 1) / (n - 1);
  final hsl = HSLColor.fromColor(_baseTasa);
  return (
    _baseTasa.withValues(alpha: oscuro ? 0.22 + t * 0.33 : 0.14 + t * 0.34),
    hsl.withLightness(oscuro ? 0.82 : 0.26).toColor(),
  );
}
