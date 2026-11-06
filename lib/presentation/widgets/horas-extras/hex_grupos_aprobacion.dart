/// Grupos de la bandeja del jefe de área: los reportes con visto bueno de un
/// encargado en un mes, que se aprueban juntos con «Aprobar todo».
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_piezas.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// Lo que identifica un grupo y viaja a `aprobar-grupo`.
typedef ClaveGrupoHex = ({BigInt codEncargado, int anio, int mes});

/// Los reportes de un encargado con jornada en [anio]/[mes]. El encargado lo
/// pone el SP J (quien dio el visto bueno, o el dueño si es encargado).
class GrupoAprobacionHex {
  const GrupoAprobacionHex({
    required this.codEncargado,
    required this.nombreEncargado,
    required this.anio,
    required this.mes,
    required this.reportes,
  });

  final BigInt codEncargado;
  final String nombreEncargado;
  final int anio;
  final int mes;
  final List<HexReporteEntity> reportes;

  ClaveGrupoHex get clave => (codEncargado: codEncargado, anio: anio, mes: mes);

  /// `octubre de 2026`.
  String get periodo => periodoHex(anio, mes);

  /// Si «Aprobar todo» tiene qué hacer: un encargado y un mes reales (no la
  /// clave 0 de una fila incompleta) y algún reporte que el SP deja aprobar.
  bool get puedeAprobarTodo =>
      codEncargado != BigInt.zero &&
      mes != 0 &&
      reportes.any((r) => r.puedeAprobar);
}

/// Agrupa por encargado y por el año y mes de la jornada. Ordena por nombre
/// del encargado y, dentro de cada uno, del mes más reciente al más antiguo;
/// las filas conservan el orden del SP.
List<GrupoAprobacionHex> agruparHex(List<HexReporteEntity> filas) {
  final grupos = <ClaveGrupoHex, List<HexReporteEntity>>{};
  for (final r in filas) {
    // El SP J siempre manda los dos; el cero solo evita perder una fila.
    final clave = (
      codEncargado: r.codEncargado ?? BigInt.zero,
      anio: r.fechaJornada?.year ?? 0,
      mes: r.fechaJornada?.month ?? 0,
    );
    grupos.putIfAbsent(clave, () => []).add(r);
  }
  final lista = [
    for (final MapEntry(key: c, value: reportes) in grupos.entries)
      GrupoAprobacionHex(
        codEncargado: c.codEncargado,
        nombreEncargado: reportes.first.nombreEncargado?.trim() ?? '',
        anio: c.anio,
        mes: c.mes,
        reportes: List.unmodifiable(reportes),
      ),
  ];
  int periodo(GrupoAprobacionHex g) => g.anio * 100 + g.mes;
  lista.sort((a, b) {
    final porNombre = a.nombreEncargado.toLowerCase().compareTo(
      b.nombreEncargado.toLowerCase(),
    );
    if (porNombre != 0) return porNombre;
    final porEncargado = a.codEncargado.compareTo(b.codEncargado);
    if (porEncargado != 0) return porEncargado;
    return periodo(b).compareTo(periodo(a));
  });
  return lista;
}

/// La cabecera de un grupo: «Rojas Vargas Luis — octubre de 2026 · 2
/// reportes» y «Aprobar todo» si el grupo lo admite y el usuario tiene el
/// botón. [enTabla]: franja de la tabla; si no, panel de tarjetas.
class CabeceraGrupoHex extends StatelessWidget {
  const CabeceraGrupoHex(
    this.grupo, {
    super.key,
    required this.enTabla,
    required this.ocupado,
    required this.alAprobarTodo,
  });

  final GrupoAprobacionHex grupo;
  final bool enTabla;

  /// Este grupo se está aprobando: su botón muestra la espera.
  final bool ocupado;

  /// Nulo mientras otro grupo se aprueba: el botón queda deshabilitado.
  final VoidCallback? alAprobarTodo;

  @override
  Widget build(BuildContext context) {
    final n = grupo.reportes.length;
    final aprobarTodo =
        grupo.puedeAprobarTodo
            ? PermissionWidget(
              buttonName: BotonHex.aprobarGrupo,
              child: SizedBox(
                height: 48,
                child: BotonAccion(
                  etiqueta: 'Aprobar todo',
                  etiquetaOcupado: 'Aprobando…',
                  icono: Icons.done_all,
                  tonal: true,
                  ocupado: ocupado,
                  onPressed: alAprobarTodo,
                ),
              ),
            )
            : null;
    return FranjaGrupoHex(
      enTabla: enTabla,
      icono: Icons.supervisor_account_outlined,
      titulo: oGuionHex(grupo.nombreEncargado),
      detalle: '${grupo.periodo} · ${cuentaHex(n, 'reporte', 'reportes')}',
      accion: aprobarTodo,
    );
  }
}
