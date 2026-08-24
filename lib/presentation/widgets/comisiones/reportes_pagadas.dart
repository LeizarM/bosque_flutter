import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/descargar_reportes_jasper.dart';

/// Empresas que distingue el reporte de comisiones pagadas.
///
/// El SP tiene una rama por empresa: 'A' cubre IMPEXPAP, PRODUCTIVA PAPEL y
/// PAPIRUS, y 'G' cubre ESPPAPEL. Por eso son dos opciones y no tres.
enum EmpresaReporte {
  impexpap('IMPEXPAP y Productiva', 'impexpap'),
  esppapel('Esppapel', 'esppapel');

  const EmpresaReporte(this.etiqueta, this.archivo);
  final String etiqueta;
  final String archivo;
}

/// Qué reportes ofrece la barra.
///
/// El preliminar solo necesita los de comisiones pagadas: es la consulta que
/// hace cualquier vendedor para contrastar contra lo que está viendo. Los de
/// importación y notas pendientes son de operación y viven en su pestaña.
enum AlcanceReportes { pagadas, todos }

/// Barra de descarga de los reportes de comisiones pagadas.
///
/// Vive en un archivo propio porque la usan dos pestañas con permisos
/// distintos: Pendientes, que en la práctica solo abren los administradores, y
/// Preliminar, que abre cualquier vendedor. Duplicarla habría dejado dos
/// combinaciones de mes/año/empresa que se desincronizan a la primera
/// corrección.
class BarraReportesPagadas extends ConsumerStatefulWidget {
  const BarraReportesPagadas({
    super.key,
    required this.padding,
    this.alcance = AlcanceReportes.todos,
    this.mesInicial,
    this.anioInicial,
    this.periodoPropio = true,
  });

  final double padding;
  final AlcanceReportes alcance;

  /// Período con el que arranca, cuando la barra elige el suyo.
  final int? mesInicial;
  final int? anioInicial;

  /// Si la barra dibuja sus propios selectores de mes y año.
  ///
  /// En Pendientes sí: es la única forma de elegir el período del reporte.
  /// En Preliminar NO: esa pestaña ya tiene su propio Mes/Año arriba, y dos
  /// combos idénticos uno debajo del otro, con el mismo valor, no se entienden
  /// — quien mira no sabe cuál manda. Con esto la barra usa el período que le
  /// pasan y muestra solo Empresa y los botones.
  final bool periodoPropio;

  @override
  ConsumerState<BarraReportesPagadas> createState() =>
      _BarraReportesPagadasState();
}

class _BarraReportesPagadasState extends ConsumerState<BarraReportesPagadas> {
  late int _mes;
  late int _anio;
  EmpresaReporte _empresa = EmpresaReporte.impexpap;

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
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _mes = widget.mesInicial ?? hoy.month;
    _anio = widget.anioInicial ?? hoy.year;
  }

  @override
  void didUpdateWidget(BarraReportesPagadas anterior) {
    super.didUpdateWidget(anterior);
    // El preliminar cambia de período mientras la barra está montada; si no se
    // sigue, el botón bajaría el PDF de un mes distinto al que está en pantalla.
    if (widget.mesInicial != null && widget.mesInicial != anterior.mesInicial) {
      _mes = widget.mesInicial!;
    }
    if (widget.anioInicial != null &&
        widget.anioInicial != anterior.anioInicial) {
      _anio = widget.anioInicial!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(comisionesRepositoryProvider);
    final anioActual = DateTime.now().year;
    final soloPagadas = widget.alcance == AlcanceReportes.pagadas;

    return Padding(
      padding: EdgeInsets.fromLTRB(widget.padding, 12, widget.padding, 12),
      // Wrap y no Row: en un teléfono los tres selectores y los botones no
      // entran en una línea, y un Row los recortaría sin avisar.
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (widget.periodoPropio) ...[
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<int>(
                value: _mes,
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
                onChanged: (v) => setState(() => _mes = v ?? _mes),
              ),
            ),
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<int>(
                value: _anio,
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
                onChanged: (v) => setState(() => _anio = v ?? _anio),
              ),
            ),
          ],
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<EmpresaReporte>(
              value: _empresa,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Empresa',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final e in EmpresaReporte.values)
                  DropdownMenuItem(value: e, child: Text(e.etiqueta)),
              ],
              onChanged: (v) => setState(() => _empresa = v ?? _empresa),
            ),
          ),
          _BotonReporte(
            texto: 'Pagadas internas',
            alPulsar:
                () => _descargar(
                  () =>
                      _empresa == EmpresaReporte.esppapel
                          ? repo.reportePagadasEpp(mes: _mes, anio: _anio)
                          : repo.reportePagadasInternas(mes: _mes, anio: _anio),
                  'comisiones_internas_${_empresa.archivo}_${_mes}_$_anio.pdf',
                ),
          ),
          _BotonReporte(
            texto: 'Pagadas externas',
            // Esppapel no tiene vendedores externos: el SP no contempla esa
            // combinación. Se desactiva en vez de devolver un PDF vacío.
            deshabilitadoPorque:
                _empresa == EmpresaReporte.esppapel
                    ? 'Esppapel no tiene vendedores externos'
                    : null,
            alPulsar:
                () => _descargar(
                  () => repo.reportePagadasExternas(mes: _mes, anio: _anio),
                  'comisiones_externas_${_mes}_$_anio.pdf',
                ),
          ),
          if (!soloPagadas) ...[
            _BotonReporte(
              texto: 'Por importación',
              alPulsar:
                  () => _descargar(
                    () => repo.reporteImportaciones(mes: _mes, anio: _anio),
                    'comisiones_importacion_${_mes}_$_anio.pdf',
                  ),
            ),
            _BotonReporte(
              texto: 'Notas pendientes',
              alPulsar:
                  () => _descargar(
                    () => repo.reporteNotasPendientes(),
                    'notas_pendientes.pdf',
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _descargar(
    Future<Uint8List> Function() descarga,
    String nombre,
  ) async {
    await mostrarReportePdf(
      context: context,
      downloadFunction: descarga,
      filename: nombre,
    );
  }
}

class _BotonReporte extends StatelessWidget {
  const _BotonReporte({
    required this.texto,
    required this.alPulsar,
    this.deshabilitadoPorque,
  });

  final String texto;
  final VoidCallback alPulsar;

  /// Motivo por el que no se puede generar. Va como tooltip para que el botón
  /// apagado no quede sin explicación.
  final String? deshabilitadoPorque;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: deshabilitadoPorque ?? 'Generar $texto en PDF',
      child: OutlinedButton.icon(
        onPressed: deshabilitadoPorque == null ? alPulsar : null,
        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
        label: Text(texto),
      ),
    );
  }
}
