/// La vista preliminar de una propuesta: sus artículos con el precio de cada
/// lista. Todo sale de `/price/vistaPropuesta`, armada con los mismos
/// procedimientos que el PDF (ramas F y H) y el Excel de la generación (ramas D y
/// G): lo que se ve es lo que se imprime y se carga en SAP.
///
/// Precio (`MedidaVista`): por tonelada (filas del PDF); Bs (Impexpap) = tonelada
/// / UTM x tipo de cambio SAP; USD (Impexpap) = tonelada / UTM; Bs Productiva = Bs
/// de Impexpap menos 7 %. El tipo de cambio va en la leyenda para verificarlo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/vista_propuesta_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cabeza_y_lista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/pdf_precios.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_detalle_piezas.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_en_autorizacion.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_propuestas.dart';
import 'package:bosque_flutter/presentation/widgets/precios/vista_preliminar_reporte.dart';

// El diálogo

class VistaPreliminarPropuesta extends ConsumerStatefulWidget {
  const VistaPreliminarPropuesta({
    super.key,
    required this.fila,
    required this.preliminar,
    this.onEnviarAEspera,
  });

  final PropuestaEnAutorizacion fila;

  /// La version que abre "Editar" o la revision del asistente: la propuesta
  /// que todavia se arma, con el atajo para mandarla a autorizar.
  final bool preliminar;
  final VoidCallback? onEnviarAEspera;

  @override
  ConsumerState<VistaPreliminarPropuesta> createState() =>
      _VistaPreliminarPropuestaState();
}

class _VistaPreliminarPropuestaState
    extends ConsumerState<VistaPreliminarPropuesta> {
  String _busqueda = '';
  MedidaVista _medida = MedidaVista.tonelada;

  /// La sucursal elegida en la vista angosta. Null = la primera.
  String? _sucursal;

  @override
  Widget build(BuildContext context) {
    // Aquí sí MediaQuery: un diálogo vive en el Overlay raíz, no dentro del cajón de
    // la pantalla; lo de adentro se decide con LayoutBuilder.
    final pantalla = MediaQuery.sizeOf(context);
    final id = widget.fila.idPropuesta;
    final datos = ref.watch(vistaPropuestaProvider(id));
    final vista = datos.valueOrNull;

    final Widget cuerpo = datos.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.all(Esp.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => MensajeError(
            error: e,
            onReintentar: () => ref.invalidate(vistaPropuestaProvider(id)),
          ),
      data: (v) {
        if (v.filas.isEmpty) {
          return const MensajeVacio(
            icono: Icons.inventory_2_outlined,
            titulo: 'La propuesta no tiene artículos',
            detalle:
                'Todavía no se le cargaron familias ni artículos, o los '
                'precios propuestos no se guardaron. Mientras esté Pendiente '
                'se completa con «Editar» desde el listado.',
          );
        }
        // Sin precios por unidad (SAP no contesto) solo queda por tonelada.
        final medidas = [
          for (final m in MedidaVista.values)
            if (!m.porUnidad || v.preciosPorUnidad) m,
        ];
        return _Contenido(
          vista: v,
          busqueda: _busqueda,
          medida: medidas.contains(_medida) ? _medida : MedidaVista.tonelada,
          medidas: medidas,
          sucursal: _sucursal,
          onBuscar: (t) => setState(() => _busqueda = t),
          onMedida: (m) => setState(() => _medida = m),
          onSucursal: (s) => setState(() => _sucursal = s),
        );
      },
    );

    final cuenta =
        vista == null || vista.filas.isEmpty
            ? null
            : _Cuenta(
              articulos: vista.filas.length,
              familias: vista.filas.map((f) => f.codigoFamilia).toSet().length,
              listas: vista.listas.length,
            );

    return Dialog(
      insetPadding: EdgeInsets.all(pantalla.width < 600 ? Esp.s : Esp.xl),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1440,
          maxHeight: pantalla.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Cabecera(fila: widget.fila, preliminar: widget.preliminar),
            Flexible(child: cuerpo),
            _Pie(
              cuenta: cuenta,
              preliminar: widget.preliminar,
              onEnviarAEspera: widget.onEnviarAEspera,
              onPdf:
                  cuenta == null
                      ? null
                      : () => verPdfDePropuesta(context, ref, widget.fila),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo que cuenta el pie.
@immutable
class _Cuenta {
  const _Cuenta({
    required this.articulos,
    required this.familias,
    required this.listas,
  });

  final int articulos;
  final int familias;
  final int listas;
}

// Cabecera y pie

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.fila, required this.preliminar});

  final PropuestaEnAutorizacion fila;
  final bool preliminar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Lo que todavia no paso no se nombra: "Sin resolver" y "Sin generar" ya
    // los dice el estado de la esquina, y en un telefono son dos renglones.
    String quien(String nombre) =>
        nombre.trim().isEmpty ? '' : ' por ${nombre.trim()}';
    final hechos = [
      _Hecho(
        icono: Icons.person_outline,
        texto: 'Propuesta${quien(fila.propuestoPor)} · ${fila.fechaPropuesta}',
      ),
      EtiquetaTipoPropuesta(fila: fila),
      if (fila.tieneResolucion)
        _Hecho(
          icono: Icons.how_to_reg_outlined,
          texto:
              '${fila.autorizacion.etiquetaEstado}${quien(fila.resueltoPor)}'
              ' · ${fila.fechaResolucion}',
        ),
      if (fila.propuesta.fueGenerada || fila.generadoPor.trim().isNotEmpty)
        _Hecho(
          icono: Icons.file_download_outlined,
          texto: 'Generada${quien(fila.generadoPor)} · ${fila.fechaGeneracion}',
        ),
    ];

    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.s, Esp.m),
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
                      preliminar ? 'VISTA PRELIMINAR' : 'PROPUESTA DE PRECIOS',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: Peso.titulo,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Propuesta N.º ${fila.idPropuesta}'
                      '${fila.titulo.trim().isEmpty ? '' : ' · ${fila.titulo.trim()}'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleMedium?.copyWith(fontWeight: Peso.dato),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Esp.s),
              ChipEstadoPropuesta(autorizacion: fila.autorizacion),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: Esp.s),
          Wrap(spacing: Esp.l, runSpacing: Esp.xs, children: hechos),
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
      // Flexible: un nombre largo en un telefono no entra en un renglon.
      Flexible(child: Text(texto, style: context.apagado())),
    ],
  );
}

