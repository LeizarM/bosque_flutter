/// Los avisos de la vista previa de una planilla (SP W), agrupados por tipo:
/// lo provisional primero, luego lo que queda fuera de la planilla y al final
/// el biométrico. El detalle de cada aviso es siempre el texto del SP.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_detalle_reporte.dart';

/// Avisos de un tipo que se ven sin desplegar el grupo.
const int _avisosALaVista = 3;

/// Los tipos de W que dejan el reporte fuera de la planilla: no se liquida y
/// sigue aprobado (lo dice el detalle del SP).
const Set<String> _tiposFuera = {
  'SIN_HABER',
  'HABER_CERO',
  'SIN_HORAS',
  'ANTES_INICIO',
};

/// Cuántos reportes distintos quedan fuera de la planilla según W.
int reportesFueraHex(List<HexAvisoEntity> avisos) =>
    {
      for (final a in avisos)
        if (_tiposFuera.contains(a.tipoAviso)) a.idReporte,
    }.length;

/// Cómo se presenta cada tipo de aviso del SP W: rótulo, icono, tono y orden.
/// Lo provisional va en `error` y los avisos en ámbar; el detalle de cada
/// aviso es siempre el texto del SP.
({String titulo, IconData icono, TonoHex tono, int orden}) _tipoAviso(
  String tipo,
) => switch (tipo) {
  'PROVISIONAL' => (
    titulo: 'Monto provisional',
    icono: Icons.hourglass_top,
    tono: TonoHex.error,
    orden: 0,
  ),
  'SIN_HABER' => (
    titulo: 'Fuera de la planilla: sin haber básico',
    icono: Icons.block,
    tono: TonoHex.pendiente,
    orden: 1,
  ),
  'HABER_CERO' => (
    titulo: 'Fuera de la planilla: haber básico en cero',
    icono: Icons.block,
    tono: TonoHex.pendiente,
    orden: 2,
  ),
  'SIN_HORAS' => (
    titulo: 'Fuera de la planilla: sin hora de inicio o de fin',
    icono: Icons.block,
    tono: TonoHex.pendiente,
    orden: 3,
  ),
  'ANTES_INICIO' => (
    titulo: 'Fuera de la planilla: jornada anterior al inicio del módulo',
    icono: Icons.block,
    tono: TonoHex.pendiente,
    orden: 4,
  ),
  'BIOMETRICO' => (
    titulo: 'El biométrico registra otra hora',
    icono: Icons.fingerprint,
    tono: TonoHex.pendiente,
    orden: 5,
  ),
  _ => (
    titulo: tipo,
    icono: Icons.info_outline,
    tono: TonoHex.neutro,
    orden: 6,
  ),
};

/// Las tres familias del semáforo: qué tipos de aviso cuenta cada chip, su
/// rótulo (singular y plural) y a qué tipo lleva al tocarlo.
typedef _FamiliaAvisoHex =
    ({Set<String> tipos, String uno, String varios, String primero});

const List<_FamiliaAvisoHex> _familiasAviso = [
  (
    tipos: {'PROVISIONAL'},
    uno: 'provisional',
    varios: 'provisionales',
    primero: 'PROVISIONAL',
  ),
  (
    tipos: _tiposFuera,
    uno: 'fuera de la planilla',
    varios: 'fuera de la planilla',
    primero: 'SIN_HABER',
  ),
  (
    tipos: {'BIOMETRICO'},
    uno: 'con aviso de biométrico',
    varios: 'con aviso de biométrico',
    primero: 'BIOMETRICO',
  ),
];

/// Cuántos reportes distintos tienen avisos de alguno de [tipos].
int _reportesConAviso(List<HexAvisoEntity> avisos, Set<String> tipos) =>
    {
      for (var i = 0; i < avisos.length; i++)
        if (tipos.contains(avisos[i].tipoAviso)) avisos[i].idReporte ?? -i,
    }.length;

/// Cuántos reportes tienen avisos de monto provisional.
int reportesProvisionalesHex(List<HexAvisoEntity> avisos) =>
    _reportesConAviso(avisos, const {'PROVISIONAL'});

/// Cuántos reportes tienen un aviso del biométrico.
int reportesBiometricoHex(List<HexAvisoEntity> avisos) =>
    _reportesConAviso(avisos, const {'BIOMETRICO'});

/// El semáforo de la vista previa: un chip por familia de avisos que hay.
/// Tocar uno lleva a su sección con [alIr] (recibe el primer tipo de esa
/// familia que existe); sin avisos, un chip verde.
class SemaforoAvisosHex extends StatelessWidget {
  const SemaforoAvisosHex({
    super.key,
    required this.avisos,
    required this.alIr,
  });

  final List<HexAvisoEntity> avisos;
  final ValueChanged<String> alIr;

  @override
  Widget build(BuildContext context) {
    final fichas = <Widget>[];
    for (final f in _familiasAviso) {
      final n = _reportesConAviso(avisos, f.tipos);
      if (n == 0) continue;
      final primero = avisos
          .map((a) => a.tipoAviso)
          .where(f.tipos.contains)
          .reduce((a, b) => _tipoAviso(a).orden <= _tipoAviso(b).orden ? a : b);
      final tipo = _tipoAviso(f.primero);
      fichas.add(
        _FichaSemaforoHex(
          texto: cuentaHex(n, f.uno, f.varios),
          icono: tipo.icono,
          tono: tipo.tono,
          alTocar: () {
            HapticaHex.toque();
            alIr(primero);
          },
        ),
      );
    }
    return Semantics(
      container: true,
      label: 'Avisos de la vista previa',
      child: Wrap(
        spacing: Esp.s,
        runSpacing: Esp.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children:
            fichas.isEmpty
                ? const [
                  ChipHex(
                    texto: 'Sin avisos',
                    icono: Icons.check_circle_outline,
                    tono: TonoHex.exito,
                  ),
                ]
                : fichas,
      ),
    );
  }
}

