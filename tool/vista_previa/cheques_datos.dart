// Datos de mentira para la vista previa del modulo de Cheques: cheques variados
// (atrasados, que cobran hoy, por cobrar, vigentes, cerrados, de respaldo, en
// dolares, con nombres largos) y el repositorio falso que los sirve.
//
// Va en `tool/` y no en `lib/`: no entra en la app. Reusa el repositorio falso de
// las pruebas (`test/fakes/repositorio_cheques.dart`, que no importa
// flutter_test) y solo cambia los datos.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:bosque_flutter/core/state/actualizar_socios_sap_provider.dart';
import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart'
    show obtenerBancos;
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/models/accion_cheque_model.dart';
import 'package:bosque_flutter/data/models/cheque_fila_model.dart';
import 'package:bosque_flutter/data/models/nota_remision_cheque_model.dart';
import 'package:bosque_flutter/data/models/postergacion_model.dart';
import 'package:bosque_flutter/data/models/transaccion_bancaria_model.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/botones_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/pdf_cheque_estado_entity.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';
import 'package:bosque_flutter/domain/entities/transaccion_bancaria_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';

import '../../test/fakes/repositorio_actualizar_socios_sap.dart';
import '../../test/fakes/repositorio_cheques.dart';

/// «Hoy» de la vista previa. Fijo: la situacion de cobro de cada cheque
/// («Atrasado 12 d», «Cobra hoy») se arma contra este dia y no cambia segun
/// cuando se mire.
final DateTime hoyDeLaVista = DateTime(2026, 10, 3, 9, 30);

String _dia(DateTime f) =>
    '${f.year.toString().padLeft(4, '0')}-'
    '${f.month.toString().padLeft(2, '0')}-'
    '${f.day.toString().padLeft(2, '0')}';

DateTime _hace(int dias) =>
    DateTime(hoyDeLaVista.year, hoyDeLaVista.month, hoyDeLaVista.day - dias);

/// Un cheque tal como llega del backend.
ChequeFilaEntity _cheque(
  int cod, {
  required String cliente,
  required String banco,
  required double monto,
  String estado = 'PEN',
  int? cobraEn,
  bool moneda$us = false,
  String? descTipo = 'PAGO',
  String tipo = 'PAG',
  String? empleado,
  String aOrdenDe = 'BOSQUE SA',
  int recibidoHace = 2,
}) {
  final fechaCheque = _hace(recibidoHace + 3);
  final cobro = cobraEn == null ? null : _hace(-cobraEn);
  return ChequeFilaModel.fromJson({
    'codCheque': cod,
    'nrocheque': '${4800000 + cod * 137}',
    'codCliente': 'C$cod',
    'aOrdenDe': aOrdenDe,
    'fechaCheque': _dia(fechaCheque),
    'fechaCobrar': cobro == null ? null : _dia(cobro),
    'monto': monto,
    'moneda': moneda$us ? 'SUS' : 'BS',
    'tipo': tipo,
    'estado': estado,
    'codBanco': 7,
    'codEmpleado': empleado == null ? 0 : 12,
    'reciboManual': '0',
    'codSucursal': 3,
    'nroRecibo': cod,
    'nroTalonario': '0',
    'codEmpresa': 1,
    'audUsuario': 47,
    'audFecha': '2026-09-30 14:54:51.5670000 +00:00',
    'fechaRecepcion': _dia(_hace(recibidoHace)),
    'datoCliente': cliente,
    'descMoneda': moneda$us ? r'$us' : 'Bs',
    'descTipo': descTipo,
    'descEstado': estado == 'CER' ? 'CERRADO' : 'PENDIENTE',
    'nombreBanco': banco,
    'datoEmpleado':
        empleado == null
            ? ' - Entregado por el Cliente -'
            : ' - $empleado -',
    'observacion': 'Recibido en caja',
    'datoEmpresa': 'IMPEXPAP',
    'fila': 0,
  }).toEntity();
}