class _Pie extends StatelessWidget {
  const _Pie({
    required this.cuenta,
    required this.preliminar,
    required this.onEnviarAEspera,
    required this.onPdf,
  });

  final _Cuenta? cuenta;
  final bool preliminar;
  final VoidCallback? onEnviarAEspera;

  /// Null mientras no hay articulos: no hay nada que imprimir.
  final VoidCallback? onPdf;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m = cuenta;
    String contar(int n, String uno, String varios) =>
        '$n ${n == 1 ? uno : varios}';

    // En un telefono no entran tres botones con rotulo al lado de la cuenta:
    // el PDF queda como icono.
    final angosto = MediaQuery.sizeOf(context).width < 600;
    final pdf =
        angosto
            ? IconButton(
              tooltip: 'Descargar PDF',
              onPressed: onPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
            )
            : OutlinedButton.icon(
              onPressed: onPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('PDF'),
            );

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(Esp.l, Esp.s, Esp.m, Esp.s),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, r) {
                if (m == null) return const SizedBox();
                // Al lado de "Enviar a autorizar", en un telefono entra solo
                // la cuenta de articulos; el resto se ve en la lista.
                final completo = r.maxWidth >= 320;
                return Text(
                  [
                    contar(m.articulos, 'artículo', 'artículos'),
                    if (completo) ...[
                      contar(m.familias, 'familia', 'familias'),
                      contar(m.listas, 'lista de precio', 'listas de precio'),
                    ],
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.apagado(),
                );
              },
            ),
          ),
          pdf,
          const SizedBox(width: Esp.s),
          if (preliminar && onEnviarAEspera != null) ...[
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(context);
                onEnviarAEspera!();
              },
              icon: const Icon(Icons.gavel_outlined, size: 18),
              label: const Text('Enviar a autorizar'),
            ),
            const SizedBox(width: Esp.s),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// Contenido

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.vista,
    required this.busqueda,
    required this.medida,
    required this.medidas,
    required this.sucursal,
    required this.onBuscar,
    required this.onMedida,
    required this.onSucursal,
  });

  final VistaPropuestaEntity vista;
  final String busqueda;
  final MedidaVista medida;
  final List<MedidaVista> medidas;
  final String? sucursal;
  final ValueChanged<String> onBuscar;
  final ValueChanged<MedidaVista> onMedida;
  final ValueChanged<String> onSucursal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, r) {
        // La tabla completa pide unos 1400 px (doce listas); por debajo de mil
        // seria mas scroll lateral que tabla y se pasa a una sucursal por vez.
        final amplio = r.maxWidth >= 1000;
        final texto = busqueda.trim().toLowerCase();
        final hay = vista.filas.any((f) => coincideEnVista(f, texto));
        final sucursales = [
          for (final (nombre, _) in gruposDeSucursal(vista.listas)) nombre,
        ];
        final elegida =
            sucursal != null && sucursales.contains(sucursal)
                ? sucursal!
                : (sucursales.isEmpty ? '' : sucursales.first);

        final barra = _Barra(
          amplio: amplio,
          vista: vista,
          busqueda: busqueda,
          medida: medida,
          medidas: medidas,
          sucursales: sucursales,
          sucursal: elegida,
          onBuscar: onBuscar,
          onMedida: onMedida,
          onSucursal: onSucursal,
        );

        final Widget cuerpo;
        if (!hay) {
          cuerpo = MensajeVacio(
            icono: Icons.search_off,
            titulo: 'Ningún artículo coincide',
            detalle:
                'La propuesta tiene ${vista.filas.length} artículos. '
                'Pruebe con otro código o descripción.',
          );
        } else if (amplio) {
          cuerpo = TablaReportePropuesta(
            vista: vista,
            medida: medida,
            texto: texto,
          );
        } else {
          cuerpo = ReportePropuestaSucursal(
            vista: vista,
            medida: medida,
            texto: texto,
            sucursal: elegida,
          );
        }

        // En un telefono con el teclado abierto (el buscador de articulos)
        // la barra no deja lugar al reporte: CabezaYLista la acota.
        return CabezaYLista(altoCompacto: 320, cabeza: [barra], lista: cuerpo);
      },
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.amplio,
    required this.vista,
    required this.busqueda,
    required this.medida,
    required this.medidas,
    required this.sucursales,
    required this.sucursal,
    required this.onBuscar,
    required this.onMedida,
    required this.onSucursal,
  });

  final bool amplio;
  final VistaPropuestaEntity vista;
  final String busqueda;
  final MedidaVista medida;
  final List<MedidaVista> medidas;
  final List<String> sucursales;
  final String sucursal;
  final ValueChanged<String> onBuscar;
  final ValueChanged<MedidaVista> onMedida;
  final ValueChanged<String> onSucursal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selector = SegmentedButton<MedidaVista>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        for (final m in medidas)
          ButtonSegment<MedidaVista>(
            value: m,
            label: Tooltip(message: m.ayuda, child: Text(m.etiqueta)),
          ),
      ],
      selected: {medida},
      onSelectionChanged: (s) => onMedida(s.first),
    );
    // Sin precios por unidad no hay nada que elegir.
    final hayQueElegir = medidas.length > 1;

    final buscador = BuscadorPropuesta(
      texto: busqueda,
      pista: 'Buscar artículo',
      ancho: amplio ? 300 : null,
      alCambiar: onBuscar,
    );

    // Que se ve y de donde sale: con el tipo de cambio a la vista, cualquiera
    // puede rehacer la cuenta de una celda.
    final leyenda = Wrap(
      spacing: Esp.l,
      runSpacing: Esp.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(medida.explicacion(vista.tipoCambio), style: context.apagado()),
        if (!medida.porUnidad && vista.conComparacion)
          const LeyendaComparacion(),
      ],
    );
    final aviso = vista.avisoPreciosPorUnidad;

    final Widget controles;
    if (amplio) {
      controles = Row(
        children: [
          buscador,
          const Spacer(),
          if (hayQueElegir) ...[
            Text('Mostrar', style: context.apagado()),
            const SizedBox(width: Esp.s),
            selector,
          ],
        ],
      );
    } else {
      controles = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Una sucursal por vez: sus cuatro listas entran sin scroll lateral
          // en un telefono.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in sucursales)
                  Padding(
                    padding: const EdgeInsets.only(right: Esp.s),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: s == sucursal,
                      onSelected: (_) => onSucursal(s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Esp.s),
          // Buscador y medida en un solo renglon: en un telefono cada renglon
          // de controles es un articulo menos a la vista.
          LayoutBuilder(
            builder:
                (context, r) => Row(
                  children: [
                    Expanded(child: buscador),
                    if (hayQueElegir) ...[
                      const SizedBox(width: Esp.s),
                      if (r.maxWidth >= 600)
                        selector
                      else
                        _MenuMedida(
                          medida: medida,
                          medidas: medidas,
                          onMedida: onMedida,
                        ),
                    ],
                  ],
                ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, Esp.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          controles,
          const SizedBox(height: Esp.s),
          leyenda,
          if (aviso != null) ...[
            const SizedBox(height: Esp.xs),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: cs.error),
                const SizedBox(width: Esp.xs),
                Expanded(
                  child: Text(
                    aviso,
                    style: context.apagado()?.copyWith(color: cs.error),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// La medida como menu, para cuando los cuatro segmentos no entran.
class _MenuMedida extends StatelessWidget {
  const _MenuMedida({
    required this.medida,
    required this.medidas,
    required this.onMedida,
  });

  final MedidaVista medida;
  final List<MedidaVista> medidas;
  final ValueChanged<MedidaVista> onMedida;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<MedidaVista>(
      tooltip: 'Qué precio se muestra',
      initialValue: medida,
      onSelected: onMedida,
      itemBuilder:
          (_) => [
            for (final m in medidas)
              PopupMenuItem<MedidaVista>(
                value: m,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(m.etiqueta),
                  subtitle: Text(m.ayuda),
                ),
              ),
          ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: Esp.m, right: Esp.xs),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              medida.etiqueta,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: Peso.titulo),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
