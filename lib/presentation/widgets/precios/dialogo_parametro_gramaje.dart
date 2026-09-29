import 'package:flutter/material.dart';

import 'package:bosque_flutter/presentation/widgets/precios/ancho_dialogo.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/grupo_fam_tipo_rango_gram_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_familia_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/rango_gramaje_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_producto_entity.dart';

/// Lo que devuelve [DialogoParametroGramaje] al aceptar: solo los tres ids; el
/// usuario de auditoría y la fecha los pone la pantalla, que tiene el repositorio.
@immutable
class ResultadoParametroGramaje {
  const ResultadoParametroGramaje({
    required this.idGrpFamiliaSap,
    required this.idTipo,
    required this.idRangoGram,
  });

  final int idGrpFamiliaSap;
  final int idTipo;
  final int idRangoGram;
}

/// Alta y modificación de una asignación grupo de familia + tipo -> rango de
/// gramaje (tpr_grupoFamTipoRangoGram).
///
/// La tabla es un heap (sin PK ni IDENTITY): el par (grupo, tipo) ES la clave. Al
/// MODIFICAR ambos quedan deshabilitados (cambiarlos apuntaría a otra fila y sin
/// unique el backend crearía un duplicado); al CREAR se valida contra
/// [clavesOcupadas]. Solo el rango de gramaje es editable.
class DialogoParametroGramaje extends StatefulWidget {
  const DialogoParametroGramaje({
    super.key,
    required this.grupos,
    required this.tipos,
    required this.rangos,
    this.inicial,
    this.clavesOcupadas = const <String>{},
  });

  /// Catalogo de grupos de familia SAP, para el combo del alta.
  final List<GrupoFamiliaSapEntity> grupos;

  /// Catalogo de tipos de papel.
  final List<TipoProductoEntity> tipos;

  /// Catalogo de rangos de gramaje: el unico campo editable.
  final List<RangoGramajeEntity> rangos;

  /// La fila que se edita. Null para un alta.
  final GrupoFamTipoRangoGramEntity? inicial;

  /// Claves naturales ya cargadas ("grupo-tipo"), para no duplicar un par en
  /// una tabla que no tiene unique que lo impida.
  final Set<String> clavesOcupadas;

  @override
  State<DialogoParametroGramaje> createState() =>
      _DialogoParametroGramajeState();
}

class _DialogoParametroGramajeState extends State<DialogoParametroGramaje> {
  int? _idGrupo;
  int? _idTipo;
  int? _idRango;
  String? _errorClave;
  String? _errorRango;

  bool get _esEdicion => widget.inicial != null;

