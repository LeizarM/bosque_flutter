// Destino final: lib/data/models/responsable_cierre_model.dart
import 'package:bosque_flutter/domain/entities/responsable_cierre_entity.dart';

/// Lectura de p_list_tac_ResponsableCierre L, C, S (81 y 85), E y W (86).
class ResponsableCierreModel {
  ResponsableCierreModel._();

  static int? _int(dynamic v) => (v as num?)?.toInt();

  static String? _texto(dynamic v) {
    final s = (v as String?)?.replaceAll(RegExp(r'\s+'), ' ').trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static ResponsableCierre fila(Map<String, dynamic> j) {
    final codigo = _texto(j['seccion']) ?? '?';
    return ResponsableCierre(
      idRC: _int(j['idRC']) ?? 0,
      idTarRuti: _int(j['idTarRuti']) ?? 39,
      codigoSeccion: codigo,
      nombreSeccion: _texto(j['nombreSeccion']) ?? codigo,
      // Sin el dato (servidor sin el 86): vigente, como antes.
      seccionVigente: _int(j['seccionVigente']) != 0,
      codSucursal: _int(j['codSucursal']),
      nombreSucursal: _texto(j['nombreSucursal']) ?? 'Todas',
      codCargoSucursal: _int(j['codCargoSucursal']),
      cargo: _texto(j['cargo']),
      sucursalDelCargo: _texto(j['sucursalDelCargo']),
      codEmpleado: _int(j['codEmpleado']),
      personas: _texto(j['personas']),
      puedeAutorrevisar: _int(j['puedeAutorrevisar']) == 1,
      activo: (_int(j['estado']) ?? 1) == 1,
    );
  }

  static CandidatoCierre candidato(Map<String, dynamic> j) => CandidatoCierre(
    esCargo: _texto(j['tipo']) != 'P',
    codCargoSucursal: _int(j['codCargoSucursal']),
    codEmpleado: _int(j['codEmpleado']),
    cargo: _texto(j['cargo']) ?? '—',
    sucursal: _texto(j['sucursal']) ?? '—',
    personas: _texto(j['personas']),
    tieneLaTarea: _int(j['tieneLaTarea']) == 1,
    secciones: _int(j['secciones']) ?? 0,
  );

  static SeccionCierre seccion(Map<String, dynamic> j) => SeccionCierre(
    codigo: _texto(j['seccion']) ?? '?',
    nombre: _texto(j['nombre']) ?? '—',
    queRevisar: _texto(j['queRevisar']),
    porSucursal: _int(j['porSucursal']) == 1,
    propia: _int(j['propia']) == 1,
    fuente: _texto(j['fuente']),
    nombreFuente: _texto(j['nombreFuente']),
    marcaPorFila: _int(j['marcaPorFila']) != 0,
    firmaSola: _int(j['firmaSola']) != 0,
    obsDesde: _int(j['obsDesde']) ?? 1,
    diaRevisado: _texto(j['diaRevisado']) ?? 'H',
    orden: _int(j['orden']) ?? 100,
    vigente: _int(j['vigente']) != 0,
    responsables: _int(j['responsables']) ?? 0,
  );

  static FuenteCierre fuente(Map<String, dynamic> j) => FuenteCierre(
    fuente: _texto(j['fuente']) ?? '',
    tipo: _texto(j['tipo']) ?? 'F',
    nombre: _texto(j['nombre']) ?? _texto(j['fuente']) ?? '—',
    descripcion: _texto(j['descripcion']),
    spMarcar: _texto(j['spMarcar']),
    guardaEnSuModulo: _int(j['guardaEnSuModulo']) == 1,
    // Sin el dato ('W' solo trae las que sirven): activa, existe y sirve.
    activa: (_int(j['estado']) ?? 1) == 1,
    existe: (_int(j['existe']) ?? 1) == 1,
    columnasOk: (_int(j['columnasOk']) ?? 1) == 1,
    secciones: _int(j['secciones']) ?? 0,
    usadaPor: _texto(j['usadaPor']),
  );

  static CandidatoFuente candidatoFuente(Map<String, dynamic> j) =>
      CandidatoFuente(
        fuente: _texto(j['fuente']) ?? '',
        tipo: _texto(j['tipo']) ?? 'F',
        columnasOk: (_int(j['columnasOk']) ?? 1) == 1,
      );

  static SucursalCaja sucursal(Map<String, dynamic> j) => SucursalCaja(
    _int(j['codSucursal']) ?? 0,
    _texto(j['nombreSucursal']) ?? '—',
  );
}
