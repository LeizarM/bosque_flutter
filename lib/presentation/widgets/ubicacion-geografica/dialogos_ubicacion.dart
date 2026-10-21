/// Los diálogos de Ubicación geográfica: alta y edición de un país, una ciudad
/// (con su país) o una zona (con su ciudad), y sus bajas. Las reglas y los
/// textos los ponen `p_abm_Pais`, `p_abm_Ciudad` y `p_abm_Zona`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/ubicacion_geografica_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/pais_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';
import 'package:bosque_flutter/presentation/widgets/parametros/catalogo_parametros.dart';

Future<void> abrirFormularioPais(BuildContext context, {PaisEntity? existente}) =>
    _abrir(
      context,
      _FormularioUbicacion(
        titulo: existente == null ? 'Nuevo país' : 'Editar país',
        subtitulo:
            existente == null
                ? 'Se elige como nacionalidad y agrupa ciudades.'
                : 'Código ${existente.codPais} · ${existente.ciudades} ciudades.',
        etiquetaNombre: 'Nombre del país',
        nombreInicial: existente?.pais ?? '',
        guardar:
            (ref, nombre, _) => ref
                .read(ubicacionRepositoryProvider)
                .registrarPais(
                  PaisEntity(
                    codPais: existente?.codPais ?? 0,
                    pais: nombre,
                    audUsuario: 0,
                  ),
                ),
      ),
    );

Future<void> abrirFormularioCiudad(
  BuildContext context, {
  required List<PaisEntity> paises,
  CiudadEntity? existente,
  int? codPaisInicial,
}) => _abrir(
  context,
  _FormularioUbicacion(
    titulo: existente == null ? 'Nueva ciudad' : 'Editar ciudad',
    subtitulo:
        existente == null
            ? 'Agrupa zonas y la usan las sucursales.'
            : 'Código ${existente.codCiudad} · ${existente.zonas} zonas · '
                '${existente.sucursales} sucursales.',
    etiquetaNombre: 'Nombre de la ciudad',
    nombreInicial: existente?.ciudad ?? '',
    etiquetaPadre: 'País',
    padres: [for (final p in paises) (p.codPais, p.pais)],
    padreInicial: existente?.codPais ?? codPaisInicial,
    guardar:
        (ref, nombre, codPais) => ref
            .read(ubicacionRepositoryProvider)
            .registrarCiudad(
              CiudadEntity(
                codCiudad: existente?.codCiudad ?? 0,
                codPais: codPais ?? 0,
                ciudad: nombre,
                audUsuario: 0,
              ),
            ),
  ),
);

Future<void> abrirFormularioZona(
  BuildContext context, {
  required List<CiudadEntity> ciudades,
  ZonaEntity? existente,
  int? codCiudadInicial,
}) => _abrir(
  context,
  _FormularioUbicacion(
    titulo: existente == null ? 'Nueva zona' : 'Editar zona',
    subtitulo:
        existente == null
            ? 'Se elige en la dirección de las personas.'
            : 'Código ${existente.codZona} · la tienen ${existente.personas} personas.',
    etiquetaNombre: 'Nombre de la zona',
    nombreInicial: existente?.zona ?? '',
    etiquetaPadre: 'Ciudad',
    padres: [for (final c in ciudades) (c.codCiudad, '${c.ciudad} · ${c.pais}')],
    padreInicial: existente?.codCiudad ?? codCiudadInicial,
    guardar:
        (ref, nombre, codCiudad) => ref
            .read(ubicacionRepositoryProvider)
            .registrarZona(
              ZonaEntity(
                codZona: existente?.codZona ?? 0,
                codCiudad: codCiudad ?? 0,
                zona: nombre,
                audUsuario: 0,
              ),
            ),
  ),
);

Future<void> _abrir(BuildContext context, Widget formulario) {
  ProviderScope.containerOf(
    context,
  ).read(operacionesUbicacionProvider.notifier).limpiarError();
  return abrirFormularioParametro<void>(context, contenido: (_) => formulario);
}

typedef _Guardar =
    Future<ResultadoEscrituraEntity> Function(
      WidgetRef ref,
      String nombre,
      int? codPadre,
    );

