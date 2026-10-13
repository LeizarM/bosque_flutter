/// Los filtros del archivo. En escritorio van a la vista; en teléfono el
/// buscador queda afuera y el resto en un panel plegable que cuenta cuántos
/// criterios hay puestos (un filtro olvidado explicaría una lista vacía). El
/// archivo se elige con los chips de color de arriba, no aquí.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_documento_archivo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';

class FiltrosArchivo extends StatefulWidget {
  const FiltrosArchivo({
    super.key,
    required this.filtro,
    required this.onFiltro,
    required this.tipos,
    required this.empresas,
    required this.compacto,
  });

  final FiltroArchivo filtro;
  final ValueChanged<FiltroArchivo> onFiltro;
  final List<TipoDocumentoArchivoEntity> tipos;
  final List<EmpresaEntity> empresas;
  final bool compacto;

  @override
  State<FiltrosArchivo> createState() => _FiltrosArchivoState();
}

class _FiltrosArchivoState extends State<FiltrosArchivo> {
  late final TextEditingController _texto;
  late final TextEditingController _numero;
  late final TextEditingController _anio;

  @override
  void initState() {
    super.initState();
    _texto = TextEditingController(text: widget.filtro.texto);
    _numero = TextEditingController(text: widget.filtro.numeroCaja?.toString() ?? '');
    _anio = TextEditingController(text: widget.filtro.anio?.toString() ?? '');
  }

  @override
  void dispose() {
    _texto.dispose();
    _numero.dispose();
    _anio.dispose();
    super.dispose();
  }

  FiltroArchivo get _f => widget.filtro;

  /// Limpia lo de este panel; el archivo elegido en los chips se conserva.
  void _limpiar() {
    _texto.clear();
    _numero.clear();
    _anio.clear();
    widget.onFiltro(FiltroArchivo(codArchivo: _f.codArchivo));
  }

  bool get _hayAlgoAqui => _f.texto.trim().isNotEmpty || _puestos > 0;

  /// Los criterios de este panel (el archivo va en los chips).
  int get _puestos => _f.criterios - (_f.codArchivo == null ? 0 : 1);

  @override
  Widget build(BuildContext context) =>
      widget.compacto ? _movil(context) : _escritorio();

  Widget _escritorio() => Wrap(
    spacing: Esp.m,
    runSpacing: Esp.m,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(width: 340, child: _buscador()),
      SizedBox(width: 230, child: _comboTipo()),
      SizedBox(width: 210, child: _comboEmpresa()),
      SizedBox(width: 110, child: _campoNumero()),
      SizedBox(width: 100, child: _campoAnio()),
      if (_hayAlgoAqui)
        TextButton.icon(
          onPressed: _limpiar,
          icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
          label: const Text('Limpiar filtros'),
        ),
    ],
  );

  Widget _movil(BuildContext context) {
    final puestos = _puestos;
    final t = tonoDe(context, TonosArchivo.gestion);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buscador(),
        const SizedBox(height: Esp.s),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            initiallyExpanded: puestos > 0,
            tilePadding: const EdgeInsets.symmetric(horizontal: Esp.m),
            childrenPadding: const EdgeInsets.fromLTRB(Esp.m, 0, Esp.m, Esp.m),
            leading: const IconoTono(Icons.tune, TonosArchivo.gestion, lado: 32),
            title: Text('Filtros', style: Theme.of(context).textTheme.titleSmall),
            subtitle:
                puestos == 0
                    ? null
                    : Text(
                      puestos == 1 ? '1 criterio aplicado' : '$puestos criterios aplicados',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: t.fuerte,
                        fontWeight: Peso.titulo,
                      ),
                    ),
            children: [
              _comboTipo(),
              const SizedBox(height: Esp.m),
              _comboEmpresa(),
              const SizedBox(height: Esp.m),
              Row(
                children: [
                  Expanded(child: _campoNumero()),
                  const SizedBox(width: Esp.m),
                  Expanded(child: _campoAnio()),
                ],
              ),
              const SizedBox(height: Esp.s),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _hayAlgoAqui ? _limpiar : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Limpiar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buscador() => TextField(
    controller: _texto,
    textInputAction: TextInputAction.search,
    onChanged: (t) => widget.onFiltro(_f.copyWith(texto: t)),
    decoration: InputDecoration(
      border: const OutlineInputBorder(),
      prefixIcon: Icon(Icons.search, size: 20, color: tonoDe(context, TonosArchivo.documentos).fuerte),
      hintText: 'Buscar documento: facturas 2016, comex, papirus…',
      suffixIcon:
          _f.texto.isEmpty
              ? null
              : IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Borrar la búsqueda',
                onPressed: () {
                  _texto.clear();
                  widget.onFiltro(_f.copyWith(texto: ''));
                },
              ),
    ),
  );

  Widget _comboTipo() {
    final tipos = [...widget.tipos]
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return ComboBuscable<int?>(
      etiqueta: 'Tipo de documento',
      valor: _f.codTipoDocumento,
      opciones: [
        const DropdownMenuEntry<int?>(value: null, label: 'Todos'),
        for (final t in tipos)
          DropdownMenuEntry<int?>(value: t.codTipoDocumento, label: t.nombre),
      ],
      onElegir:
          (v) => widget.onFiltro(
            v == null ? _f.copyWith(limpiarTipo: true) : _f.copyWith(codTipoDocumento: v),
          ),
    );
  }

  Widget _comboEmpresa() => ComboBuscable<int?>(
    etiqueta: 'Empresa',
    valor: _f.codEmpresa,
    opciones: [
      const DropdownMenuEntry<int?>(value: null, label: 'Todas'),
      const DropdownMenuEntry<int?>(value: sinEmpresa, label: 'Sin empresa (otros)'),
      for (final e in widget.empresas)
        DropdownMenuEntry<int?>(value: e.codEmpresa, label: e.nombre),
    ],
    onElegir:
        (v) => widget.onFiltro(
          v == null ? _f.copyWith(limpiarEmpresa: true) : _f.copyWith(codEmpresa: v),
        ),
  );

  Widget _campoNumero() => TextField(
    controller: _numero,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onChanged: (t) {
      final n = int.tryParse(t);
      widget.onFiltro(n == null ? _f.copyWith(limpiarNumero: true) : _f.copyWith(numeroCaja: n));
    },
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Caja N°',
    ),
  );

  Widget _campoAnio() => TextField(
    controller: _anio,
    keyboardType: TextInputType.number,
    maxLength: 4,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onChanged: (t) {
      // Solo un año completo filtra: con «20» a medio escribir no queda nada.
      final n = t.length == 4 ? int.tryParse(t) : null;
      widget.onFiltro(n == null ? _f.copyWith(limpiarAnio: true) : _f.copyWith(anio: n));
    },
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Año',
      counterText: '',
    ),
  );
}
