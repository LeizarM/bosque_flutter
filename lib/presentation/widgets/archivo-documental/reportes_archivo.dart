/// Los reportes del archivo (jrxml en el backend): se elige cuál, se acota con
/// filtros que arrancan con los de la pantalla y el PDF se ve antes de
/// imprimirlo o compartirlo (`mostrarPdf`, igual en web y teléfono).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/domain/entities/archivo_fisico_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_documento_archivo_entity.dart';
import 'package:bosque_flutter/domain/repositories/archivo_documental_repository.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';

class ReportesArchivo extends StatefulWidget {
  const ReportesArchivo({
    super.key,
    required this.archivos,
    required this.tipos,
    required this.empresas,
    required this.generar,
    required this.ver,
    this.filtroInicial = const FiltroArchivo(),
    this.mostrarAsa = true,
  });

  final List<ArchivoFisicoEntity> archivos;
  final List<TipoDocumentoArchivoEntity> tipos;
  final List<EmpresaEntity> empresas;
  final Future<Uint8List> Function(PedidoReporteArchivo pedido) generar;

  /// `mostrarPdf` en la app; las pruebas lo reemplazan.
  final VerPdf ver;

  /// Los filtros de la pantalla: el reporte arranca acotado igual.
  final FiltroArchivo filtroInicial;
  final bool mostrarAsa;

  @override
  State<ReportesArchivo> createState() => _ReportesArchivoState();
}

class _ReportesArchivoState extends State<ReportesArchivo> {
  ReporteArchivo _reporte = ReporteArchivo.porSucursal;
  int? _sucursal;
  int? _tipo;
  int? _empresa;
  late final TextEditingController _desde;
  late final TextEditingController _hasta;
  bool _generando = false;
  String? _error;

  /// Las sucursales que tienen algún archivo: filtrar por otra daría vacío.
  late final List<(int, String)> _sucursales = () {
    final vistas = <int, String>{};
    for (final a in widget.archivos) {
      final cod = a.codSucursal;
      if (cod != null) vistas[cod] = a.nombreSucursal ?? 'Sucursal $cod';
    }
    return [for (final e in vistas.entries) (e.key, e.value)]..sort((a, b) => a.$2.compareTo(b.$2));
  }();

  @override
  void initState() {
    super.initState();
    final f = widget.filtroInicial;
    _tipo = f.codTipoDocumento;
    _empresa = f.codEmpresa;
    for (final a in widget.archivos) {
      if (a.codArchivo == f.codArchivo) _sucursal = a.codSucursal;
    }
    _desde = TextEditingController(text: f.anio?.toString() ?? '');
    _hasta = TextEditingController(text: f.anio?.toString() ?? '');
  }

  @override
  void dispose() {
    _desde.dispose();
    _hasta.dispose();
    super.dispose();
  }

  String? _validarAnios() {
    final d = _desde.text.trim();
    final h = _hasta.text.trim();
    final desde = int.tryParse(d);
    final hasta = int.tryParse(h);
    if ((d.isNotEmpty && (d.length != 4 || desde == null)) || (h.isNotEmpty && (h.length != 4 || hasta == null))) {
      return 'Escribe los años con cuatro cifras, por ejemplo 2015.';
    }
    if (desde != null && hasta != null && desde > hasta) {
      return 'El año «desde» no puede ser mayor que el año «hasta».';
    }
    return null;
  }

