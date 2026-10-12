// Capturas de las pantallas del módulo Tareas Rutinarias, para mirarlas.
//
// NO es una prueba: no afirma nada y no la levanta `flutter test` solo (el
// nombre no termina en _test.dart). Se corre a mano:
//
//   flutter test test/capturas/capturas_tareas.dart --dart-define=CAPTURAS=<carpeta>
//
// Responde a la red con datos de ejemplo interceptando Dio, así las pantallas
// funcionan con sus providers de verdad, sin backend ni login. Las fuentes son
// las reales del proyecto: con la de prueba de Flutter cada letra es un
// rectángulo y no se puede juzgar nada.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/presentation/screens/screens.dart';
import 'package:bosque_flutter/presentation/widgets/talonarios/uso_caja_chica.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Datos reales para mirar la pantalla de otras personas, desde un JSON que
/// vive fuera del repo: `--dart-define=ESCENARIO=<ruta>`. Lista de
/// {nombre, usuario, respuestas}; ver la prueba "escenario".
const _archivoEscenario = String.fromEnvironment('ESCENARIO');

const _salida = String.fromEnvironment(
  'CAPTURAS',
  defaultValue: 'build/capturas',
);

/// El mismo usuario con otro tipo: un administrador ve todos los paneles sin
/// que la captura tenga que responder el ACL de botones.
LoginEntity _usuarioDe(String tipoUsuario) => LoginEntity(
  token: 'x',
  bearer: 'Bearer',
  nombreCompleto: 'QUISPE MAMANI RONALDO',
  cargo: 'CAJERO',
  tipoUsuario: tipoUsuario,
  codUsuario: 90,
  codEmpleado: 180,
  codEmpresa: 1,
  codCiudad: 1,
  login: 'rquispe',
  versionApp: '1.0.1',
  codSucursal: 1,
  esAutorizador: 'N',
  estado: 'A',
  audUsuarioI: 34,
  nombreSucursal: 'CENTRAL',
  nombreCiudad: 'LA PAZ',
  nombreEmpresa: 'IMPEXPAP',
  npassword: '',
  password: '',
  password2: '',
);

final _admin = _usuarioDe('ROLE_ADM');

final _usuario = LoginEntity(
  token: 'x',
  bearer: 'Bearer',
  nombreCompleto: 'QUISPE MAMANI RONALDO',
  cargo: 'CAJERO',
  tipoUsuario: 'lim',
  codUsuario: 90,
  codEmpleado: 180,
  codEmpresa: 1,
  codCiudad: 1,
  login: 'rquispe',
  versionApp: '1.0.1',
  codSucursal: 1,
  esAutorizador: 'N',
  estado: 'A',
  audUsuarioI: 34,
  nombreSucursal: 'CENTRAL',
  nombreCiudad: 'LA PAZ',
  nombreEmpresa: 'IMPEXPAP',
  npassword: '',
  password: '',
  password2: '',
);

