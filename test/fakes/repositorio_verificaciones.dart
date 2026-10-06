// Repositorio falso de «Verificar Cheques» para las pruebas y la vista previa.
// No importa flutter_test (lo reusa `tool/vista_previa/verificar_cheques.dart`).
//
// Se porta como el servidor en lo que la pantalla ve: filtra por dia, pagina,
// ordena lo mas reciente primero, saca de los pendientes al cheque que se
// verifica y rechaza lo que el servidor rechaza (cheque ya verificado, cerrado o
// que no existe). Cada llamada queda anotada para que la prueba compruebe lo que
// la pantalla de verdad pidio.
import 'package:bosque_flutter/domain/entities/cheque_pendiente_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/datos_cheque_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/pagina_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/pendientes_verificacion_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_deposito_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_preparada_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_registro_entity.dart';
import 'package:bosque_flutter/domain/repositories/verificaciones_repository.dart';

DateTime _dia(DateTime f) => DateTime(f.year, f.month, f.day);

/// [n] elementos armados por [f]: `repetir(45, (i) => verificacionFalsa(i + 1))`.
List<T> repetir<T>(int n, T Function(int i) f) => [for (var i = 0; i < n; i++) f(i)];

/// La descripcion de una moneda como la da el servidor: «Bs» y «\$us»; un codigo
/// desconocido va tal cual.
String? _descMoneda(String? moneda) => switch (moneda) {
  null => null,
  'BS' => 'Bs',
  'SUS' => r'$us',
  final otra => otra,
};

/// Una verificacion tal como llega del backend. `fila` lo reescribe el
/// repositorio al paginar.
VerificacionFilaEntity verificacionFalsa(
  int codvd, {
  int? codCheque,
  String nroCheque = '',
  double? monto = 1500.5,
  String? moneda = 'BS',
  String banco = 'BANCO UNION',
  String bancoVerificacion = 'BANCO MERCANTIL SANTA CRUZ',
  int codBancoVerificacion = 8,
  DateTime? fechaBanco,
  DateTime? fechaCobranza,
  String estado = 'Y',
  String observacion = '',
  bool chequeCerrado = false,
}) {
  final cod = codCheque ?? 9000 + codvd;
  return VerificacionFilaEntity(
    verificacion: VerificacionDepositoEntity(
      codvd: BigInt.from(codvd),
      codCheque: BigInt.from(cod),
      codBanco: codBancoVerificacion,
      fechaBanco: fechaBanco ?? DateTime(2026, 10, 3),
      observacion: observacion,
      estado: estado,
      audUsuario: null,
      audFecha: null,
    ),
    cheque: DatosChequeVerificacionEntity(
      codCheque: BigInt.from(cod),
      nroCheque: nroCheque.isEmpty ? '${480000 + cod}' : nroCheque,
      montoCheque: monto,
      datoBancoCheque: banco,
      datoEstadoCheque: chequeCerrado ? 'CERRADO' : 'PENDIENTE',
      fechaCobrarCheque: fechaCobranza ?? DateTime(2026, 10, 3),
      chequeCerrado: chequeCerrado,
      moneda: moneda,
      descMoneda: _descMoneda(moneda),
    ),
    datoBanco: bancoVerificacion,
    datoEstado: estado == 'Y' ? 'Valido' : 'Anulado',
    fila: 0,
  );
}

/// Un cheque pendiente de verificar, como lo devuelve `/pendientes`.
ChequePendienteVerificacionEntity pendienteFalso(
  int codCheque, {
  String nroCheque = '',
  double? monto = 2350,
  String? moneda = 'BS',
  String banco = 'BANCO UNION',
  int codBanco = 7,
  DateTime? fechaCobranza,
  bool chequeCerrado = false,
}) => ChequePendienteVerificacionEntity(
  cheque: DatosChequeVerificacionEntity(
    codCheque: BigInt.from(codCheque),
    nroCheque: nroCheque.isEmpty ? '${480000 + codCheque}' : nroCheque,
    montoCheque: monto,
    datoBancoCheque: banco,
    datoEstadoCheque: chequeCerrado ? 'CERRADO' : 'PENDIENTE',
    fechaCobrarCheque: fechaCobranza ?? DateTime(2026, 10, 3),
    chequeCerrado: chequeCerrado,
    moneda: moneda,
    descMoneda: _descMoneda(moneda),
  ),
  codBancoCheque: codBanco,
  fila: 0,
);