/// Las catorce situaciones de la vista previa, de la mas reciente a la mas
/// antigua. Cubre cada situacion de cobro y los casos que estiran el diseno.
List<ChequeFilaEntity> chequesDeLaVista() => [
  _cheque(
    14,
    cliente: 'EDITORA MENDEZ LTDA.',
    banco: 'BANCO UNION',
    monto: 15400.5,
    cobraEn: -12,
    recibidoHace: 0,
  ),
  _cheque(
    13,
    cliente: 'LIBRERIA Y PAPELERIA EL PAIS S.R.L.',
    banco: 'BANCO MERCANTIL SANTA CRUZ',
    monto: 8200,
    cobraEn: 0,
    empleado: 'Rolando Quispe Mamani',
    recibidoHace: 1,
  ),
  _cheque(
    12,
    cliente: 'DISTRIBUIDORA ANDINA DE PAPELES',
    banco: 'BANCO NACIONAL DE BOLIVIA',
    monto: 2350,
    cobraEn: 3,
    moneda$us: true,
    recibidoHace: 1,
  ),
  _cheque(
    11,
    cliente: 'COMERCIAL SANTA CRUZ',
    banco: 'BANCO BISA',
    monto: 640,
    cobraEn: 1,
    recibidoHace: 2,
  ),
  _cheque(
    10,
    cliente: 'IMPRENTA UNIVERSAL',
    banco: 'BANCO GANADERO',
    monto: 12000,
    cobraEn: 25,
    descTipo: null,
    tipo: 'PAG',
    recibidoHace: 3,
  ),
  _cheque(
    9,
    cliente: 'PAPELERA DEL SUR',
    banco: 'BANCO UNION',
    monto: 4500,
    estado: 'CER',
    cobraEn: -10,
    recibidoHace: 6,
  ),
  _cheque(
    8,
    cliente: 'FUNDACION EDUCATIVA ILLIMANI',
    banco: 'BANCO ECONOMICO',
    monto: 800,
    estado: 'CER',
    cobraEn: -20,
    moneda$us: true,
    empleado: 'Marisol Choque Flores',
    recibidoHace: 9,
  ),
  _cheque(
    7,
    cliente: 'GRAFICA ILLIMANI',
    banco: 'BANCO FIE',
    monto: 15000,
    cobraEn: -40,
    moneda$us: true,
    descTipo: 'RESPALDO',
    tipo: 'RES',
    recibidoHace: 45,
  ),
  _cheque(
    6,
    cliente:
        'CORPORACION INDUSTRIAL DE LA PAZ Y AFINES SOCIEDAD ANONIMA - '
        'SUCURSAL EL ALTO',
    banco: 'BANCO BISA',
    monto: 36720.25,
    cobraEn: null,
    recibidoHace: 12,
  ),
  _cheque(
    5,
    cliente: 'LIBRERIA CRISTAL',
    banco: 'BANCO NACIONAL DE BOLIVIA',
    monto: 2200,
    estado: 'CER',
    cobraEn: -30,
    descTipo: 'RESPALDO',
    tipo: 'RES',
    recibidoHace: 20,
  ),
  _cheque(
    4,
    cliente: 'CLIENTE CON UN NOMBRE MUY LARGO S.R.L. SUCURSAL NORTE - CHIQUITOS',
    banco: 'Banco Mercantil Santa Cruz - Cuenta corriente 1234567890',
    monto: 12345678.9,
    cobraEn: -1,
    aOrdenDe: 'BOSQUE INDUSTRIAL DE PAPELES Y AFINES SA',
    empleado: 'Juan Carlos Perez de la Fuente Rodriguez',
    recibidoHace: 14,
  ),
  _cheque(
    3,
    cliente: 'ELECTRO PAPEL S.A.',
    banco: 'BANCO UNION',
    monto: 3150.75,
    cobraEn: 7,
    empleado: 'Marisol Choque Flores',
    recibidoHace: 17,
  ),
  _cheque(
    2,
    cliente: 'COPIAS Y SERVICIOS EL ESTUDIANTE',
    banco: 'BANCO GANADERO',
    monto: 980,
    cobraEn: 8,
    recibidoHace: 20,
  ),
  _cheque(
    1,
    cliente: 'PAPELES Y UTILES BOLIVIA',
    banco: 'BANCO FIE',
    monto: 22000,
    estado: 'CER',
    cobraEn: -45,
    recibidoHace: 33,
  ),
];