  Future<void> _generarPdf() async {
    final malo = _validarAnios();
    if (malo != null) {
      setState(() => _error = malo);
      return;
    }
    setState(() {
      _generando = true;
      _error = null;
    });
    final pedido = PedidoReporteArchivo(
      reporte: _reporte,
      codSucursal: _sucursal,
      codTipoDocumento: _tipo,
      codEmpresa: _empresa,
      anioDesde: int.tryParse(_desde.text.trim()),
      anioHasta: int.tryParse(_hasta.text.trim()),
    );
    try {
      final bytes = await widget.generar(pedido);
      if (!mounted) return;
      setState(() => _generando = false);
      await widget.ver(
        context,
        bytes: bytes,
        titulo: _reporte.titulo,
        nombreArchivo: _nombreArchivo(_reporte),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generando = false;
        _error = humanizar(e).texto;
      });
    }
  }

  static String _nombreArchivo(ReporteArchivo r) {
    final hoy = DateTime.now();
    String dos(int n) => n.toString().padLeft(2, '0');
    final clave = switch (r) {
      ReporteArchivo.porSucursal => 'por-sucursal',
      ReporteArchivo.porTipo => 'por-tipo',
      ReporteArchivo.detalle => 'detalle',
    };
    return 'archivo-documentos-$clave-${hoy.year}-${dos(hoy.month)}-${dos(hoy.day)}.pdf';
  }

  @override
  Widget build(BuildContext context) {
    final tipos = [...widget.tipos]
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    return PopScope(
      canPop: !_generando,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: widget.mostrarAsa ? MediaQuery.viewInsetsOf(context).bottom : 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CabezaFicha(
              titulo: 'Reportes del archivo',
              mostrarAsa: widget.mostrarAsa,
              ocupado: _generando,
              icono: Icons.assessment_outlined,
              semilla: TonosArchivo.reportes,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Esp.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Esp.m),
                        child: NotaDelDato(texto: _error!, tono: TonoNota.error),
                      ),
                    Text('Qué quieres ver', style: context.tituloSeccion()),
                    const SizedBox(height: Esp.s),
                    for (final r in ReporteArchivo.values) ...[
                      _OpcionReporte(
                        reporte: r,
                        elegido: _reporte == r,
                        onTap: _generando ? null : () => setState(() => _reporte = r),
                      ),
                      const SizedBox(height: Esp.s),
                    ],
                    const SizedBox(height: Esp.m),
                    Text('Filtros (opcionales)', style: context.tituloSeccion()),
                    const SizedBox(height: Esp.m),
                    DropdownButtonFormField<int?>(
                      value: _sucursales.any((s) => s.$1 == _sucursal) ? _sucursal : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sucursal',
                        prefixIcon: Icon(Icons.store_mall_directory_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
                        for (final (cod, nombre) in _sucursales)
                          DropdownMenuItem<int?>(value: cod, child: Text(nombre)),
                      ],
                      onChanged: _generando ? null : (v) => setState(() => _sucursal = v),
                    ),
                    const SizedBox(height: Esp.l),
                    ComboBuscable<int?>(
                      etiqueta: 'Tipo de documento',
                      valor: _tipo,
                      opciones: [
                        const DropdownMenuEntry<int?>(value: null, label: 'Todos'),
                        for (final t in tipos)
                          DropdownMenuEntry<int?>(value: t.codTipoDocumento, label: t.nombre),
                      ],
                      onElegir: (v) => setState(() => _tipo = v),
                    ),
                    const SizedBox(height: Esp.l),
                    DropdownButtonFormField<int?>(
                      value:
                          _empresa == sinEmpresa || widget.empresas.any((e) => e.codEmpresa == _empresa)
                              ? _empresa
                              : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Empresa',
                        prefixIcon: Icon(Icons.business_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
                        const DropdownMenuItem<int?>(value: sinEmpresa, child: Text('Sin empresa (otros)')),
                        for (final e in widget.empresas)
                          DropdownMenuItem<int?>(value: e.codEmpresa, child: Text(e.nombre)),
                      ],
                      onChanged: _generando ? null : (v) => setState(() => _empresa = v),
                    ),
                    const SizedBox(height: Esp.l),
                    Row(
                      children: [
                        Expanded(child: _campoAnio(_desde, 'Gestión desde')),
                        const SizedBox(width: Esp.l),
                        Expanded(child: _campoAnio(_hasta, 'Gestión hasta')),
                      ],
                    ),
                    const SizedBox(height: Esp.xs),
                    Text(
                      'Un documento entra si su gestión se cruza con esos años.',
                      style: context.apagado(),
                    ),
                  ],
                ),
              ),
            ),
            PieFicha(
              etiqueta: _generando ? 'Generando…' : 'Ver PDF',
              ocupado: _generando,
              onGuardar: _generarPdf,
              semilla: TonosArchivo.reportes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoAnio(TextEditingController c, String rotulo) => TextField(
    controller: c,
    enabled: !_generando,
    keyboardType: TextInputType.number,
    maxLength: 4,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: rotulo,
      hintText: 'Ej. 2015',
      prefixIcon: const Icon(Icons.event_outlined),
      border: const OutlineInputBorder(),
      counterText: '',
    ),
  );
}

class _OpcionReporte extends StatelessWidget {
  const _OpcionReporte({required this.reporte, required this.elegido, required this.onTap});

  final ReporteArchivo reporte;
  final bool elegido;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icono, semilla, detalle) = switch (reporte) {
      ReporteArchivo.porSucursal => (
        Icons.warehouse_outlined,
        TonosArchivo.archivos[0],
        'Qué tipos de documento hay en cada sucursal, cuántos y en qué cajas.',
      ),
      ReporteArchivo.porTipo => (
        Icons.manage_search_outlined,
        TonosArchivo.archivos[2],
        'Para cada tipo (por ejemplo Facturas): en qué sucursal y en qué cajas está.',
      ),
      ReporteArchivo.detalle => (
        Icons.list_alt_outlined,
        TonosArchivo.documentos,
        'Cada documento con su caja y su ubicación, caja por caja, para imprimir.',
      ),
    };
    final t = tonoDe(context, semilla);
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      selected: elegido,
      button: true,
      child: Material(
        color: elegido ? t.fondo.withValues(alpha: 0.55) : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Esquina.media),
          side: BorderSide(color: elegido ? t.fuerte : cs.outlineVariant, width: elegido ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Esp.m),
            child: Row(
              children: [
                IconoTono(icono, semilla, lado: 40),
                const SizedBox(width: Esp.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reporte.titulo,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: Peso.dato),
                      ),
                      Text(detalle, style: context.apagado()),
                    ],
                  ),
                ),
                Icon(
                  elegido ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: elegido ? t.fuerte : cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