class RepositorioVerificacionesFalso implements VerificacionesRepository {
  RepositorioVerificacionesFalso({
    List<VerificacionFilaEntity>? verificaciones,
    List<ChequePendienteVerificacionEntity>? pendientes,
    DateTime? hoy,
  }) : verificaciones = verificaciones ?? [],
       pendientes = pendientes ?? [],
       hoy = hoy ?? DateTime(2026, 10, 3);

  /// Las verificaciones que hay «en la base».
  List<VerificacionFilaEntity> verificaciones;

  /// Los cheques sin verificacion valida.
  List<ChequePendienteVerificacionEntity> pendientes;

  /// El dia del servidor (la fecha que propone `preparar`).
  DateTime hoy;

  /// Nombre de cada banco por codigo, para rotular lo que se guarda (la base
  /// lo resuelve por JOIN). Sin entrada: «BANCO» seguido del codigo.
  Map<int, String> nombresDeBancos = {};

  String _banco(int cod) => nombresDeBancos[cod] ?? 'BANCO $cod';

  List<OpcionChequeEntity> estados = const [
    OpcionChequeEntity(codigo: 'PEN', nombre: 'PENDIENTE'),
    OpcionChequeEntity(codigo: 'CER', nombre: 'CERRADO'),
  ];

  // ── Lo que la pantalla pidio ─────────────────────────────────────────────
  final List<VerificacionFiltroEntity> consultasListar = [];
  final List<PendientesVerificacionFiltroEntity> consultasPendientes = [];
  final List<BigInt> preparados = [];
  final List<VerificacionRegistroEntity> registros = [];
  final List<BigInt> anulados = [];
  int consultasEstados = 0;

  // ── Fallos y retrasos que una prueba puede provocar ─────────────────────
  Object? errorAlListar;
  Object? errorAlListarPendientes;
  Object? errorAlRegistrar;
  Object? errorAlAnular;
  Object? errorEstados;

  /// Si se asigna, `preparar` falla con esto (y no mira los pendientes).
  Object? errorAlPreparar;

  /// Retrasa `listar`: sirve para cruzar dos consultas.
  Future<void> Function(VerificacionFiltroEntity filtro)? antesDeListar;

  String mensajeAnular = 'Verificación anulada.';
  int _siguiente = 5000;

  // ── Lecturas ─────────────────────────────────────────────────────────────

  PaginaVerificacionEntity<T> _pagina<T>(
    List<T> todas,
    int pagina,
    int tamanio,
    T Function(T, int) numerar,
  ) {
    final total = todas.length;
    final paginas = tamanio <= 0 ? 1 : ((total + tamanio - 1) ~/ tamanio).clamp(1, 1 << 30);
    final p = pagina.clamp(1, paginas);
    final desde = (p - 1) * tamanio;
    final hasta = (desde + tamanio).clamp(0, total);
    final filas = <T>[
      for (var i = desde; i < hasta; i++) numerar(todas[i], i + 1),
    ];
    return PaginaVerificacionEntity<T>(
      total: total,
      pagina: p,
      tamanio: tamanio,
      filas: filas,
    );
  }

  @override
  Future<PaginaVerificacionEntity<VerificacionFilaEntity>> listar(
    VerificacionFiltroEntity filtro,
  ) async {
    consultasListar.add(filtro);
    await antesDeListar?.call(filtro);
    if (errorAlListar != null) throw errorAlListar!;
    final dia = filtro.fechaBanco == null ? null : _dia(filtro.fechaBanco!);
    // Lo mas reciente primero (codvd descendente), como el servidor.
    final filtradas =
        verificaciones
            .where(
              (v) =>
                  dia == null ||
                  (v.verificacion.fechaBanco != null &&
                      _dia(v.verificacion.fechaBanco!) == dia),
            )
            .toList()
          ..sort((a, b) => b.codvd.compareTo(a.codvd));
    return _pagina(
      filtradas,
      filtro.pagina,
      filtro.tamanio,
      (v, n) => VerificacionFilaEntity(
        verificacion: v.verificacion,
        cheque: v.cheque,
        datoBanco: v.datoBanco,
        datoEstado: v.datoEstado,
        fila: n,
      ),
    );
  }

  @override
  Future<PaginaVerificacionEntity<ChequePendienteVerificacionEntity>>
  listarPendientes(PendientesVerificacionFiltroEntity filtro) async {
    consultasPendientes.add(filtro);
    if (errorAlListarPendientes != null) throw errorAlListarPendientes!;
    final h = _dia(hoy);
    final filtradas = pendientes.where((p) {
      final c = p.cheque;
      if (filtro.estado != null) {
        final cerrado = filtro.estado == 'CER';
        if (c.chequeCerrado != cerrado) return false;
      }
      final cobranza =
          c.fechaCobrarCheque == null ? null : _dia(c.fechaCobrarCheque!);
      if (cobranza == null) return false;
      return filtro.soloCobranzaHoy ? cobranza == h : !cobranza.isAfter(h);
    }).toList();
    return _pagina(
      filtradas,
      filtro.pagina,
      filtro.tamanio,
      (p, n) => ChequePendienteVerificacionEntity(
        cheque: p.cheque,
        codBancoCheque: p.codBancoCheque,
        fila: n,
      ),
    );
  }

