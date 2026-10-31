import 'package:bosque_flutter/domain/entities/asiento_sap_entity.dart';

/// `data` de POST /planilla/asiento-sap/vista-previa.
class AsientoSapModel {
  final Map<String, dynamic> _json;

  AsientoSapModel.fromJson(Map<String, dynamic> json) : _json = json;

  static double _monto(dynamic v) => (v as num?)?.toDouble() ?? 0;

  AsientoSapEntity toEntity() {
    final lineas = (_json['lineas'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .map(
          (l) => AsientoSapLineaEntity(
            codigo: l['codigo'] ?? '',
            nombre: l['nombre'] ?? '',
            cuenta: l['cuenta'] ?? '',
            socio: l['socio'],
            debito: _monto(l['debito']),
            credito: _monto(l['credito']),
          ),
        )
        .toList();
    return AsientoSapEntity(
      anio: _json['anio'] ?? 0,
      mes: _json['mes'] ?? 0,
      codEmpresa: _json['codEmpresa'] ?? 0,
      empresa: _json['empresa'] ?? '',
      baseSap: _json['baseSap'] ?? '',
      fecha: _json['fecha'] ?? '',
      memo: _json['memo'] ?? '',
      referencia: _json['referencia'] ?? '',
      lineas: lineas,
      totalDebito: _monto(_json['totalDebito']),
      totalCredito: _monto(_json['totalCredito']),
      diferencia: _monto(_json['diferencia']),
      cuadra: _json['cuadra'] == true,
    );
  }
}

/// Una fila de POST /planilla/asiento-sap/config/listar, y el cuerpo de /config/guardar.
abstract final class AsientoSapConfigModel {
  static AsientoSapConfigEntity fromJson(Map<String, dynamic> j) =>
      AsientoSapConfigEntity(
        codEmpresa: j['codEmpresa'] ?? 0,
        empresa: j['empresa'] ?? '',
        habilitado: j['habilitado'] == true,
        baseSap: j['baseSap'] ?? '',
        linkedServer: j['linkedServer'] ?? '',
        esquema: j['esquema'] ?? 'dbo',
        sp: j['sp'] ?? '',
        paramAnio: j['paramAnio'] ?? '',
        paramMes: j['paramMes'] ?? '',
        colCodigo: j['colCodigo'] ?? '',
        colNombre: j['colNombre'] ?? '',
        colCuenta: j['colCuenta'] ?? '',
        colDebito: j['colDebito'] ?? '',
        colCredito: j['colCredito'] ?? '',
        prefijosSocio: j['prefijosSocio'] ?? '',
        diaDelMes: j['diaDelMes'] ?? 30,
        memo: j['memo'] ?? '',
        referencia: j['referencia'] ?? '',
        campoReferencia: j['campoReferencia'] ?? '',
        evitarDuplicados: j['evitarDuplicados'] != false,
        tolerancia: (j['tolerancia'] as num?)?.toDouble() ?? 0,
        slUrl: j['slUrl'] ?? '',
        slUsuario: j['slUsuario'] ?? '',
        claveCargada: j['claveCargada'] == true,
        audFecha:
            j['audFecha'] != null ? DateTime.tryParse(j['audFecha'].toString()) : null,
      );

  /// Sin la contraseña, que tiene su propio endpoint, ni los campos que calcula el backend.
  static Map<String, dynamic> toJson(AsientoSapConfigEntity c) => {
    'codEmpresa': c.codEmpresa,
    'habilitado': c.habilitado,
    'baseSap': c.baseSap,
    'linkedServer': c.linkedServer,
    'esquema': c.esquema,
    'sp': c.sp,
    'paramAnio': c.paramAnio,
    'paramMes': c.paramMes,
    'colCodigo': c.colCodigo,
    'colNombre': c.colNombre,
    'colCuenta': c.colCuenta,
    'colDebito': c.colDebito,
    'colCredito': c.colCredito,
    'prefijosSocio': c.prefijosSocio,
    'diaDelMes': c.diaDelMes,
    'memo': c.memo,
    'referencia': c.referencia,
    'campoReferencia': c.campoReferencia,
    'evitarDuplicados': c.evitarDuplicados,
    'tolerancia': c.tolerancia,
    'slUrl': c.slUrl,
    'slUsuario': c.slUsuario,
  };
}