/// [total] cheques: los catorce de [chequesDeLaVista] y, si hacen falta mas,
/// copias de ellos con otro codigo, para ver el resumen con varias paginas.
List<ChequeFilaEntity> chequesParaVista(int total) {
  final base = chequesDeLaVista();
  if (total <= base.length) return base.take(total).toList();
  return [
    ...base,
    for (var i = base.length; i < total; i++)
      ChequeFilaModel.fromEntity(base[i % base.length])
          .toEntity()
          .conCodigo(100 + i),
  ];
}

extension on ChequeFilaEntity {
  /// Copia con otro codigo, para repetir un cheque sin repetir su identidad.
  ChequeFilaEntity conCodigo(int cod) {
    final json = ChequeFilaModel.fromEntity(this).toJson();
    json['codCheque'] = cod;
    json['fechaRecepcion'] = _dia(_hace(40 + (cod % 50)));
    return ChequeFilaModel.fromJson(json).toEntity();
  }
}

/// Un PDF de una pagina armado en memoria: lo que «Ver / Descargar» abre en la
/// vista previa, sin servidor ni archivo en disco.
Future<Uint8List> pdfDeEjemploDeCheque(BigInt codCheque) async {
  final doc = pw.Document(title: 'Cheque $codCheque');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build:
          (_) => pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'Cheque $codCheque',
                  style: pw.TextStyle(
                    fontSize: 30,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text('PDF de ejemplo de la vista previa'),
              ],
            ),
          ),
    ),
  );
  return doc.save();
}

/// Lo que la vista previa dice del PDF del cheque cuando hay uno cargado.
final PdfChequeEstadoEntity estadoConPdfDeLaVista = PdfChequeEstadoEntity(
  existe: true,
  nombreArchivo: '14.pdf',
  tamanoBytes: 184320,
  fechaModificacion: DateTime(2026, 10, 3, 9, 22, 10),
);

/// El repositorio falso de las pruebas, con un PDF de verdad al descargar.
class RepositorioChequesDeLaVista extends RepositorioChequesFalso {
  RepositorioChequesDeLaVista() : super(total: 0);

  @override
  Future<Uint8List> descargarPdf(BigInt codCheque) async {
    await super.descargarPdf(codCheque);
    return pdfDeEjemploDeCheque(codCheque);
  }

  @override
  Future<Uint8List> descargarPdfPostergacion(BigInt codPostergacion) async {
    await super.descargarPdfPostergacion(codPostergacion);
    return pdfDeEjemploDeCheque(codPostergacion);
  }
}

// ── Paneles del detalle: notas de remision, transacciones y postergaciones ──

/// El cheque con los tres paneles llenos (el que abre la vista por defecto).
final BigInt chequeConPanelesLlenos = BigInt.from(14);

/// Un cheque con **un** dato en cada panel.
final BigInt chequeConPanelesMinimos = BigInt.from(13);

/// Una postergacion con PDF cargado y su estado, para ver el dialogo de «Descargar».
final BigInt postergacionConPdfDeLaVista = BigInt.from(8002);

/// Una postergacion sin PDF, para ver el dialogo de «Cargar».
final BigInt postergacionSinPdfDeLaVista = BigInt.from(8003);

NotaRemisionChequeEntity _nota(
  int cod,
  String nota,
  int factura,
  int diasAtras,
  int fila,
) => NotaRemisionChequeModel.fromJson({
  'codCheque': cod,
  'notaRemision': nota,
  'nroFactura': factura,
  'fechaFactura': _dia(_hace(diasAtras)),
  'audUsuario': 47,
  'audFecha': '${_dia(_hace(diasAtras))}T09:05:17',
  'fila': fila,
}).toEntity();

TransaccionBancariaEntity _transaccion(
  int cod,
  String nro,
  int codBanco,
  String banco,
  int diasAtras,
  int fila,
) => TransaccionBancariaModel.fromJson({
  'codCheque': cod,
  'nroTransaccion': nro,
  'codBanco': codBanco,
  'fechaTransaccion': _dia(_hace(diasAtras)),
  'datoBanco': banco,
  'fila': fila,
}).toEntity();

PostergacionEntity _postergacion(
  int cod,
  int codCheque,
  int diasAtras,
  String motivo,
  bool? tienePdf,
  int fila,
) => PostergacionModel.fromJson({
  'codPostergacion': cod,
  'codCheque': codCheque,
  'fecha': _dia(_hace(diasAtras)),
  'observacion': motivo,
  'nombreArchivo': '',
  'audUsuario': 47,
  'audFecha': '${_dia(_hace(diasAtras))}T11:42:00',
  'tienePdf': tienePdf,
  'fila': fila,
}).toEntity();

