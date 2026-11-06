/// «Aprobadores» agrupado por jefe de área y por observador (D45): cada uno
/// con los encargados que tiene asignados y, al final, los encargados sin
/// jefe. Solo presentación: el SP manda las filas tal cual y aquí se ordenan.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';

/// En qué momento está una fila respecto de [hoy].
enum EstadoAprobadorHex { vigente, programada, cerrada }

/// Vigente si el SP lo dice; cerrada si su fin ya pasó; si no, programada
/// (el SP solo deja de marcarla vigente porque aún no empieza).
EstadoAprobadorHex estadoAprobadorHex(HexAprobadorEntity a, DateTime hoy) {
  if (a.esVigente) return EstadoAprobadorHex.vigente;
  final hasta = a.vigenteHasta;
  if (hasta != null && DateUtils.dateOnly(hasta).isBefore(hoy)) {
    return EstadoAprobadorHex.cerrada;
  }
  return EstadoAprobadorHex.programada;
}

/// Sin «Mostrar cerradas» solo se ven las vigentes y las programadas.
bool visibleAprobadorHex(HexAprobadorEntity a, DateTime hoy) =>
    estadoAprobadorHex(a, hoy) != EstadoAprobadorHex.cerrada;

/// Un encargado en el árbol: el [par] jefe → encargado (nivel 2) y su [rol]
/// de encargado (nivel 1). Bajo un jefe siempre hay par; sin jefe, solo rol.
class NodoEncargadoHex {
  const NodoEncargadoHex({this.par, this.rol})
    : assert(par != null || rol != null);

  final HexAprobadorEntity? par;
  final HexAprobadorEntity? rol;

  /// La fila que trae cargo, rama y aviso del encargado: el rol o, sin él,
  /// el par (el SP manda en el par los datos del encargado).
  HexAprobadorEntity get datos => rol ?? par!;

  BigInt? get codEncargado =>
      rol?.codEmpleadoAprobador ?? par?.codEmpleadoAprobado;

  String get nombre => rol?.nombreAprobador ?? par?.nombreAprobado ?? '';
}

/// Un jefe de área u observador ([jefe] es una de sus filas de par) con sus
/// encargados, o el grupo de los encargados sin jefe ([jefe] nulo). Las
/// cuentas no cambian al filtrar: cuentan los pares no cerrados, un encargado
/// una vez.
class GrupoAprobadoresHex {
  const GrupoAprobadoresHex({
    required this.jefe,
    required this.nodos,
    required this.encargados,
    required this.empleados,
  });

  final HexAprobadorEntity? jefe;
  final List<NodoEncargadoHex> nodos;
  final int encargados;
  final int empleados;

  bool get sinJefe => jefe == null;

  /// D45: el grupo es de un observador (nivel 3), no de un jefe de área.
  bool get esObservador => jefe?.nivel == 3;

  GrupoAprobadoresHex _con(List<NodoEncargadoHex> otros) => GrupoAprobadoresHex(
    jefe: jefe,
    nodos: otros,
    encargados: encargados,
    empleados: empleados,
  );
}