String _f(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')} 00:00:00';

final _hoy = DateTime.now();
DateTime _dias(int n) => DateTime(_hoy.year, _hoy.month, _hoy.day + n);

// ── Datos de ejemplo, con textos reales de la base ────────────────────────────

List<Map<String, dynamic>> _misTareas() {
  var id = 1000;
  Map<String, dynamic> t(
    String nombre, {
    required int idATR,
    required int idFrec,
    required int enDias,
    int idTarRuti = 1,
  }) => {
    'idBitTarea': id++,
    'fechaActivo': _f(_dias(enDias)),
    'fechaPresentacion': _f(_dias(enDias)),
    'idTarRuti': idTarRuti,
    'nombreTareaRutinaria': nombre,
    'codEmpleado': 180,
    'descripCargo': 'CAJERO',
    'fechaCompletado': null,
    'fueRealizado': 12,
    'obs': null,
    'estado': 1,
    'audUsuario': -1,
    'audFecha': _f(_hoy),
    'idATR': idATR,
    'idFrec': idFrec,
  };
  return [
    t('Arqueo de Caja', idATR: 2, idFrec: 6, enDias: 0, idTarRuti: 1),
    t(
      'Verificar traspaso Caja AXA contra movimiento de caja',
      idATR: 12,
      idFrec: 6,
      enDias: 0,
      idTarRuti: 295,
    ),
    t(
      'Verificar Traspaso de Efectivo Entre Sistemas',
      idATR: 11,
      idFrec: 6,
      enDias: 0,
      idTarRuti: 289,
    ),
    t(
      'Revisar que los depósitos bancarios del día coincidan con el reporte de ventas',
      idATR: 1,
      idFrec: 6,
      enDias: -1,
      idTarRuti: 300,
    ),
    t(
      'Supervisar y controlar los insumos de impresión para las diferentes sucursales.',
      idATR: 1,
      idFrec: 1,
      enDias: 12,
      idTarRuti: 248,
    ),
    t(
      'Supervisar, controlar y documentar el mantenimiento de los equipos de las diferentes áreas de la empresa, reportando cualquier anomalía al gerente de sistemas y operaciones.',
      idATR: 1,
      idFrec: 1,
      enDias: -3,
      idTarRuti: 246,
    ),
    t(
      'Realizar el almacenaje de las copias de seguridad',
      idATR: 1,
      idFrec: 2,
      enDias: 3,
      idTarRuti: 247,
    ),
    t(
      'Supervisar y controlar que todos los usuarios que necesiten el sistema SAP lo tengan a su disposición.',
      idATR: 1,
      idFrec: 5,
      enDias: 60,
      idTarRuti: 254,
    ),
  ];
}

List<Map<String, dynamic>> _bitacora() {
  final personas = [
    (180, 'QUISPE MAMANI RONALDO', 158, 'CAJERO', 1, 'CENTRAL'),
    (117, 'CHOQUE APAZA FABIOLA', 160, 'RESPONSABLE SUCURSAL', 3, 'CENTRO SCZ'),
    (32, 'ALMENDRAS ROCHA ERICK', 144, 'JEFE DE SISTEMAS Y OPERACIONES', 1, 'CENTRAL'),
    (28, 'MAMANI TICONA EDWIN', 75, 'RESPONSABLE SUCURSAL EL ALTO', 2, 'EL ALTO'),
  ];
  final tareas = [
    (1, 'Arqueo de Caja', 6, 'Diario'),
    (295, 'Verificar traspaso Caja AXA contra movimiento de caja', 6, 'Diario'),
    (248, 'Supervisar y controlar los insumos de impresión para las diferentes sucursales.', 1, 'Mensual'),
    (247, 'Realizar el almacenaje de las copias de seguridad', 2, 'Semanal'),
  ];
  const estados = ['R', 'R', 'R', 'N', 'R', 'A', 'R', 'P', 'N', 'R'];
  var id = 5000;
  final filas = <Map<String, dynamic>>[];
  for (var d = 0; d < 6; d++) {
    for (var p = 0; p < personas.length; p++) {
      final t = tareas[(d + p) % tareas.length];
      final e = estados[(d * 3 + p) % estados.length];
      final per = personas[p];
      filas.add({
        'idBitTarea': id++,
        'fechaPresentacion': _f(_dias(-d)),
        'fechaCompletado': e == 'R' || e == 'A' ? '${_f(_dias(-d)).substring(0, 10)} 17:42:10' : null,
        'idTarRuti': t.$1,
        'nombreTareaRutinaria': t.$2,
        'idFrec': t.$3,
        'descripcionFrecuencia': t.$4,
        'codEmpleado': per.$1,
        'nombreEmpleado': per.$2,
        'codCargo': per.$3,
        'descripcionCargo': per.$4,
        'codSucursal': per.$5,
        'nombreSucursal': per.$6,
        'fueRealizado': e == 'R' ? 13 : e == 'A' ? 14 : 12,
        'cumplimiento': e,
        'obs': e == 'A' ? 'No aplica: la sucursal estuvo cerrada por inventario.' : null,
        'nombreRespondio': e == 'R' || e == 'A' ? per.$2.split(' ').first : null,
      });
    }
  }
  return filas;
}

List<Map<String, dynamic>> _corridas() {
  final c = '${_f(_hoy).substring(0, 10)} 00:05:03';
  return [
    {'corrida': c, 'motivo': 'Empleado dado de baja', 'cantidad': 6792},
    {'corrida': c, 'motivo': 'Cargo no vigente', 'cantidad': 1031},
    {'corrida': c, 'motivo': 'A requerimiento', 'cantidad': 663},
    {'corrida': c, 'motivo': 'Asignacion inactiva', 'cantidad': 362},
    {'corrida': c, 'motivo': 'Paso los filtros (frecuencia o ya existia)', 'cantidad': 194},
    {'corrida': c, 'motivo': 'Generadas', 'cantidad': 151},
  ];
}

List<Map<String, dynamic>> _porQue() => [
  {'idTarRuti': 1, 'tarea': 'Arqueo de Caja', 'idFrec': 6, 'frecuencia': 'Diario', 'codCargo': 158, 'cargo': 'CAJERO', 'sucursal': 'CENTRAL', 'filtro': 0, 'motivo': 'Se genero.', 'existeOcurrencia': true, 'idBitTarea': 1000, 'fueRealizado': 12},
  {'idTarRuti': 248, 'tarea': 'Supervisar y controlar los insumos de impresión', 'idFrec': 1, 'frecuencia': 'Mensual', 'codCargo': 158, 'cargo': 'CAJERO', 'sucursal': 'CENTRAL', 'filtro': 0, 'motivo': 'Paso todos los filtros: la frecuencia de la tarea no vence en esa fecha.', 'existeOcurrencia': false},
  {'idTarRuti': 42, 'tarea': 'Caja Chica', 'idFrec': 6, 'frecuencia': 'Diario', 'codCargo': 158, 'cargo': 'CAJERO', 'sucursal': 'CENTRAL', 'filtro': 1, 'motivo': 'Es a requerimiento: la ocurrencia se crea al entrar al submodulo, el Job no la genera.', 'existeOcurrencia': false},
  {'idTarRuti': 243, 'tarea': 'Administrar el correo electrónico que maneja la empresa', 'idFrec': 6, 'frecuencia': 'Diario', 'codCargo': 144, 'cargo': 'JEFE DE SISTEMAS Y OPERACIONES', 'sucursal': 'CENTRAL', 'filtro': 3, 'motivo': 'La asignacion de esta tarea a su cargo esta inactiva.', 'existeOcurrencia': false},
];

List<Map<String, dynamic>> _tesBase() => [
  {'codTes': 80, 'codCliente': 'C00731', 'datoCliente': 'DISTRIBUIDORA EL CONDOR S.R.L.', 'nombre': 'IMPEXPAP', 'fechaRegistro': _f(_dias(-4)), 'observacion': 'Depósito en caja central, pasa a ESP', 'estado': 'PEN'},
  {'codTes': 81, 'codCliente': 'C01204', 'datoCliente': 'LIBRERÍA Y PAPELERÍA SAN JOSÉ', 'nombre': 'IMPEXPAP', 'fechaRegistro': _f(_dias(-1)), 'observacion': null, 'estado': 'PEN'},
  {'codTes': 82, 'codCliente': 'C00019', 'datoCliente': 'IMPRENTA OFFSET ANDINA', 'nombre': 'IMPEXPAP', 'fechaRegistro': _f(_hoy), 'observacion': 'Cliente pagó en efectivo en El Alto', 'estado': 'PEN'},
];

List<Map<String, dynamic>> _axa() => [
  // fueVerificado 0 y no null: el SP de verdad hace ISNULL(g.fueVerificado, 0)
  // para lo que nadie revisó. La app lo lee como "sin revisar" por idTrasp 0.
  {'idTrasp': 0, 'bd': 'ESP', 'fecha': _f(_hoy), 'account': '1110101', 'contraAct': '1110102', 'acctName': 'Caja AXA Central', 'tipoTransaccion': 'Traspaso', 'dolares': 0.0, 'bs': 12500.5, 'fueVerificado': 0, 'obs': null, 'soloEnBosque': false, 'audUsuario': 0},
  {'idTrasp': 71, 'bd': 'IMPEXPAP', 'fecha': _f(_hoy), 'account': '1110101', 'contraAct': '1110205', 'acctName': 'Caja AXA El Alto', 'tipoTransaccion': 'Traspaso', 'dolares': 350.0, 'bs': 0.0, 'fueVerificado': 1, 'obs': null, 'soloEnBosque': false, 'audUsuario': 34},
  {'idTrasp': 72, 'bd': 'ESP', 'fecha': _f(_hoy), 'account': '1110101', 'contraAct': '1110301', 'acctName': 'Caja AXA Santa Cruz', 'tipoTransaccion': 'Traspaso', 'dolares': 0.0, 'bs': 1020.0, 'fueVerificado': 0, 'obs': 'El formulario dice 1.200 y el sistema 1.020.', 'soloEnBosque': false, 'audUsuario': 34},
];

/// Los cheques del día cruzados contra SAP (p_SAP_Rpt_ImpChequesPR 'A').
List<Map<String, dynamic>> _cheques() => [
  {'nroCheque': '00012345', 'codCliente': 'C00731', 'cardName': 'DISTRIBUIDORA EL CONDOR S.R.L.', 'monto': 4500.0, 'moneda': 'BS', 'nombre': 'IMPEXPAP', 'resultado': 'COBRADO', 'codEmpresa': 1},
  {'nroCheque': '00012399', 'codCliente': 'C01204', 'cardName': 'LIBRERÍA Y PAPELERÍA SAN JOSÉ', 'monto': 1230.0, 'moneda': 'BS', 'nombre': 'IMPEXPAP', 'resultado': 'SIN COBRAR', 'codEmpresa': 1},
  {'nroCheque': '00098120', 'codCliente': 'C00019', 'cardName': 'IMPRENTA OFFSET ANDINA', 'monto': 800.0, 'moneda': '--', 'nombre': 'ESPPAPEL', 'resultado': 'SIN REGISTRO BOSQUE', 'codEmpresa': 2},
];

/// Las tareas que el Job generó ese día en la sucursal (rama R del archivo 60):
/// las de hoy de la bitácora, que es de donde salen.
List<Map<String, dynamic>> _tareasDelDia() {
  final hoy = _f(_hoy).substring(0, 10);
  return [
    for (final t in _bitacora())
      if ((t['fechaPresentacion'] as String).startsWith(hoy)) t,
  ];
}

List<Map<String, dynamic>> _arqueosDeHoy() => [
  {'idAC': 1, 'fueRevisado': 1, 'total': 15230.5, 'diferencia': 0.0, 'obs': null, 'nombreCompletoEncargado': 'QUISPE MAMANI RONALDO', 'nombreSucursal': 'CENTRAL', 'nombreTarea': 'Arqueo de Caja', 'fecha': _f(_hoy), 'hora': '18:05', 'saldoMovSap': 15230.5},
  {'idAC': 2, 'fueRevisado': 0, 'total': 8120.0, 'diferencia': -35.5, 'obs': 'Faltan 35,50 Bs en monedas', 'nombreCompletoEncargado': 'MAMANI TICONA EDWIN', 'nombreSucursal': 'EL ALTO', 'nombreTarea': 'Arqueo de Caja', 'fecha': _f(_hoy), 'hora': '18:20', 'saldoMovSap': 8155.5},
];

List<Map<String, dynamic>> _llegadasDeHoy() => [
  {'idRp': 1, 'fueVerificado': 0, 'persona': 'Juan Pérez', 'cliente': 'DISTRIBUIDORA EL CONDOR S.R.L.', 'nombreSucursal': 'CENTRAL', 'moneda': 'Bs', 'importe': 4500.0, 'destino': 'Depósito BNB', 'horallegada': '${_f(_hoy).substring(0, 10)} 10:15:00', 'tipo': 'Efectivo'},
  {'idRp': 2, 'fueVerificado': 1, 'persona': null, 'cliente': 'IMPRENTA OFFSET ANDINA', 'nombreSucursal': 'CENTRAL', 'moneda': 'USD', 'importe': 800.0, 'destino': null, 'horallegada': '${_f(_hoy).substring(0, 10)} 11:40:00', 'tipo': 'Cheque'},
];

// Archivos 97 a 99: uno en uso de la sucursal, uno del responsable y uno en espera.
List<Map<String, dynamic>> _talonariosCajaChica() => [
  {'codTalonario': 1138, 'nroTalonario': 'VCC001', 'numeracionInicial': 1, 'numeracionFinal': 50, 'usados': 5, 'libres': 45, 'ultimoVale': 5, 'siguienteVale': 6, 'activo': true, 'titular': null},
  {'codTalonario': 1187, 'nroTalonario': 'VCC050', 'numeracionInicial': 2451, 'numeracionFinal': 2500, 'usados': 0, 'libres': 50, 'ultimoVale': null, 'siguienteVale': 2451, 'activo': true, 'titular': 'DIEGO SANDRO RUCK TORRICO'},
  {'codTalonario': 1139, 'nroTalonario': 'VCC002', 'numeracionInicial': 51, 'numeracionFinal': 100, 'usados': 0, 'libres': 50, 'ultimoVale': null, 'siguienteVale': 51, 'activo': false, 'titular': null},
];

List<Map<String, dynamic>> _reglasRecibo() => [
  {'reciboObligatorio': true, 'titulo': 'Talonarios de tu sucursal', 'regla': 'El número de recibo es obligatorio: tiene que ser de un talonario en uso y no haberse usado antes. Los que están en espera se habilitan cuando el que está en uso llega a su último recibo, o cuando Talonarios lo devuelve o lo cierra. Un talonario entregado a una persona lo puede usar cualquiera de la sucursal.'},
];

List<Map<String, dynamic>> _cochesDelDia() => [
  {'idCo': 1, 'idCoche': 11, 'placa': '2345-KLM', 'marca': 'Toyota', 'clase': 'Camioneta', 'color': 'Blanco', 'anio': 2019, 'descripcion': 'Hilux de reparto', 'llego': 1, 'obs': null, 'fecha': _f(_hoy), 'idTarRuti': 41, 'quienMarco': 'QUISPE MAMANI RONALDO'},
  {'idCo': 2, 'idCoche': 12, 'placa': '4410-PQR', 'marca': 'Nissan', 'clase': 'Furgón', 'color': 'Gris', 'anio': 2017, 'descripcion': 'Furgón de El Alto', 'llego': null, 'obs': null, 'fecha': null, 'idTarRuti': 41},
  {'idCo': 3, 'idCoche': 13, 'placa': '1188-XYZ', 'marca': 'Suzuki', 'clase': 'Moto', 'color': 'Rojo', 'anio': 2021, 'descripcion': 'Moto de cobranza', 'llego': 0, 'obs': 'En taller por frenos', 'fecha': _f(_hoy), 'idTarRuti': 41, 'quienMarco': 'CASTAÑO ROJAS ANDRÉS'},
];

List<Map<String, dynamic>> _dependientes() => [
  {'codCargo': 158, 'codCargoSucursal': 1580, 'codEmpleadoActual': 180, 'codEmpresa': 1, 'codNivel': 6, 'codSucursal': 1, 'descripcionCargo': 'CAJERO', 'nombreEmpleadoActual': 'QUISPE MAMANI RONALDO', 'nombreSucursal': 'CENTRAL', 'profundidadNivel': 1},
  {'codCargo': 160, 'codCargoSucursal': 1600, 'codEmpleadoActual': 117, 'codEmpresa': 1, 'codNivel': 5, 'codSucursal': 3, 'descripcionCargo': 'RESPONSABLE SUCURSAL', 'nombreEmpleadoActual': 'CHOQUE APAZA FABIOLA', 'nombreSucursal': 'CENTRO SCZ', 'profundidadNivel': 1},
  {'codCargo': 75, 'codCargoSucursal': 750, 'codEmpleadoActual': 28, 'codEmpresa': 1, 'codNivel': 5, 'codSucursal': 2, 'descripcionCargo': 'RESPONSABLE SUCURSAL EL ALTO', 'nombreEmpleadoActual': 'MAMANI TICONA EDWIN', 'nombreSucursal': 'EL ALTO', 'profundidadNivel': 2},
  {'codCargo': 201, 'codCargoSucursal': 2010, 'codEmpleadoActual': 222, 'codEmpresa': 1, 'codNivel': 7, 'codSucursal': 1, 'descripcionCargo': 'CHOFER B', 'nombreEmpleadoActual': 'CASTAÑO ROJAS ANDRÉS', 'nombreSucursal': 'CENTRAL', 'profundidadNivel': 3},
];

/// Qué día revisa la ocurrencia de la 289: el hábil anterior (archivo SQL 58).
Map<String, dynamic> _tesBaseDia() => {
  'fechaTarea': _f(_hoy),
  'fechaRevisada': _f(_dias(-1)),
  'feriado': null,
};

/// Las transferencias del día revisado: una pendiente y una ya cerrada.
List<Map<String, dynamic>> _tesBaseDelDia() => [
  _tesBase()[1],
  {'codTes': 79, 'codCliente': 'C00412', 'datoCliente': 'COMERCIAL LA BELLOTA', 'nombre': 'ESPPAPEL', 'fechaRegistro': _f(_dias(-1)), 'observacion': 'Pasa de caja central a ESP', 'estado': 'CER', 'fechaFinalizacion': _f(_dias(-1))},
];

// Un lote como el de la captura de Marcelo (07/10/2026), con a quién se
// entregó cada egreso (archivo SQL 80). El ingreso no muestra destinatario.
List<Map<String, dynamic>> _cajaChicaLote() {
  var saldo = 200.0;
  Map<String, dynamic> m(int id, int dias, String detalle, double eg, String? a, {int? factura}) {
    saldo -= eg;
    return {'idCC': id, 'idBitTarRuti': 1, 'montoIng': 0.0, 'montoEg': eg, 'saldo': saldo, 'numFactura': factura, 'moneda': 'BS', 'descripcion': detalle, 'fecha': _f(_dias(dias)), 'codSucursal': 3, 'lote': 30, 'audUsuario': 34, 'nombreEmpDestino': a};
  }
  return [
    {'idCC': 1, 'idBitTarRuti': 1, 'montoIng': 200.0, 'montoEg': 0.0, 'saldo': 200.0, 'moneda': 'BS', 'descripcion': 'Ingreso de a Caja Chica automatico', 'fecha': _f(_dias(-20)), 'codSucursal': 3, 'lote': 30, 'audUsuario': 34, 'nombreEmpDestino': 'DIEGO SANDRO RUCK TORRICO'},
    m(2, -20, 'COPIA DE LLAVE MONTACARGAS', 15, 'DIEGO SANDRO RUCK TORRICO'),
    m(3, -19, 'PASAJE ENTREGA DE MATERIAL AL 07, 15 Y 16 DE SEPTIEMBRE', 18, 'JORGE LUIS SACK FERNANDEZ'),
    m(4, -19, 'PASAJE ENTREGA DE MATERIAL AL 25, 26 DE AGOSTO Y DE 01, 03, 09 Y 10 DE SEPTIEMBRE.', 36, 'JAIME MARCELO GUZMAN'),
    m(5, -13, 'RETEN COLCAPIRHUA ENTREGA EDICIONES NUEVO TIEMPO', 3, 'FERNANDO SANTOS SOTO'),
    m(6, -9, 'FLORES PARA MISA', 15, null),
    m(7, -7, 'AGUA PARA RADIADOR 6 LTS', 20, 'FERNANDO SANTOS SOTO', factura: 260230),
  ];
}

/// Verificar Cierre por responsables (archivo SQL 81): lo que le toca a uno.
List<Map<String, dynamic>> _misSecciones() {
  Map<String, dynamic> c(String s, String nombre, int? suc, String sucursal, {String? firmo, String? obs, int conBoton = 1, String? detalle}) => {
    'seccion': s,
    'nombreSeccion': nombre,
    'codSucursal': suc,
    'nombreSucursal': sucursal,
    'fechaRevisada': _f(_hoy.subtract(const Duration(days: 1))),
    'puedeAutorrevisar': 0,
    'idFC': firmo == null ? null : 7,
    'firmadoPor': firmo,
    'fechaFirma': firmo == null ? null : '${_f(_hoy).substring(0, 10)} 09:12:00',
    'obs': obs,
    'conBoton': firmo == null ? conBoton : 0,
    'detalle': firmo == null ? (detalle ?? 'Revísalo y firma.') : null,
  };
  return [
    c('A', 'Arqueos de caja', 20, 'CENTRAL', detalle: 'Hay 2 problema(s) (2 arqueo(s) sin hacer): firma con tu observación.'),
    c('A', 'Arqueos de caja', 22, 'EL ALTO', conBoton: 0, detalle: 'Falta 1 por revisar: se firma sola al terminar.'),
    c('F', 'Caja fuerte', 20, 'CENTRAL', conBoton: 0, detalle: 'Faltan 2 por revisar: se firma sola al terminar.'),
    c('T', 'Traspasos Caja AXA', null, 'Toda la empresa', firmo: 'OSCAR ZABALLA'),
    c('C', 'Cheques', null, 'Toda la empresa'),
    c('R', 'Tareas del día', null, 'Toda la empresa', firmo: 'PAOLA RODRIGO', obs: 'Se avisó a los jefes de área.'),
  ];
}

List<Map<String, dynamic>> _tableroCierre() {
  final filas = <Map<String, dynamic>>[];
  const estados = ['A tiempo', 'A tiempo', 'Tarde', 'Sin firmar'];
  for (var d = 0; d < 4; d++) {
    final dia = _hoy.subtract(Duration(days: d));
    for (final (i, s) in [('A', 'Arqueos de caja', 'CENTRAL'), ('A', 'Arqueos de caja', 'SANTA CRUZ'), ('F', 'Caja fuerte', 'COCHABAMBA'), ('R', 'Tareas del día', 'Toda la empresa')].indexed) {
      final estado = d == 0 ? (i == 3 ? 'A tiempo' : 'Pendiente') : estados[(d + i) % 4];
      final firmo = estado == 'A tiempo' || estado == 'Tarde';
      filas.add({
        'fechaTarea': _f(dia),
        'fechaRevisada': _f(dia.subtract(const Duration(days: 1))),
        'seccion': s.$1,
        'nombreSeccion': s.$2,
        'nombreSucursal': s.$3,
        'estado': estado,
        'firmadoPor': firmo ? (i == 3 ? 'OSCAR ZABALLA' : 'PAOLA RODRIGO') : null,
        'fechaFirma': firmo ? '${_f(dia).substring(0, 10)} ${estado == 'Tarde' ? '23:10' : '10:05'}:00' : null,
        'filas': 3,
        'filasRevisadas': firmo ? 3 : 0,
        'hallazgos': i == 1 ? 2 : 0,
        'obs': i == 1 && firmo ? 'Santa Cruz no hizo el arqueo: la cajera estaba con permiso.' : null,
        'responsables': i == 3 ? 'HANS ANEIVA, OSCAR ZABALLA, PAOLA RODRIGO' : 'HANS ANEIVA, PAOLA RODRIGO',
      });
    }
  }
  return filas;
}

List<Map<String, dynamic>> _resumenCierre() => [
  {'codEmpleado': 139, 'persona': 'PAOLA JANNETH RODRIGO', 'leTocaban': 15, 'hechasATiempo': 9, 'hechasTarde': 2, 'porOtro': 1, 'noHechas': 3, 'pendientes': 3, 'autorrevisadas': 0, 'hallazgos': 4},
  {'codEmpleado': 20, 'persona': 'HANS MARTIN ANEIVA', 'leTocaban': 15, 'hechasATiempo': 0, 'hechasTarde': 0, 'porOtro': 12, 'noHechas': 3, 'pendientes': 3, 'autorrevisadas': 0, 'hallazgos': 0},
  {'codEmpleado': 50, 'persona': 'OSCAR RODOLFO ZABALLA', 'leTocaban': 8, 'hechasATiempo': 4, 'hechasTarde': 0, 'porOtro': 2, 'noHechas': 1, 'pendientes': 1, 'autorrevisadas': 0, 'hallazgos': 0},
];

/// Cargos por revisar (archivo SQL 82), con casos reales del 07/10/2026.
List<Map<String, dynamic>> _senalesCargo() {
  Map<String, dynamic> x(int emp, String persona, String cargo, String desde, String suc, int idTar, String tarea, int deSus, String motivo, {String? ultima, int noAplica = 0}) => {
    'codEmpleado': emp, 'persona': persona, 'cargo': cargo, 'cargoDesde': desde, 'nombreSucursal': suc,
    'idTarRuti': idTar, 'tarea': tarea, 'idFrec': 6, 'ocurrencias': 10, 'noAplica': noAplica,
    'desde': _f(_hoy.subtract(const Duration(days: 12))), 'ultimaHecha': ultima, 'tareasDeLaPersona': deSus,
    'motivo': motivo, 'idSC': null,
  };
  return [
    x(301, 'TOMÁS JARANDILLA', 'RESPONSABLE DE ALMACEN', '2026-02-01 00:00:00', 'ACHOCALLA', 1, 'Arqueo de Caja', 3, 'Dejó de hacerla: la última vez fue el 07/09/2024.', ultima: '2024-09-07 00:00:00'),
    x(301, 'TOMÁS JARANDILLA', 'RESPONSABLE DE ALMACEN', '2026-02-01 00:00:00', 'ACHOCALLA', 30, 'Verificar estado de las instalaciones', 3, 'Dejó de hacerla: la última vez fue el 06/07/2024.', ultima: '2024-07-06 00:00:00'),
    x(301, 'TOMÁS JARANDILLA', 'RESPONSABLE DE ALMACEN', '2026-02-01 00:00:00', 'ACHOCALLA', 31, 'Verificar la limpieza de la Sucursal', 3, 'Dejó de hacerla: la última vez fue el 06/07/2024.', ultima: '2024-07-06 00:00:00'),
    x(302, 'MANUEL ANGEL MAMANI', 'RESPONSABLE DE ALMACEN', '2026-02-01 00:00:00', 'CENTRAL', 1, 'Arqueo de Caja', 6, 'Dejó de hacerla: la última vez fue el 15/10/2022. En CENTRAL la hace RONALDO PEREZ.', ultima: '2022-10-15 00:00:00'),
    x(211, 'DIEGO SANDRO RUCK TORRICO', 'ADMINISTRADOR REGIONAL CBBA', '2022-07-01 00:00:00', 'COCHABAMBA', 154, 'Amortizar en el sistema SAP los cheques que se hayan hecho efectivos.', 20, 'Nunca la hizo.'),
    x(211, 'DIEGO SANDRO RUCK TORRICO', 'ADMINISTRADOR REGIONAL CBBA', '2022-07-01 00:00:00', 'COCHABAMBA', 164, 'Controlar los límites y montos de dinero de saldos en caja.', 20, 'Nunca la hizo.'),
  ];
}

/// Respuestas que pisan a las de siempre en una captura (otro usuario).
final Map<String, Object? Function()> _escenario = {};

/// Diego Ruck (Cochabamba) con UNA celda: caja fuerte de su sucursal.
final _ruck = LoginEntity(
  token: 'x',
  bearer: 'Bearer',
  nombreCompleto: 'RUCK TORRICO DIEGO SANDRO',
  cargo: 'ADMINISTRADOR REGIONAL CBBA',
  tipoUsuario: 'lim',
  codUsuario: 120,
  codEmpleado: 211,
  codEmpresa: 1,
  codCiudad: 3,
  login: 'druck',
  versionApp: '1.0.1',
  codSucursal: 23,
  esAutorizador: 'N',
  estado: 'A',
  audUsuarioI: 34,
  nombreSucursal: 'COCHABAMBA',
  nombreCiudad: 'COCHABAMBA',
  nombreEmpresa: 'IMPEXPAP',
  npassword: '',
  password: '',
  password2: '',
);

Map<String, Object? Function()> _escenarioRuck() {
  var id = 175260;
  Map<String, dynamic> t(String nombre, int idTarRuti, int idATR, {int fueRealizado = 12}) => {
    'idBitTarea': id++,
    'fechaActivo': _f(_hoy),
    'fechaPresentacion': _f(_hoy),
    'idTarRuti': idTarRuti,
    'nombreTareaRutinaria': nombre,
    'codEmpleado': 211,
    'descripCargo': 'ADMINISTRADOR REGIONAL CBBA',
    'fechaCompletado': fueRealizado == 13 ? _f(_hoy) : null,
    'fueRealizado': fueRealizado,
    'obs': null,
    'estado': 1,
    'audUsuario': -1,
    'audFecha': _f(_hoy),
    'idATR': idATR,
    'idFrec': 6,
  };
  final ayer = _f(_hoy.subtract(const Duration(days: 1))).substring(0, 10);
  Map<String, dynamic> l(int idRp, String cliente, String moneda, double importe, String hora, {int verificada = 0}) => {
    'idRp': idRp, 'fueVerificado': verificada, 'persona': 'Diego Ruck', 'cliente': cliente,
    'nombreSucursal': 'COCHABAMBA', 'moneda': moneda, 'importe': importe, 'destino': 'Depósito BCP',
    'horallegada': '$ayer $hora:00', 'tipo': 'Efectivo',
  };
  return {
    '/tareas-rutinarias/obtener-bit-tarea-ruti': () => [
      t('Verificar Cierre de Operaciones', 39, 5),
      t('Arqueo de Caja', 1, 2),
      t('Caja Chica', 42, 7, fueRealizado: 13),
      t('Recepcionar y registrar los depósitos diarios en Bancos', 151, 1),
      t('Recepcionar y registrar las cobranzas diarias ejecutadas por los cobradores', 153, 1),
    ],
    '/tareas-rutinarias/verificar-cierre/mis-secciones': () => [
      {
        'seccion': 'F', 'nombreSeccion': 'Caja fuerte', 'codSucursal': 23, 'nombreSucursal': 'COCHABAMBA',
        'fechaRevisada': _f(_hoy.subtract(const Duration(days: 1))), 'puedeAutorrevisar': 1,
        'idFC': null, 'firmadoPor': null, 'fechaFirma': null, 'obs': null,
        'conBoton': 0, 'detalle': 'Faltan 2 por revisar: se firma sola al terminar.',
      },
    ],
    '/tareas-rutinarias/verificar-cierre/llegadas-de-hoy': () => [
      l(1, 'DISTRIBUIDORA EL VALLE S.R.L.', 'Bs', 12450.0, '10:20', verificada: 1),
      l(2, 'LIBRERÍA LA PAZ CBBA', 'Bs', 3800.0, '12:05'),
      l(3, 'IMPRENTA SAN MARTÍN', 'USD', 600.0, '16:40'),
    ],
  };
}

final Map<String, Object? Function()> _respuestas = {
  '/tareas-rutinarias/senales-cargo/lista': _senalesCargo,
  '/tareas-rutinarias/senales-cargo/de-mi-equipo': () => _senalesCargo().where((x) => x['codEmpleado'] != 211).toList(),
  '/tareas-rutinarias/verificar-cierre/mis-secciones': _misSecciones,
  '/tareas-rutinarias/verificar-cierre/tablero': _tableroCierre,
  '/tareas-rutinarias/verificar-cierre/tablero-resumen': _resumenCierre,
  '/tareas-rutinarias/caja-chica/listar-del-lote': _cajaChicaLote,
  '/tareas-rutinarias/caja-chica/talonarios': _talonariosCajaChica,
  '/tareas-rutinarias/caja-chica/reglas-recibo': _reglasRecibo,
  '/tareas-rutinarias/traspaso-efectivo-tesbase/dia-revisado': _tesBaseDia,
  '/tareas-rutinarias/traspaso-efectivo-tesbase/del-dia': _tesBaseDelDia,
  '/tareas-rutinarias/listar-dependientes-jefe': _dependientes,
  '/tareas-rutinarias/coches/listar-del-dia': _cochesDelDia,
  '/tareas-rutinarias/verificar-cierre/arqueos-de-hoy': _arqueosDeHoy,
  '/tareas-rutinarias/verificar-cierre/llegadas-de-hoy': _llegadasDeHoy,
  '/tareas-rutinarias/obtener-traspaso-mov-caja': _axa,
  '/tareas-rutinarias/obtener-bit-tarea-ruti': _misTareas,
  '/tareas-rutinarias/bitacora/cumplimiento': _bitacora,
  '/tareas-rutinarias/bitacora/generacion': _corridas,
  '/tareas-rutinarias/bitacora/por-que': _porQue,
  '/tareas-rutinarias/traspaso-efectivo-tesbase/pendientes': _tesBase,
  '/tareas-rutinarias/traspaso-entre-sistemas/del-dia': _axa,
  '/tareas-rutinarias/cierre-operaciones/cheques': _cheques,
  '/tareas-rutinarias/cierre-operaciones/tareas-del-dia': _tareasDelDia,
};

final _pedidosSinRespuesta = <String>{};

Future<void> _cargarFuentes() async {
  final dir = Directory('assets/fonts');
  final porFamilia = <String, List<File>>{};
  for (final f in dir.listSync().whereType<File>()) {
    final nombre = f.uri.pathSegments.last;
    if (!nombre.endsWith('.ttf') && !nombre.endsWith('.otf')) continue;
    porFamilia.putIfAbsent(nombre.split('-').first, () => []).add(f);
  }
  for (final e in porFamilia.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  }
  final iconos = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter'}/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (iconos.existsSync()) {
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(iconos.readAsBytesSync()))))
        .load();
  }
}

