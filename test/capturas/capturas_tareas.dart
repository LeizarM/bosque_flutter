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
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/presentation/screens/screens.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

List<Map<String, dynamic>> _cochesDelDia() => [
  {'idCo': 1, 'idCoche': 11, 'placa': '2345-KLM', 'marca': 'Toyota', 'clase': 'Camioneta', 'color': 'Blanco', 'anio': 2019, 'descripcion': 'Hilux de reparto', 'llego': 1, 'obs': null, 'fecha': _f(_hoy), 'idTarRuti': 41, 'idBitTarRuti': 1},
  {'idCo': 2, 'idCoche': 12, 'placa': '4410-PQR', 'marca': 'Nissan', 'clase': 'Furgón', 'color': 'Gris', 'anio': 2017, 'descripcion': 'Furgón de El Alto', 'llego': null, 'obs': null, 'fecha': _f(_hoy), 'idTarRuti': 41, 'idBitTarRuti': 1},
  {'idCo': 3, 'idCoche': 13, 'placa': '1188-XYZ', 'marca': 'Suzuki', 'clase': 'Moto', 'color': 'Rojo', 'anio': 2021, 'descripcion': 'Moto de cobranza', 'llego': 0, 'obs': 'En taller por frenos', 'fecha': _f(_hoy), 'idTarRuti': 41, 'idBitTarRuti': 1},
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

final Map<String, Object? Function()> _respuestas = {
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
          final datos = _respuestas[options.path];
          if (datos == null) {
            _pedidosSinRespuesta.add(options.path);
            return handler.resolve(
              Response(requestOptions: options, statusCode: 204),
            );
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'message': 'ok', 'data': datos(), 'status': 200},
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
    await _capturar(t, 'caja_chica_escritorio', const CajaChicaScreen(idBitTarea: 1, nombreTarea: 'Caja Chica'));
  });

  testWidgets('caja fuerte', (t) async {
    await _capturar(t, 'caja_fuerte_escritorio', const CajaFuerteScreen(idTarRuti: 40, idBitTarea: 1, nombreTarea: 'Kardex Caja Fuerte'));
  });

  testWidgets('coches', (t) async {
    await _capturar(t, 'coches_escritorio', const CochesScreen(idTarRuti: 41, idBitTarea: 1, nombreTarea: 'Revisión de Autos'));
  });

  testWidgets('cierre', (t) async {
    // Con un administrador: así se ven los cinco paneles de la revisión.
    await _capturar(t, 'cierre_escritorio', const CierreOperacionesScreen(idBitTarea: 1, nombreTarea: 'Cierre de Operaciones'), usuario: _admin);
    await _capturar(t, 'cierre_telefono', const CierreOperacionesScreen(idBitTarea: 1, nombreTarea: 'Cierre de Operaciones'), tam: telefono, usuario: _admin);
  });

  testWidgets('verificar cierre', (t) async {
    await _capturar(t, 'verificar_cierre_escritorio', const CierreOperacionesScreen(idBitTarea: 1, nombreTarea: 'Verificar Cierre de Operaciones', modo: ModoCierre.verificacion), usuario: _admin);
  });

  testWidgets('dependientes', (t) async {
    await _capturar(t, 'dependientes_escritorio', const DependientesJefeScreen());
  });
}