/// Agrupa [filas] por jefe y luego por observador (por nombre) y deja al
/// final «Sin jefe de área»; el observador no saca al encargado de ese grupo.
/// Con [codEmpleado]: el grupo entero si es el jefe, o solo sus nodos si es
/// encargado. Sin [conCerradas] se omiten las filas cerradas.
List<GrupoAprobadoresHex> agruparAprobadoresHex(
  List<HexAprobadorEntity> filas, {
  required DateTime hoy,
  bool conCerradas = false,
  BigInt? codEmpleado,
}) {
  final dia = DateUtils.dateOnly(hoy);
  final visibles = [
    for (final a in filas)
      if (conCerradas || visibleAprobadorHex(a, dia)) a,
  ];

  // Roles de encargado por persona, para elegir el que acompaña a cada nodo.
  final roles = <BigInt?, List<HexAprobadorEntity>>{};
  for (final a in visibles.where((a) => a.nivel == 1)) {
    roles.putIfAbsent(a.codEmpleadoAprobador, () => []).add(a);
  }
  HexAprobadorEntity? rolDe(BigInt? cod) =>
      cod == null ? null : _mejorRol(roles[cod] ?? const [], dia);

  final porJefe = <BigInt?, List<HexAprobadorEntity>>{};
  for (final a in visibles.where((a) => a.nivel == 2)) {
    porJefe.putIfAbsent(a.codEmpleadoAprobador, () => []).add(a);
  }
  final porObservador = <BigInt?, List<HexAprobadorEntity>>{};
  for (final a in visibles.where((a) => a.nivel == 3)) {
    porObservador.putIfAbsent(a.codEmpleadoAprobador, () => []).add(a);
  }
  final conJefe = <BigInt>{
    for (final pares in porJefe.values)
      for (final p in pares)
        if (p.codEmpleadoAprobado case final cod?) cod,
  };

  final grupos = <GrupoAprobadoresHex>[
    for (final pares in porJefe.values)
      _grupo(
        jefe: _mejorRol(pares, dia)!,
        nodos: [
          for (final p in pares)
            NodoEncargadoHex(par: p, rol: rolDe(p.codEmpleadoAprobado)),
        ],
        hoy: dia,
      ),
  ]..sort(
    (a, b) => _comparar(a.jefe!.nombreAprobador, b.jefe!.nombreAprobador),
  );

  final observadores = <GrupoAprobadoresHex>[
    for (final pares in porObservador.values)
      _grupo(
        jefe: _mejorRol(pares, dia)!,
        nodos: [
          for (final p in pares)
            NodoEncargadoHex(par: p, rol: rolDe(p.codEmpleadoAprobado)),
        ],
        hoy: dia,
      ),
  ]..sort(
    (a, b) => _comparar(a.jefe!.nombreAprobador, b.jefe!.nombreAprobador),
  );
  grupos.addAll(observadores);

  final sueltos = [
    for (final entrada in roles.entries)
      if (entrada.key == null || !conJefe.contains(entrada.key))
        NodoEncargadoHex(rol: _mejorRol(entrada.value, dia)),
  ];
  if (sueltos.isNotEmpty) {
    grupos.add(_grupo(jefe: null, nodos: sueltos, hoy: dia));
  }

  final cod = codEmpleado;
  if (cod == null) return grupos;
  return [
    for (final g in grupos)
      if (g.jefe?.codEmpleadoAprobador == cod)
        g
      else if (g.nodos.where((n) => n.codEncargado == cod).toList()
          case final propios when propios.isNotEmpty)
        g._con(propios),
  ];
}

/// Ordena los nodos y cuenta los encargados (y su rama) de pares no cerrados.
GrupoAprobadoresHex _grupo({
  required HexAprobadorEntity? jefe,
  required List<NodoEncargadoHex> nodos,
  required DateTime hoy,
}) {
  nodos.sort((a, b) {
    final porNombre = _comparar(a.nombre, b.nombre);
    if (porNombre != 0) return porNombre;
    final da = (a.par ?? a.rol)?.vigenteDesde ?? DateTime(0);
    final db = (b.par ?? b.rol)?.vigenteDesde ?? DateTime(0);
    return db.compareTo(da);
  });
  final contados = <Object?>{};
  var empleados = 0;
  for (final n in nodos) {
    final fila = n.par ?? n.rol!;
    if (estadoAprobadorHex(fila, hoy) == EstadoAprobadorHex.cerrada) continue;
    if (!contados.add(n.codEncargado ?? n)) continue;
    empleados += n.datos.cantidadRama;
  }
  return GrupoAprobadoresHex(
    jefe: jefe,
    nodos: nodos,
    encargados: contados.length,
    empleados: empleados,
  );
}

/// La fila que representa a una persona: la vigente; si no, la programada
/// más próxima; si no, la más reciente.
HexAprobadorEntity? _mejorRol(List<HexAprobadorEntity> filas, DateTime hoy) {
  HexAprobadorEntity? mejor;
  int rango(HexAprobadorEntity a) => switch (estadoAprobadorHex(a, hoy)) {
    EstadoAprobadorHex.vigente => 0,
    EstadoAprobadorHex.programada => 1,
    EstadoAprobadorHex.cerrada => 2,
  };
  for (final a in filas) {
    final m = mejor;
    if (m == null) {
      mejor = a;
      continue;
    }
    final ra = rango(a);
    final rm = rango(m);
    if (ra != rm) {
      if (ra < rm) mejor = a;
      continue;
    }
    final da = a.vigenteDesde ?? DateTime(0);
    final dm = m.vigenteDesde ?? DateTime(0);
    // Programadas: la que empieza antes; las demás, la que empezó después.
    if (ra == 1 ? da.isBefore(dm) : da.isAfter(dm)) mejor = a;
  }
  return mejor;
}

int _comparar(String a, String b) =>
    a.trim().toLowerCase().compareTo(b.trim().toLowerCase());