  @override
  Future<VerificacionPreparadaEntity> preparar(BigInt codCheque) async {
    preparados.add(codCheque);
    if (errorAlPreparar != null) throw errorAlPreparar!;
    final p = pendientes.where((x) => x.codCheque == codCheque);
    if (p.isEmpty) {
      throw Exception(
        'El cheque $codCheque ya tiene una verificación válida o no existe. '
        'Actualiza la lista de cheques pendientes.',
      );
    }
    if (p.first.cheque.chequeCerrado) {
      throw Exception(
        'El cheque ${p.first.cheque.nroCheque} está cerrado y no se puede '
        'verificar.',
      );
    }
    return VerificacionPreparadaEntity(cheque: p.first, fechaBanco: _dia(hoy));
  }

  @override
  Future<List<OpcionChequeEntity>> obtenerEstadosCheque() async {
    consultasEstados++;
    if (errorEstados != null) throw errorEstados!;
    return estados;
  }

  // ── Escrituras ───────────────────────────────────────────────────────────

  @override
  Future<BigInt> registrar(VerificacionRegistroEntity registro) async {
    registros.add(registro);
    if (errorAlRegistrar != null) throw errorAlRegistrar!;

    if (registro.esAlta) {
      final p = pendientes.where((x) => x.codCheque == registro.codCheque);
      if (p.isEmpty) {
        throw Exception(
          'El cheque ${registro.codCheque} ya tiene una verificación válida.',
        );
      }
      final c = p.first.cheque;
      final codvd = ++_siguiente;
      verificaciones = [
        ...verificaciones,
        VerificacionFilaEntity(
          verificacion: VerificacionDepositoEntity(
            codvd: BigInt.from(codvd),
            codCheque: registro.codCheque,
            codBanco: registro.codBanco,
            fechaBanco: registro.fechaBanco,
            observacion: registro.observacion,
            estado: 'Y',
            audUsuario: null,
            audFecha: null,
          ),
          cheque: c,
          datoBanco: _banco(registro.codBanco),
          datoEstado: 'Valido',
          fila: 0,
        ),
      ];
      pendientes = [
        for (final x in pendientes)
          if (x.codCheque != registro.codCheque) x,
      ];
      return BigInt.from(codvd);
    }

    final existente = verificaciones.where((v) => v.codvd == registro.codvd);
    if (existente.isEmpty) {
      throw Exception('No se encontró la verificación ${registro.codvd}.');
    }
    final v = existente.first;
    verificaciones = [
      for (final x in verificaciones)
        if (x.codvd != registro.codvd)
          x
        else
          VerificacionFilaEntity(
            verificacion: VerificacionDepositoEntity(
              codvd: v.codvd,
              codCheque: v.codCheque,
              codBanco: registro.codBanco,
              fechaBanco: registro.fechaBanco,
              observacion: registro.observacion,
              // El estado se conserva: una anulada que se edita sigue anulada.
              estado: v.verificacion.estado,
              audUsuario: null,
              audFecha: null,
            ),
            cheque: v.cheque,
            datoBanco: _banco(registro.codBanco),
            datoEstado: v.datoEstado,
            fila: 0,
          ),
    ];
    return registro.codvd;
  }

  @override
  Future<String> anular(BigInt codvd) async {
    anulados.add(codvd);
    if (errorAlAnular != null) throw errorAlAnular!;
    final existente = verificaciones.where((v) => v.codvd == codvd);
    if (existente.isEmpty) {
      throw Exception('No se encontró la verificación $codvd.');
    }
    verificaciones = [
      for (final x in verificaciones)
        if (x.codvd != codvd)
          x
        else
          VerificacionFilaEntity(
            verificacion: VerificacionDepositoEntity(
              codvd: x.codvd,
              codCheque: x.codCheque,
              codBanco: x.verificacion.codBanco,
              fechaBanco: x.verificacion.fechaBanco,
              observacion: x.verificacion.observacion,
              estado: 'N',
              audUsuario: null,
              audFecha: null,
            ),
            cheque: x.cheque,
            datoBanco: x.datoBanco,
            datoEstado: 'Anulado',
            fila: 0,
          ),
    ];
    return mensajeAnular;
  }
}