/// Llena los paneles: el cheque 14 con varias filas de cada cosa (una nota
/// repetida, un banco de nombre largo, una postergacion con PDF y dos sin), el 13
/// con una de cada una y el resto sin nada, para ver los estados vacios.
void sembrarPanelesDeLaVista(RepositorioChequesFalso repo) {
  final lleno = chequeConPanelesLlenos.toInt();
  repo.notasPorCheque[chequeConPanelesLlenos] = [
    _nota(lleno, '262211881', 1856, 3, 1),
    _nota(lleno, '262211820', 1795, 9, 2),
    _nota(lleno, '262211820', 1795, 9, 3),
    _nota(lleno, '2922800091', 1801, 14, 4),
  ];
  repo.transaccionesPorCheque[chequeConPanelesLlenos] = [
    _transaccion(lleno, 'TT26216QW3N3', 8, 'BANCO MERCANTIL SANTA CRUZ', 2, 1),
    _transaccion(lleno, '14910211612', 7, 'BANCO UNION', 5, 2),
    _transaccion(
      lleno,
      'TRANSFERENCIA-INTERBANCARIA-0098',
      9,
      'Banco Nacional de Bolivia - Cuenta corriente 1234567890',
      12,
      3,
    ),
  ];
  repo.postergacionesPorCheque[chequeConPanelesLlenos] = [
    _postergacion(
      8001,
      lleno,
      30,
      'Cliente envió carta solicitando postergación hasta el 06 de marzo, '
          'aceptada por la gerencia comercial.',
      false,
      1,
    ),
    _postergacion(
      8002,
      lleno,
      14,
      'Segunda postergación: el cliente aún no cobra a sus clientes.',
      true,
      2,
    ),
    _postergacion(8003, lleno, 3, 'Se espera el depósito del lunes.', false, 3),
  ];
  repo.estadosPdfPostergacion[postergacionConPdfDeLaVista] =
      PdfChequeEstadoEntity(
        existe: true,
        nombreArchivo: '8002.pdf',
        tamanoBytes: 96256,
        fechaModificacion: DateTime(2026, 9, 19, 11, 42, 10),
      );

  final minimo = chequeConPanelesMinimos.toInt();
  repo.notasPorCheque[chequeConPanelesMinimos] = [
    _nota(minimo, '262390321', 321, 7, 1),
  ];
  repo.transaccionesPorCheque[chequeConPanelesMinimos] = [
    _transaccion(minimo, '11070876009', 7, 'BANCO UNION', 4, 1),
  ];
  repo.postergacionesPorCheque[chequeConPanelesMinimos] = [
    _postergacion(
      8010,
      minimo,
      6,
      'Postergado a pedido del ejecutivo comercial.',
      null,
      1,
    ),
  ];
}