  @override
  void initState() {
    super.initState();
    final inicial = widget.inicial;
    if (inicial != null) {
      _idGrupo = inicial.idGrpFamiliaSap;
      _idTipo = inicial.idTipo;
      // Solo se preselecciona si el rango sigue en el catálogo: un Dropdown con un valor
      // fuera de sus opciones revienta en un assert y hay filas con rangos dados de baja.
      final vive = widget.rangos.any(
        (r) => r.idRangoGram.toInt() == inicial.idRangoGram,
      );
      _idRango = vive ? inicial.idRangoGram : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        _esEdicion ? Icons.edit_outlined : Icons.add_circle_outline,
        color: context.cs.primary,
      ),
      title: Text(
        _esEdicion
            ? 'Editar parámetro de gramaje'
            : 'Nuevo parámetro de gramaje',
      ),
      insetPadding: const EdgeInsets.all(Esp.l),
      content: SingleChildScrollView(
        child: SizedBox(
          width: anchoDialogo(context, 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_esEdicion) ...[
                _claveBloqueada(
                  etiqueta: 'Grupo de familia',
                  valor: _nombreGrupo(_idGrupo),
                ),
                const SizedBox(height: Esp.m),
                _claveBloqueada(
                  etiqueta: 'Tipo de papel',
                  valor: _nombreTipo(_idTipo),
                ),
                const NotaDelDato(
                  texto:
                      'El grupo y el tipo son la clave de la fila: no se pueden '
                      'cambiar. Para asignar otro par, elimine este parámetro y '
                      'cree uno nuevo.',
                ),
              ] else ...[
                ComboBuscable<int>(
                  etiqueta: 'Grupo de familia',
                  valor: _idGrupo,
                  ayuda: 'Parte 1 de la clave',
                  opciones: [
                    for (final g in _gruposOrdenados)
                      DropdownMenuEntry<int>(
                        value: g.idGrpFamiliaSap.toInt(),
                        label: g.nombreVisible,
                        labelWidget: Text(
                          g.nombreVisible,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onElegir:
                      (valor) => setState(() {
                        _idGrupo = valor;
                        _errorClave = null;
                      }),
                ),
                const SizedBox(height: Esp.m),
                DropdownButtonFormField<int>(
                  value: _idTipo,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de papel',
                    helperText: 'Parte 2 de la clave',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final t in _tiposOrdenados)
                      DropdownMenuItem<int>(
                        value: t.idTipo.toInt(),
                        child: Text(
                          t.esActivo
                              ? t.nombreLegible
                              : '${t.nombreLegible} (inactivo)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged:
                      (valor) => setState(() {
                        _idTipo = valor;
                        _errorClave = null;
                      }),
                ),
                if (_errorClave != null)
                  NotaDelDato(tono: TonoNota.error, texto: _errorClave!),
              ],
              const Divider(height: Esp.xl),
              DropdownButtonFormField<int>(
                value: _idRango,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Rango de gramaje',
                  helperText: 'Es el único dato editable de la fila',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final r in _rangosOrdenados)
                    DropdownMenuItem<int>(
                      value: r.idRangoGram.toInt(),
                      child: Text(
                        r.rangoLegible,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged:
                    (valor) => setState(() {
                      _idRango = valor;
                      _errorRango = null;
                    }),
              ),
              if (_errorRango != null)
                NotaDelDato(tono: TonoNota.error, texto: _errorRango!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _aceptar,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  /// Campo de la clave natural, visible pero deshabilitado. Es un
  /// [TextFormField] apagado y no un combo: si el grupo o el tipo se dieron de
  /// baja del catálogo, un Dropdown con un valor fuera de sus opciones revienta
  /// en un assert y la fila vieja dejaría de ser editable.
  Widget _claveBloqueada({required String etiqueta, required String valor}) =>
      TextFormField(
        key: ValueKey('clave-$etiqueta-$valor'),
        initialValue: valor,
        enabled: false,
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: const Icon(Icons.lock_outline),
          border: const OutlineInputBorder(),
        ),
      );

  List<GrupoFamiliaSapEntity> get _gruposOrdenados =>
      List<GrupoFamiliaSapEntity>.of(widget.grupos)
        ..sort((a, b) => a.nombreVisible.compareTo(b.nombreVisible));

  List<TipoProductoEntity> get _tiposOrdenados =>
      List<TipoProductoEntity>.of(widget.tipos)
        ..sort((a, b) => a.nombreLegible.compareTo(b.nombreLegible));

  /// Ordenados por limite inferior: "70 a 90" antes que "90 a 120", que es como
  /// el usuario los tiene en la cabeza.
  List<RangoGramajeEntity> get _rangosOrdenados =>
      List<RangoGramajeEntity>.of(widget.rangos)
        ..sort((a, b) => a.min.compareTo(b.min));

  String _nombreGrupo(int? id) {
    for (final g in widget.grupos) {
      if (g.idGrpFamiliaSap.toInt() == id) return g.nombreVisible;
    }
    return id == null ? '-' : 'Grupo $id (fuera del catálogo)';
  }

  String _nombreTipo(int? id) {
    for (final t in widget.tipos) {
      if (t.idTipo.toInt() == id) return t.nombreLegible;
    }
    return id == null ? '-' : 'Tipo $id (fuera del catálogo)';
  }

  void _aceptar() {
    final grupo = _idGrupo;
    final tipo = _idTipo;
    final rango = _idRango;

    setState(() {
      _errorClave =
          (grupo == null || tipo == null)
              ? 'Elija el grupo de familia y el tipo de papel.'
              : (!_esEdicion && widget.clavesOcupadas.contains('$grupo-$tipo'))
              ? 'Ese grupo ya tiene un rango asignado para ese tipo. '
                  'Edite el parámetro existente.'
              : null;
      _errorRango = rango == null ? 'Elija el rango de gramaje.' : null;
    });

    if (_errorClave != null || _errorRango != null) return;

    Navigator.pop(
      context,
      ResultadoParametroGramaje(
        idGrpFamiliaSap: grupo!,
        idTipo: tipo!,
        idRangoGram: rango!,
      ),
    );
  }
}