/// Un chip del semáforo con 48 px de área táctil.
class _FichaSemaforoHex extends StatelessWidget {
  const _FichaSemaforoHex({
    required this.texto,
    required this.icono,
    required this.tono,
    required this.alTocar,
  });

  final String texto;
  final IconData icono;
  final TonoHex tono;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$texto: ver los avisos',
    excludeSemantics: true,
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(
          widthFactor: 1,
          child: ChipHex(texto: texto, icono: icono, tono: tono),
        ),
      ),
    ),
  );
}

/// Los avisos de W agrupados por tipo, o lo que pasa mientras llegan.
class SeccionAvisosHex extends StatelessWidget {
  const SeccionAvisosHex({
    super.key,
    required this.avisos,
    required this.reintentar,
    this.claves = const {},
  });

  final AsyncValue<List<HexAvisoEntity>> avisos;
  final VoidCallback reintentar;

  /// Una clave por tipo de aviso: el semáforo las usa para llevar a su grupo.
  final Map<String, GlobalKey> claves;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Avisos antes de ejecutar', style: context.tituloSeccion()),
      const SizedBox(height: Esp.xs),
      avisos.when(
        skipLoadingOnReload: true,
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error:
            (e, _) => NotaDelDato(
              texto: textoErrorHex(e),
              tono: TonoNota.error,
              accion: TextButton(
                onPressed: reintentar,
                child: const Text('Reintentar'),
              ),
            ),
        data: (lista) {
          if (lista.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: Esp.s),
              child: AvisoHex(
                texto: 'Sin avisos: ningún reporte necesita revisión.',
                icono: Icons.check_circle_outline,
                tono: TonoHex.exito,
              ),
            );
          }
          final grupos = <String, List<HexAvisoEntity>>{};
          for (final a in lista) {
            grupos.putIfAbsent(a.tipoAviso, () => []).add(a);
          }
          final tipos =
              grupos.keys.toList()
                ..sort((a, b) => _tipoAviso(a).orden - _tipoAviso(b).orden);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Toca un aviso para ver su reporte.',
                style: context.apagado(),
              ),
              for (final tipo in tipos)
                _GrupoAvisosHex(
                  key: claves[tipo],
                  tipo: tipo,
                  avisos: grupos[tipo]!,
                ),
            ],
          );
        },
      ),
    ],
  );
}

/// Un tipo de aviso: rótulo y cantidad, y sus avisos (los primeros a la
/// vista; el resto, al desplegar).
class _GrupoAvisosHex extends StatefulWidget {
  const _GrupoAvisosHex({super.key, required this.tipo, required this.avisos});

  final String tipo;
  final List<HexAvisoEntity> avisos;

  @override
  State<_GrupoAvisosHex> createState() => _GrupoAvisosHexState();
}

class _GrupoAvisosHexState extends State<_GrupoAvisosHex> {
  bool _todos = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tipo = _tipoAviso(widget.tipo);
    final (:fondo, :letra) = coloresTonoHex(context, tipo.tono);
    final n = widget.avisos.length;
    final visibles =
        _todos ? widget.avisos : widget.avisos.take(_avisosALaVista).toList();
    return Container(
      margin: const EdgeInsets.only(top: Esp.s),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.m, Esp.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(tipo.icono, size: 18, color: letra),
                const SizedBox(width: Esp.s),
                Expanded(
                  child: Text(
                    tipo.titulo,
                    style: t.titleSmall?.copyWith(
                      color: letra,
                      fontWeight: Peso.titulo,
                    ),
                  ),
                ),
                const SizedBox(width: Esp.s),
                Text(
                  cuentaHex(n, 'reporte', 'reportes'),
                  style: t.labelMedium?.copyWith(color: letra),
                ),
              ],
            ),
          ),
          for (final a in visibles) _AvisoHex(aviso: a, color: letra),
          if (n > _avisosALaVista)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: letra,
                  minimumSize: const Size(48, 48),
                  visualDensity: VisualDensity.standard,
                ),
                onPressed: () => setState(() => _todos = !_todos),
                child: Text(_todos ? 'Ver menos' : 'Ver los $n avisos'),
              ),
            )
          else
            const SizedBox(height: Esp.s),
        ],
      ),
    );
  }
}

/// Un aviso: empleado y jornada, el texto del SP; tocarlo abre el reporte.
class _AvisoHex extends StatelessWidget {
  const _AvisoHex({required this.aviso, required this.color});

  final HexAvisoEntity aviso;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final id = aviso.idReporte;
    return InkWell(
      onTap: id == null ? null : () => mostrarDetalleReporteHex(context, id),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Esp.m + 18 + Esp.s,
            Esp.xs,
            Esp.m,
            Esp.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${oGuionHex(aviso.nombreEmpleado)} · '
                      '${fechaHex(aviso.fechaJornada)}',
                      style: t.labelLarge?.copyWith(color: color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      oGuionHex(aviso.detalle),
                      style: t.bodySmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              if (id != null) Icon(Icons.chevron_right, size: 20, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
