/// Los diálogos del ABM de empresas y sucursales: alta y edición de una
/// empresa (nombre y empresa padre) o de una sucursal (nombre, empresa y
/// ciudad), y sus bajas. Reglas y textos los ponen `p_abm_Empresa` y
/// `p_abm_Sucursal`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/empresas_sucursales_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/presentation/widgets/parametros/catalogo_parametros.dart';

Future<void> abrirFormularioEmpresa(
  BuildContext context, {
  required List<EmpresaEntity> empresas,
  EmpresaEntity? existente,
}) => _abrir(
  context,
  _Formulario(
    titulo: existente == null ? 'Nueva empresa' : 'Editar empresa',
    subtitulo:
        existente == null
            ? 'Agrupa sucursales y cargos.'
            : 'Código ${existente.codEmpresa} · ${existente.sucursales} sucursales · ${existente.cargos} cargos.',
    nombreInicial: existente?.nombre ?? '',
    largo: 30,
    combos: [
      _Combo(
        etiqueta: 'Empresa padre',
        inicial: existente?.codPadre ?? 0,
        opciones: [
          (0, 'Sin empresa padre'),
          for (final e in empresas)
            if (e.codEmpresa != existente?.codEmpresa) (e.codEmpresa, e.nombre),
        ],
      ),
    ],
    guardar:
        (ref, nombre, v) => ref
            .read(empresasSucursalesRepositoryProvider)
            .registrarEmpresa(
              EmpresaEntity(
                codEmpresa: existente?.codEmpresa ?? 0,
                nombre: nombre,
                codPadre: v[0] ?? 0,
                sigla: existente?.sigla ?? '',
                audUsuario: 0,
              ),
            ),
  ),
);

Future<void> abrirFormularioSucursal(
  BuildContext context, {
  required List<EmpresaEntity> empresas,
  required List<CiudadEntity> ciudades,
  SucursalEntity? existente,
  int? codEmpresaInicial,
}) => _abrir(
  context,
  _Formulario(
    titulo: existente == null ? 'Nueva sucursal' : 'Editar sucursal',
    subtitulo:
        existente == null
            ? 'Una oficina, almacén o planta de una empresa.'
            : 'Código ${existente.codSucursal} · ${existente.cargos} cargos asignados.',
    nombreInicial: existente?.nombre ?? '',
    largo: 100,
    mayusculas: false,
    combos: [
      _Combo(
        etiqueta: 'Empresa',
        inicial: existente?.codEmpresa ?? codEmpresaInicial,
        opciones: [for (final e in empresas) (e.codEmpresa, e.nombre)],
      ),
      _Combo(
        etiqueta: 'Ciudad',
        inicial: existente?.codCiudad,
        opciones: [
          for (final c in ciudades) (c.codCiudad, '${c.ciudad} · ${c.pais}'),
        ],
      ),
    ],
    guardar:
        (ref, nombre, v) => ref
            .read(empresasSucursalesRepositoryProvider)
            .registrarSucursal(
              SucursalEntity(
                codSucursal: existente?.codSucursal ?? 0,
                nombre: nombre,
                codEmpresa: v[0] ?? 0,
                codCiudad: v[1] ?? 0,
                audUsuarioI: 0,
                empresa: EmpresaEntity(
                  codEmpresa: 0,
                  nombre: '',
                  codPadre: 0,
                  sigla: '',
                  audUsuario: 0,
                ),
                nombreCiudad: '',
                codSucursalPlanilla: 0,
                nombrePlanilla: '',
              ),
            ),
  ),
);

Future<void> _abrir(BuildContext context, Widget formulario) {
  ProviderScope.containerOf(
    context,
  ).read(operacionesEmpresasSucursalesProvider.notifier).limpiarError();
  return abrirFormularioParametro<void>(context, contenido: (_) => formulario);
}

class _Combo {
  const _Combo({
    required this.etiqueta,
    required this.inicial,
    required this.opciones,
  });

  final String etiqueta;
  final int? inicial;
  final List<(int, String)> opciones;
}