/// El repositorio falso con los cheques de la vista y un detalle con todos los
/// estados de accion. [conPdf] decide si los cheques tienen un PDF cargado.
RepositorioChequesFalso repositorioDeLaVista({
  int total = 14,
  bool conPdf = true,
}) {
  final repo = RepositorioChequesDeLaVista();
  repo.estadoPdfDeTodos =
      conPdf ? estadoConPdfDeLaVista : PdfChequeEstadoEntity.sinArchivo;
  sembrarPanelesDeLaVista(repo);
  repo.cheques = chequesParaVista(total);
  repo.botones = const BotonesChequeEntity(
    fechaCobro: false,
    devolver: true,
    cerrarConVerificacion: false,
    cerrarSinVerificacion: true,
    codigo: '0101',
  );
  repo.alObtenerDetalle = (cod) async {
    final fila = repo.cheques.firstWhere(
      (c) => c.codCheque == cod,
      orElse: () => repo.cheques.first,
    );
    const pasos = <(String, String, int?, String?, String?)>[
      ('REC', 'RECIBIDO', null, 'Recibido en caja', null),
      ('TRASP', 'TRASPASO', null, null, null),
      ('CUS', 'A COBRANZA', 12, 'Entregado al cobrador', null),
      ('DEV', 'DEVUELTO', 0, 'El banco pidio otra firma', null),
      (
        'VEN',
        'VENCIDO-POSTERGADO',
        0,
        'Nueva Fecha de Cobro = 15/10/2026 . ',
        null,
      ),
      ('CUS', 'A COBRANZA', 12, 'Entregado al cobrador', null),
    ];
    final cerrado = fila.estaCerrado;
    return ChequeDetalleEntity(
      cheque: fila,
      acciones: [
        for (final (i, p) in pasos.indexed)
          AccionChequeModel.fromJson({
            'codAccion': fila.codCheque.toInt() * 10 + i,
            'codCheque': fila.codCheque.toInt(),
            'fecha': '2026-09-${20 + i}T${(8 + i).toString().padLeft(2, '0')}:30:00',
            'estado': p.$1,
            'codEmpleado': p.$3,
            'nroSAP': null,
            'observacion': p.$4,
            'audUsuario': 47,
            'audFecha': '2026-09-${20 + i}T${(8 + i).toString().padLeft(2, '0')}:30:00',
            'descripcion': p.$2,
            'nro': i + 1,
          }).toEntity(),
        if (cerrado)
          AccionChequeModel.fromJson({
            'codAccion': fila.codCheque.toInt() * 10 + 9,
            'codCheque': fila.codCheque.toInt(),
            'fecha': '2026-09-30T11:15:00',
            'estado': 'COB',
            'codEmpleado': 0,
            'nroSAP': 'SAP-48213',
            'observacion': 'Cobrado en ventanilla',
            'audUsuario': 47,
            'audFecha': '2026-09-30T11:15:00',
            'descripcion': 'COBRADO',
            'nro': pasos.length + 1,
          }).toEntity(),
      ],
      botones: cerrado ? BotonesChequeEntity.ninguno : repo.botones,
    );
  };
  return repo;
}

/// El login de la vista previa: un administrador, sin pasar por el servidor.
LoginEntity loginDeLaVista() => LoginEntity.fromJson(<String, dynamic>{
  'tipoUsuario': 'ROLE_ADM',
  'codUsuario': 34,
  'codEmpresa': 1,
  'nombreEmpresa': 'IMPEXPAP',
});

/// Lo que la pantalla necesita en lugar del backend: el repositorio, el reloj
/// fijo, los permisos de administrador, la sesion y los bancos.
List<Override> overridesDeLaVista({
  int total = 14,
  bool conPdf = true,
  PermisosCheque permisos = const PermisosCheque(botones: <String>{}, esAdmin: true),
}) => [
  chequesRepositoryProvider.overrideWithValue(
    repositorioDeLaVista(total: total, conPdf: conPdf),
  ),
  relojChequesProvider.overrideWithValue(() => hoyDeLaVista),
  permisosChequeProvider.overrideWithValue(permisos),
  actualizarSociosSapRepositoryProvider.overrideWithValue(sociosSapDeLaVista()),
  userProvider.overrideWith(
    (ref) => UserStateNotifier.sinStorage(loginDeLaVista()),
  ),
  obtenerBancos.overrideWith(
    (ref) async => [
      BancoEntity(codBanco: 7, nombre: 'BANCO UNION', audUsuario: 1, fila: 1),
      BancoEntity(
        codBanco: 8,
        nombre: 'BANCO MERCANTIL SANTA CRUZ',
        audUsuario: 1,
        fila: 2,
      ),
    ],
  ),
];

/// «Actualizar datos SAP» de mentira. El parametro de la URL `sap` elige lo que
/// responde: `ok` (por defecto: la frase de exito, sin numero), `error` (SAP sin
/// responder) o `lento` (se queda en «Actualizando…»).
RepositorioActualizarSociosSapFalso sociosSapDeLaVista() {
  final repo = RepositorioActualizarSociosSapFalso();
  switch (Uri.base.queryParameters['sap']) {
    case 'error':
      repo.error =
          'No se pudieron traer los clientes de SAP. Lo más probable es que el '
          'servidor de SAP no esté respondiendo en este momento. Intenta de '
          'nuevo en unos minutos y, si el error se repite, avisa a Sistemas.';
    case 'lento':
      repo.esperar = Completer<void>();
  }
  return repo;
}