Future<void> _capturar(
  WidgetTester tester,
  String nombre,
  Widget pantalla, {
  Size tam = const Size(1440, 900),
  // Lo que hay que hacer en la pantalla antes de la foto, como tocar una
  // pestaña.
  Future<void> Function(WidgetTester tester)? antes,
  // Con quién se mira la pantalla: cambia qué paneles se ven.
  LoginEntity? usuario,
}) async {
  tester.view.physicalSize = tam;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final clave = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      // Una llave por captura: sin ella, dos capturas seguidas reusan el
      // mismo contenedor y la segunda muestra los datos de la primera.
      key: ValueKey(nombre),
      overrides: [
        userProvider.overrideWith(
          (ref) => UserStateNotifier.sinStorage(usuario ?? _usuario),
        ),
      ],
      child: RepaintBoundary(
        key: clave,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme().getTheme(),
          home: pantalla,
        ),
      ),
    ),
  );
  Future<void> dejarQueCargue() async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  await dejarQueCargue();
  if (antes != null) {
    await antes(tester);
    await dejarQueCargue();
  }

  await tester.runAsync(() async {
    final boundary =
        clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagen = await boundary.toImage(pixelRatio: 1);
    final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
    File('$_salida/$nombre.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _cargarFuentes();
    dotenv.testLoad(fileInput: 'BASE_URL_DEV=http://capturas.local');
    DioClient.getInstance().interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final datos = _escenario[options.path] ?? _respuestas[options.path];
          if (datos == null) {
            _pedidosSinRespuesta.add(options.path);
            return handler.resolve(
              Response(requestOptions: options, statusCode: 204),
            );
          }
          final valor = datos();
          // {'__status': 403} simula un rechazo del servidor (por ejemplo,
          // quien no es jefe pidiendo "Mi equipo").
          if (valor is Map && valor['__status'] is int) {
            final status = valor['__status'] as int;
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: status,
                  data: {'message': valor['message'] ?? 'Rechazado', 'status': status},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'message': 'ok', 'data': valor, 'status': 200},
            ),
          );
        },
      ),
    );
  });

  tearDownAll(() {
    if (_pedidosSinRespuesta.isNotEmpty) {
      // ignore: avoid_print
      print('Sin datos de ejemplo (respondieron 204): $_pedidosSinRespuesta');
    }
  });

  const escritorio = Size(1440, 900);
  const telefono = Size(412, 900);

  testWidgets('mis tareas', (t) async {
    await _capturar(t, 'mis_tareas_escritorio', const MisTareasRutinariasScreen());
    await _capturar(t, 'mis_tareas_telefono', const MisTareasRutinariasScreen(), tam: telefono);
  });

  testWidgets('bitacora', (t) async {
    await _capturar(t, 'bitacora_escritorio', const BitacoraTareasScreen());
    await _capturar(t, 'bitacora_telefono', const BitacoraTareasScreen(), tam: telefono);
  });

  testWidgets('bitacora generacion', (t) async {
    await _capturar(
      t,
      'bitacora_generacion_escritorio',
      const BitacoraTareasScreen(),
      antes: (t) async {
        await t.tap(find.text('Generación'));
        await t.pump();
      },
    );
  });

  testWidgets('tesbase', (t) async {
    await _capturar(
      t,
      'tesbase_escritorio',
      TraspasoEfectivoTesBaseScreen(idBitTarea: 1, nombreTarea: 'Verificar Traspaso de Efectivo Entre Sistemas', fecha: _hoy),
    );
  });

  testWidgets('caja axa', (t) async {
    await _capturar(
      t,
      'caja_axa_escritorio',
      TraspasoEntreSistemasScreen(idBitTarea: 1, nombreTarea: 'Verificar traspaso Caja AXA contra movimiento de caja', fecha: _hoy),
      tam: escritorio,
    );
  });

  testWidgets('arqueo', (t) async {
    await _capturar(t, 'arqueo_escritorio', const ArqueoCajaScreen(idTarRuti: 1, idBitTarea: 1, nombreTarea: 'Arqueo de Caja'));
  });

  testWidgets('caja chica', (t) async {
    await _capturar(t, 'caja_chica_escritorio', const CajaChicaScreen(nombreTarea: 'Caja Chica'));
    await _capturar(t, 'caja_chica_telefono', const CajaChicaScreen(nombreTarea: 'Caja Chica'), tam: telefono);
  });

  testWidgets('caja chica formulario', (t) async {
    Future<void> abrir(WidgetTester t) => t.tap(find.text('Registrar egreso'));
    await _capturar(t, 'caja_chica_formulario_escritorio', const CajaChicaScreen(nombreTarea: 'Caja Chica'), antes: abrir);
    await _capturar(t, 'caja_chica_formulario_telefono', const CajaChicaScreen(nombreTarea: 'Caja Chica'), tam: telefono, antes: abrir);
  });

  testWidgets('caja fuerte', (t) async {
    await _capturar(t, 'caja_fuerte_escritorio', const CajaFuerteScreen(nombreTarea: 'Kardex Caja Fuerte'));
  });

  testWidgets('coches', (t) async {
    await _capturar(t, 'coches_escritorio', const CochesScreen(nombreTarea: 'Revisión de Autos'));
  });

  testWidgets('cierre', (t) async {
    // Con un administrador: así se ven los cinco paneles de la revisión.
    await _capturar(t, 'cierre_escritorio', const CierreOperacionesScreen(idBitTarea: 1, nombreTarea: 'Cierre de Operaciones'), usuario: _admin);
    await _capturar(t, 'cierre_telefono', const CierreOperacionesScreen(idBitTarea: 1, nombreTarea: 'Cierre de Operaciones'), tam: telefono, usuario: _admin);
  });

  testWidgets('verificar cierre', (t) async {
    await _capturar(t, 'verificar_cierre_escritorio', const CierreOperacionesScreen(idBitTarea: 1, nombreTarea: 'Verificar Cierre de Operaciones', modo: ModoCierre.verificacion), usuario: _admin);
  });

  testWidgets('verificar cierre por responsables', (t) async {
    const pantalla = VerificarCierreScreen(idBitTarea: 1, nombreTarea: 'Verificar Cierre de Operaciones');
    await _capturar(t, 'verificar_responsables_escritorio', pantalla);
    await _capturar(t, 'verificar_responsables_telefono', pantalla, tam: telefono);
    await _capturar(t, 'control_cierre_escritorio', const ControlCierreScreen());
    await _capturar(t, 'control_cierre_telefono', const ControlCierreScreen(), tam: telefono);
  });

  testWidgets('asi lo ve ruck', (t) async {
    _escenario
      ..clear()
      ..addAll(_escenarioRuck());
    addTearDown(_escenario.clear);
    await _capturar(t, 'ruck_mis_tareas', const MisTareasRutinariasScreen(), usuario: _ruck);
    await _capturar(t, 'ruck_mis_tareas_telefono', const MisTareasRutinariasScreen(), tam: telefono, usuario: _ruck);
    const pantalla = VerificarCierreScreen(idBitTarea: 175260, nombreTarea: 'Verificar Cierre de Operaciones');
    await _capturar(t, 'ruck_verificar', pantalla, usuario: _ruck);
    await _capturar(t, 'ruck_verificar_telefono', pantalla, tam: telefono, usuario: _ruck);
  });

  testWidgets('cargos por revisar', (t) async {
    await _capturar(t, 'cargos_por_revisar_escritorio', const CargosPorRevisarScreen(), usuario: _admin, antes: (t) async {
      await t.tap(find.text('TOMÁS JARANDILLA'));
    });
    await _capturar(t, 'cargos_por_revisar_telefono', const CargosPorRevisarScreen(), tam: telefono, usuario: _admin, antes: (t) async {
      await t.tap(find.text('MANUEL ANGEL MAMANI'));
    });
  });

  testWidgets('escenario', (t) async {
    if (_archivoEscenario.isEmpty) return;
    final personas = (jsonDecode(File(_archivoEscenario).readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
    addTearDown(_escenario.clear);
    for (final p in personas) {
      final u = p['usuario'] as Map<String, dynamic>;
      final usuario = LoginEntity(
        token: 'x',
        bearer: 'Bearer',
        nombreCompleto: u['nombreCompleto'] as String,
        cargo: u['cargo'] as String,
        tipoUsuario: 'lim',
        codUsuario: u['codUsuario'] as int,
        codEmpleado: u['codEmpleado'] as int,
        codEmpresa: 1,
        codCiudad: 1,
        login: u['login'] as String,
        versionApp: '1.0.1',
        codSucursal: u['codSucursal'] as int,
        esAutorizador: 'N',
        estado: 'A',
        audUsuarioI: 34,
        nombreSucursal: u['nombreSucursal'] as String,
        nombreCiudad: u['nombreCiudad'] as String,
        nombreEmpresa: 'IMPEXPAP',
        npassword: '',
        password: '',
        password2: '',
      );
      _escenario
        ..clear()
        ..addAll({
          for (final e in (p['respuestas'] as Map<String, dynamic>).entries)
            e.key: () => e.value,
        });
      final nombre = p['nombre'] as String;
      // 'mis_tareas', 'control_cierre', 'responsables_cierre' o
      // 'verificar_cierre:<idBitTarea>'. La
      // de verificar va alta: es larga y se quiere ver entera.
      for (final pantalla in (p['pantallas'] as List?)?.cast<String>() ?? ['mis_tareas']) {
        final (sufijo, widget, alto) = switch (pantalla) {
          'mis_tareas' => ('mis_tareas', const MisTareasRutinariasScreen() as Widget, 900.0),
          'control_cierre' => ('control_cierre', const ControlCierreScreen() as Widget, 1500.0),
          'responsables_cierre' => ('responsables_cierre', const ResponsablesCierreScreen() as Widget, 1100.0),
          _ when pantalla.startsWith('verificar_cierre:') => (
            'verificar_cierre',
            VerificarCierreScreen(
              idBitTarea: int.parse(pantalla.split(':')[1]),
              nombreTarea: 'Verificar Cierre de Operaciones',
            ) as Widget,
            2600.0,
          ),
          // Caja chica con su talonario y el uso de un talonario (archivo 93).
          _ when pantalla.startsWith('caja_chica') => (
            'caja_chica',
            const CajaChicaScreen(nombreTarea: 'Caja Chica') as Widget,
            900.0,
          ),
          _ when pantalla.startsWith('uso_caja_chica:') => (
            'uso_caja_chica',
            Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: UsoEnCajaChica(codTalonario: BigInt.parse(pantalla.split(':')[1])),
              ),
            ) as Widget,
            1100.0,
          ),
          _ => throw ArgumentError('Pantalla desconocida: $pantalla'),
        };
        await _capturar(t, '${nombre}_$sufijo', widget, tam: Size(1440, alto), usuario: usuario);
        await _capturar(t, '${nombre}_${sufijo}_telefono', widget, tam: Size(412, alto * 1.6), usuario: usuario);
        if (sufijo == 'caja_chica') {
          await _capturar(t, '${nombre}_${sufijo}_egreso', widget, tam: Size(412, alto), usuario: usuario,
              antes: (t) async => t.tap(find.text('Registrar egreso')));
        }
        // La matriz también con el diálogo del primer cargo sin secciones.
        if (pantalla == 'responsables_cierre') {
          await _capturar(t, '${nombre}_${sufijo}_agregar', widget, tam: Size(1440, alto), usuario: usuario,
              antes: (t) async {
            await t.tap(find.text('Agregar secciones').first);
            await t.pumpAndSettle();
            await t.tap(find.widgetWithText(ChoiceChip, 'Cheques'));
          });
          // El catálogo de secciones y el formulario de una nueva (archivo 86).
          await _capturar(t, '${nombre}_${sufijo}_secciones', widget, tam: Size(1440, alto), usuario: usuario,
              antes: (t) async {
            await t.tap(find.text('Secciones').first);
          });
          await _capturar(t, '${nombre}_${sufijo}_nueva', widget, tam: Size(1440, alto), usuario: usuario,
              antes: (t) async {
            await t.tap(find.text('Secciones').first);
            await t.pumpAndSettle();
            await t.tap(find.text('Nueva sección'));
          });
          await _capturar(t, '${nombre}_${sufijo}_fuentes', widget, tam: Size(1440, alto), usuario: usuario,
              antes: (t) async {
            await t.tap(find.text('Secciones').first);
            await t.pumpAndSettle();
            await t.tap(find.text('Nueva sección'));
            await t.pumpAndSettle();
            await t.tap(find.byType(DropdownButtonFormField<String>));
          });
          // El registro de fuentes y el alta de una (archivo 87).
          await _capturar(t, '${nombre}_${sufijo}_registro', widget, tam: Size(1440, alto), usuario: usuario,
              antes: (t) async {
            await t.tap(find.text('Secciones').first);
            await t.pumpAndSettle();
            await t.tap(find.text('Fuentes'));
          });
          await _capturar(t, '${nombre}_${sufijo}_registrar', widget, tam: Size(1440, alto), usuario: usuario,
              antes: (t) async {
            await t.tap(find.text('Secciones').first);
            await t.pumpAndSettle();
            await t.tap(find.text('Fuentes'));
            await t.pumpAndSettle();
            await t.tap(find.text('Registrar fuente'));
          });
        }
      }
    }
  });

  testWidgets('dependientes', (t) async {
    await _capturar(t, 'dependientes_escritorio', const DependientesJefeScreen());
  });
}