typedef _Guardar =
    Future<ResultadoEscrituraEntity> Function(
      WidgetRef ref,
      String nombre,
      List<int?> valores,
    );

/// Un nombre y los combos que necesite el registro.
class _Formulario extends ConsumerStatefulWidget {
  const _Formulario({
    required this.titulo,
    required this.subtitulo,
    required this.nombreInicial,
    required this.largo,
    required this.combos,
    required this.guardar,
    this.mayusculas = true,
  });

  final String titulo;
  final String subtitulo;
  final String nombreInicial;
  final int largo;
  final List<_Combo> combos;
  final _Guardar guardar;
  final bool mayusculas;

  @override
  ConsumerState<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends ConsumerState<_Formulario> {
  late final _nombre = TextEditingController(text: widget.nombreInicial);
  late final List<int?> _valores = [
    for (final c in widget.combos)
      c.opciones.any((o) => o.$1 == c.inicial) ? c.inicial : null,
  ];

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final r = await ref
        .read(operacionesEmpresasSucursalesProvider.notifier)
        .ejecutar(() => widget.guardar(ref, _nombre.text, _valores));
    if (r == null || !mounted) return;
    avisar(context, r.mensaje);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(operacionesEmpresasSucursalesProvider);
    return PanelParametro(
      titulo: widget.titulo,
      subtitulo: widget.subtitulo,
      ocupado: estado.ocupado,
      errorServidor: estado.error,
      etiquetaGuardar:
          widget.nombreInicial.isEmpty ? 'Registrar' : 'Guardar cambios',
      onGuardar: _guardar,
      campos: [
        TextField(
          key: const ValueKey('campo-nombre'),
          controller: _nombre,
          autofocus: true,
          textCapitalization:
              widget.mayusculas
                  ? TextCapitalization.characters
                  : TextCapitalization.words,
          inputFormatters: [LengthLimitingTextInputFormatter(widget.largo)],
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
        ),
        for (var i = 0; i < widget.combos.length; i++)
          DropdownButtonFormField<int>(
            key: ValueKey('campo-combo-$i'),
            value: _valores[i],
            isExpanded: true,
            decoration: InputDecoration(
              labelText: widget.combos[i].etiqueta,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final (cod, texto) in widget.combos[i].opciones)
                DropdownMenuItem(
                  value: cod,
                  child: Text(texto, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _valores[i] = v),
          ),
      ],
    );
  }
}

Future<void> _eliminar(
  BuildContext context,
  WidgetRef ref, {
  required String titulo,
  required String detalle,
  required Future<ResultadoEscrituraEntity> Function() eliminar,
}) => eliminarDeCatalogo(
  context,
  titulo: titulo,
  detalle: detalle,
  textoConfirmar: 'Eliminar',
  operaciones: ref.read(operacionesEmpresasSucursalesProvider.notifier),
  errorActual: () => ref.read(operacionesEmpresasSucursalesProvider).error,
  eliminar: eliminar,
);

Future<void> eliminarEmpresa(
  BuildContext context,
  WidgetRef ref,
  EmpresaEntity e,
) => _eliminar(
  context,
  ref,
  titulo: '¿Eliminar la empresa ${e.nombre}?',
  detalle:
      'Se elimina «${e.nombre}». Si tiene sucursales, cargos o empresas que '
      'dependen de ella, no se podrá eliminar.',
  eliminar:
      () => ref
          .read(empresasSucursalesRepositoryProvider)
          .eliminarEmpresa(e.codEmpresa),
);

Future<void> eliminarSucursal(
  BuildContext context,
  WidgetRef ref,
  SucursalEntity s,
) => _eliminar(
  context,
  ref,
  titulo: '¿Eliminar la sucursal ${s.nombre}?',
  detalle:
      'Se elimina «${s.nombre}» (${s.nombreEmpresa}). Si tiene cargos o la usan '
      'otros módulos, no se podrá eliminar.',
  eliminar:
      () => ref
          .read(empresasSucursalesRepositoryProvider)
          .eliminarSucursal(s.codSucursal),
);