/// Un nombre y, si hay [padres], el combo del nivel de arriba.
class _FormularioUbicacion extends ConsumerStatefulWidget {
  const _FormularioUbicacion({
    required this.titulo,
    required this.subtitulo,
    required this.etiquetaNombre,
    required this.nombreInicial,
    required this.guardar,
    this.etiquetaPadre,
    this.padres,
    this.padreInicial,
  });

  final String titulo;
  final String subtitulo;
  final String etiquetaNombre;
  final String nombreInicial;
  final _Guardar guardar;
  final String? etiquetaPadre;
  final List<(int, String)>? padres;
  final int? padreInicial;

  @override
  ConsumerState<_FormularioUbicacion> createState() =>
      _FormularioUbicacionState();
}

class _FormularioUbicacionState extends ConsumerState<_FormularioUbicacion> {
  late final _nombre = TextEditingController(text: widget.nombreInicial);
  late int? _padre =
      (widget.padres ?? const []).any((p) => p.$1 == widget.padreInicial)
          ? widget.padreInicial
          : null;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final r = await ref
        .read(operacionesUbicacionProvider.notifier)
        .ejecutar(() => widget.guardar(ref, _nombre.text, _padre));
    if (r == null || !mounted) return;
    avisar(context, r.mensaje);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(operacionesUbicacionProvider);
    final padres = widget.padres;

    return PanelParametro(
      titulo: widget.titulo,
      subtitulo: widget.subtitulo,
      ocupado: estado.ocupado,
      errorServidor: estado.error,
      etiquetaGuardar: widget.nombreInicial.isEmpty ? 'Registrar' : 'Guardar cambios',
      onGuardar: _guardar,
      campos: [
        if (padres != null)
          DropdownButtonFormField<int>(
            key: const ValueKey('campo-padre'),
            value: _padre,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: widget.etiquetaPadre,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final (cod, texto) in padres)
                DropdownMenuItem(
                  value: cod,
                  child: Text(texto, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _padre = v),
          ),
        TextField(
          key: const ValueKey('campo-nombre'),
          controller: _nombre,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          textInputAction: TextInputAction.done,
          onSubmitted: estado.ocupado ? null : (_) => _guardar(),
          decoration: InputDecoration(
            labelText: widget.etiquetaNombre,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BAJAS
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _eliminar(
  BuildContext context,
  WidgetRef ref, {
  required String que,
  required String nombre,
  required String detalle,
  required Future<ResultadoEscrituraEntity> Function() eliminar,
}) => eliminarDeCatalogo(
  context,
  titulo: '¿Eliminar $que $nombre?',
  detalle: detalle,
  textoConfirmar: 'Eliminar',
  operaciones: ref.read(operacionesUbicacionProvider.notifier),
  errorActual: () => ref.read(operacionesUbicacionProvider).error,
  eliminar: eliminar,
);

Future<void> eliminarPais(BuildContext context, WidgetRef ref, PaisEntity p) =>
    _eliminar(
      context,
      ref,
      que: 'el país',
      nombre: p.pais,
      detalle:
          'Se elimina «${p.pais}». Si tiene ciudades o es la nacionalidad de '
          'alguien, no se podrá eliminar.',
      eliminar: () => ref.read(ubicacionRepositoryProvider).eliminarPais(p.codPais),
    );

Future<void> eliminarCiudad(
  BuildContext context,
  WidgetRef ref,
  CiudadEntity c,
) => _eliminar(
  context,
  ref,
  que: 'la ciudad',
  nombre: c.ciudad,
  detalle:
      'Se elimina «${c.ciudad}» (${c.pais}). Si tiene zonas o sucursales, no '
      'se podrá eliminar.',
  eliminar:
      () => ref.read(ubicacionRepositoryProvider).eliminarCiudad(c.codCiudad),
);

Future<void> eliminarZona(BuildContext context, WidgetRef ref, ZonaEntity z) =>
    _eliminar(
      context,
      ref,
      que: 'la zona',
      nombre: z.zona,
      detalle:
          'Se elimina «${z.zona}» (${z.ciudad}). Si alguna persona la tiene en '
          'su dirección, no se podrá eliminar.',
      eliminar: () => ref.read(ubicacionRepositoryProvider).eliminarZona(z.codZona),
    );
