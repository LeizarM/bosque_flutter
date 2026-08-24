import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/comision_dinamica_model.dart';
import 'package:bosque_flutter/data/models/comision_por_rango_model.dart';
import 'package:bosque_flutter/data/models/grupo_comision_model.dart';
import 'package:bosque_flutter/data/models/grupo_x_vendedor_model.dart';
import 'package:bosque_flutter/data/models/estado_periodo_model.dart';
import 'package:bosque_flutter/data/models/nota_pendiente_model.dart';
import 'package:bosque_flutter/data/models/tipo_cambio_comision_model.dart';
import 'package:bosque_flutter/data/models/nota_preliminar_model.dart';
import 'package:bosque_flutter/data/models/pagado_item_model.dart';
import 'package:bosque_flutter/data/models/politica_bond_model.dart';
import 'package:bosque_flutter/domain/entities/politica_bond_entity.dart';
import 'package:bosque_flutter/data/models/preliminar_comision_model.dart';
import 'package:bosque_flutter/data/models/vendedor_comision_model.dart';
import 'package:bosque_flutter/domain/entities/comision_dinamica_entity.dart';
import 'package:bosque_flutter/domain/entities/comision_por_rango_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_x_vendedor_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_periodo_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_pendiente_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cambio_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_preliminar_entity.dart';
import 'package:bosque_flutter/domain/entities/pagado_item_entity.dart';
import 'package:bosque_flutter/domain/entities/preliminar_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/vendedor_comision_entity.dart';
import 'package:bosque_flutter/data/models/sincronizacion_notas_model.dart';
import 'package:bosque_flutter/domain/repositories/comisiones_repository.dart';

/// Implementacion del modulo de Comisiones contra el backend Spring.
///
/// Todos los endpoints son POST, incluidas las lecturas, siguiendo la
/// convencion del backend. Los helpers de BaseApiRepository ya resuelven el
/// envelope {message, data, status} y tratan el 204 como lista vacia.
class ComisionesImpl extends BaseApiRepository implements ComisionesRepository {
  // ---------- Grupos ----------

  @override
  Future<BigInt> registrarGrupo(GrupoComisionEntity grupo) async {
    return postAndReturnId(
      endpoint: AppConstants.comRegistrarGrupo,
      data: GrupoComisionModel.fromEntity(grupo).toJson(),
    );
  }

  @override
  Future<BigInt> eliminarGrupo(GrupoComisionEntity grupo) async {
    return postAndReturnId(
      endpoint: AppConstants.comEliminarGrupo,
      data: GrupoComisionModel.fromEntity(grupo).toJson(),
    );
  }

  @override
  Future<List<GrupoComisionEntity>> obtenerGrupos({BigInt? idGrupo}) async {
    final modelos = await postAndReturnList<GrupoComisionModel>(
      endpoint: AppConstants.comObtenerGrupos,
      data: {'id': (idGrupo ?? BigInt.zero).toInt()},
      fromJson: GrupoComisionModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<GrupoComisionEntity>> obtenerGruposAsignables(
    BigInt idVendedor,
  ) async {
    final modelos = await postAndReturnList<GrupoComisionModel>(
      endpoint: AppConstants.comObtenerGruposAsignables,
      data: {'id': idVendedor.toInt()},
      fromJson: GrupoComisionModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<GrupoComisionEntity>> obtenerGruposTodos() async {
    final modelos = await postAndReturnList<GrupoComisionModel>(
      endpoint: AppConstants.comObtenerGruposTodos,
      fromJson: GrupoComisionModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  // ---------- Vendedores ----------

  @override
  Future<BigInt> registrarVendedor(VendedorComisionEntity vendedor) async {
    return postAndReturnId(
      endpoint: AppConstants.comRegistrarVendedor,
      data: VendedorComisionModel.fromEntity(vendedor).toJson(),
    );
  }

  @override
  Future<BigInt> eliminarVendedor(VendedorComisionEntity vendedor) async {
    return postAndReturnId(
      endpoint: AppConstants.comEliminarVendedor,
      data: VendedorComisionModel.fromEntity(vendedor).toJson(),
    );
  }

  @override
  Future<List<VendedorComisionEntity>> obtenerVendedores({
    BigInt? idVendedor,
  }) async {
    final modelos = await postAndReturnList<VendedorComisionModel>(
      endpoint: AppConstants.comObtenerVendedores,
      data: {'id': (idVendedor ?? BigInt.zero).toInt()},
      fromJson: VendedorComisionModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<VendedorComisionEntity>> obtenerVendedoresPorEmpresa(
    int bd,
  ) async {
    final modelos = await postAndReturnList<VendedorComisionModel>(
      endpoint: AppConstants.comObtenerVendedoresEmpresa,
      data: {'bd': bd},
      fromJson: VendedorComisionModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<VendedorComisionEntity>> obtenerVendedoresTodos() async {
    final modelos = await postAndReturnList<VendedorComisionModel>(
      endpoint: AppConstants.comObtenerVendedoresTodos,
      fromJson: VendedorComisionModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  // ---------- Asignacion grupo / vendedor ----------

  @override
  Future<BigInt> registrarGrupoVendedor(GrupoXVendedorEntity asignacion) async {
    return postAndReturnId(
      endpoint: AppConstants.comRegistrarGrupoVendedor,
      data: GrupoXVendedorModel.fromEntity(asignacion).toJson(),
    );
  }

  @override
  Future<BigInt> eliminarGrupoVendedor(GrupoXVendedorEntity asignacion) async {
    return postAndReturnId(
      endpoint: AppConstants.comEliminarGrupoVendedor,
      data: GrupoXVendedorModel.fromEntity(asignacion).toJson(),
    );
  }

  @override
  Future<List<GrupoXVendedorEntity>> obtenerGruposPorVendedor(
    BigInt idVendedor,
  ) async {
    final modelos = await postAndReturnList<GrupoXVendedorModel>(
      endpoint: AppConstants.comObtenerGruposVendedor,
      data: {'id': idVendedor.toInt()},
      fromJson: GrupoXVendedorModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<GrupoXVendedorEntity>> obtenerAsignacionesVigentes() async {
    final modelos = await postAndReturnList<GrupoXVendedorModel>(
      endpoint: AppConstants.comObtenerAsignacionesVigentes,
      fromJson: GrupoXVendedorModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  // ---------- Comision dinamica ----------

  @override
  Future<BigInt> registrarComisionDinamica(
    ComisionDinamicaEntity escala,
  ) async {
    return postAndReturnId(
      endpoint: AppConstants.comRegistrarComisionDinamica,
      data: ComisionDinamicaModel.fromEntity(escala).toJson(),
    );
  }

  @override
  Future<BigInt> eliminarComisionDinamica(ComisionDinamicaEntity escala) async {
    return postAndReturnId(
      endpoint: AppConstants.comEliminarComisionDinamica,
      data: ComisionDinamicaModel.fromEntity(escala).toJson(),
    );
  }

  @override
  Future<List<ComisionDinamicaEntity>> obtenerComisionesDinamicas({
    int? esInterno,
  }) async {
    final modelos = await postAndReturnList<ComisionDinamicaModel>(
      endpoint: AppConstants.comObtenerComisionesDinamicas,
      data: {'esInterno': esInterno},
      fromJson: ComisionDinamicaModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ComisionDinamicaEntity>> obtenerComisionesDinamicasVigentes({
    int? esInterno,
    DateTime? fecha,
  }) async {
    final modelos = await postAndReturnList<ComisionDinamicaModel>(
      endpoint: AppConstants.comObtenerComisionesDinamicasVigentes,
      data: {
        'esInterno': esInterno,
        'fecha': fecha?.toIso8601String().substring(0, 19).replaceAll('T', ' '),
      },
      fromJson: ComisionDinamicaModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }
  // ---------- Vistas preliminares ----------

  @override
  Future<List<PreliminarComisionEntity>> preliminarInterno({
    required int mes,
    required int anio,
    required double tc,
  }) => _preliminar(AppConstants.comPreliminarInterno, mes, anio, tc);

  @override
  Future<List<PreliminarComisionEntity>> preliminarExterno({
    required int mes,
    required int anio,
    required double tc,
  }) => _preliminar(AppConstants.comPreliminarExterno, mes, anio, tc);

  @override
  Future<List<PreliminarComisionEntity>> preliminarDinamicaAnterior({
    required int mes,
    required int anio,
    required double tc,
  }) => _preliminar(AppConstants.comPreliminarDinamicaAnterior, mes, anio, tc);

  @override
  Future<List<PreliminarComisionEntity>> preliminarDinamicaVigente({
    required int mes,
    required int anio,
    required double tc,
  }) => _preliminar(AppConstants.comPreliminarDinamicaVigente, mes, anio, tc);

  @override
  Future<List<NotaPreliminarEntity>> notasDeFila({
    required int idVendedor,
    required int mes,
    required int anio,
    required double comision,
    required String modalidad,
  }) async {
    final modelos = await postAndReturnList<NotaPreliminarModel>(
      endpoint: AppConstants.comNotasPreliminar,
      data: {
        'idVendedor': idVendedor,
        'mes': mes,
        'anio': anio,
        'comision': comision,
        'modalidad': modalidad,
      },
      fromJson: NotaPreliminarModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  // ---------- Items congelados al ejecutar el pago ----------

  @override
  Future<List<PagadoItemEntity>> obtenerItemsPagados({
    required int mes,
    required int anio,
    required int esInterno,
    int? idPagado,
    int? docNum,
    String? origen,
  }) async {
    final modelos = await postAndReturnList<PagadoItemModel>(
      // La accion va en la ruta, como en obtenerDescuentoDetalle: es el mismo
      // SP con dos formas de salida y el backend enruta por ahi.
      endpoint: '${AppConstants.comItemsPagados}/L',
      data: {
        'mes': mes,
        'anio': anio,
        'esInterno': esInterno,
        // Los tres opcionales los declara el SP como NULL por defecto y los
        // filtra con (@x IS NULL OR ...), asi que null NO es un caso
        // degenerado: es «sin ese filtro».
        'idPagado': idPagado,
        'docNum': docNum,
        'origen': origen,
        // Se manda 0 EXPLICITO, y no se omite la clave: @soloExcluidos es
        // INT con default 0, pero el default solo rige si el parametro no
        // viaja. Si el DTO manda la clave en null, el SP recibe NULL y la
        // condicion (@soloExcluidos = 0 OR aplicaDescuento = 0) se vuelve
        // UNKNOWN en su primera mitad: devolveria SOLO lo excluido, en
        // silencio. El filtro por exclusion se hace en pantalla.
        'soloExcluidos': 0,
      },
      fromJson: PagadoItemModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<PagadoItemResumenEntity>> obtenerResumenItemsPagados({
    required int mes,
    required int anio,
    required int esInterno,
    int? idPagado,
    int? docNum,
    String? origen,
  }) async {
    final modelos = await postAndReturnList<PagadoItemResumenModel>(
      endpoint: '${AppConstants.comItemsPagados}/R',
      data: {
        'mes': mes,
        'anio': anio,
        'esInterno': esInterno,
        'idPagado': idPagado,
        // Los mismos dos filtros de nota que el listado. El SP los aplica en
        // las dos ramas, y es lo que impide que el titular cuente el mes
        // entero mientras la lista muestra una sola nota.
        'docNum': docNum,
        'origen': origen,
        // A proposito NO se manda soloExcluidos: el resumen tiene que contar
        // las dos mitades para que «excluido» signifique algo.
      },
      fromJson: PagadoItemResumenModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<PagadoItemCorteEntity>> obtenerCorteItemsPagados({
    int? mes,
    int? anio,
    int? esInterno,
  }) async {
    final modelos = await postAndReturnList<PagadoItemCorteModel>(
      endpoint: AppConstants.comItemsPagadosCorte,
      // Los tres van nulos cuando se quiere el historico completo: el SP los
      // declara NULL por defecto y filtra con (@x IS NULL OR ...).
      data: {'mes': mes, 'anio': anio, 'esInterno': esInterno},
      fromJson: PagadoItemCorteModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  // ---------- Politica del descuento por familia ----------

  @override
  Future<List<DescuentoDetalleEntity>> obtenerDescuentoDetalle({
    required String accion,
    int? mes,
    int? anio,
    String? origen,
    int? idVendedor,
  }) async {
    final m = await postAndReturnList<DescuentoDetalleModel>(
      endpoint: '${AppConstants.comDescuentoDetalle}/$accion',
      data: {
        'mes': mes,
        'anio': anio,
        'origen': origen,
        'idVendedor': idVendedor,
      },
      fromJson: DescuentoDetalleModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<List<FamiliaSapOpcionEntity>> obtenerFamiliasSap({
    bool soloDisponibles = false,
  }) async {
    final m = await postAndReturnList<FamiliaSapOpcionModel>(
      endpoint:
          soloDisponibles
              ? AppConstants.comPoliticaFamiliasDisponibles
              : AppConstants.comPoliticaFamiliasSap,
      fromJson: FamiliaSapOpcionModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<List<FamiliaPoliticaEntity>> obtenerPoliticaFamilias() async {
    final m = await postAndReturnList<FamiliaPoliticaModel>(
      endpoint: AppConstants.comPoliticaFamilias,
      fromJson: FamiliaPoliticaModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<List<FamiliaPoliticaEntity>> obtenerPoliticaFamiliasVigentes() async {
    final m = await postAndReturnList<FamiliaPoliticaModel>(
      endpoint: AppConstants.comPoliticaFamiliasVigentes,
      fromJson: FamiliaPoliticaModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<BigInt> guardarPoliticaFamilia(
    FamiliaPoliticaEntity mb,
    int codUsuario,
  ) => postAndReturnId(
    endpoint: AppConstants.comRegistrarPoliticaFamilia,
    data: FamiliaPoliticaModel.fromEntity(mb, codUsuario).toJson(),
  );

  @override
  Future<BigInt> eliminarPoliticaFamilia(
    FamiliaPoliticaEntity mb,
    int codUsuario,
  ) => postAndReturnId(
    endpoint: AppConstants.comEliminarPoliticaFamilia,
    data: FamiliaPoliticaModel.fromEntity(mb, codUsuario).toJson(),
  );

  @override
  Future<List<VendedorExentoEntity>> obtenerVendedoresExentos() async {
    final m = await postAndReturnList<VendedorExentoModel>(
      endpoint: AppConstants.comPoliticaExentos,
      fromJson: VendedorExentoModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<BigInt> guardarVendedorExento(
    VendedorExentoEntity mb,
    int codUsuario,
  ) => postAndReturnId(
    endpoint: AppConstants.comRegistrarPoliticaExento,
    data: VendedorExentoModel.fromEntity(mb, codUsuario).toJson(),
  );

  @override
  Future<BigInt> eliminarVendedorExento(
    VendedorExentoEntity mb,
    int codUsuario,
  ) => postAndReturnId(
    endpoint: AppConstants.comEliminarPoliticaExento,
    data: VendedorExentoModel.fromEntity(mb, codUsuario).toJson(),
  );

  @override
  Future<List<ClienteExcluidoEntity>> obtenerClientesExcluidos() async {
    final m = await postAndReturnList<ClienteExcluidoModel>(
      endpoint: AppConstants.comPoliticaClientesExcluidos,
      fromJson: ClienteExcluidoModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<BigInt> guardarClienteExcluido(
    ClienteExcluidoEntity mb,
    int codUsuario,
  ) => postAndReturnId(
    endpoint: AppConstants.comRegistrarPoliticaCliente,
    data: ClienteExcluidoModel.fromEntity(mb, codUsuario).toJson(),
  );

  @override
  Future<BigInt> eliminarClienteExcluido(
    ClienteExcluidoEntity mb,
    int codUsuario,
  ) => postAndReturnId(
    endpoint: AppConstants.comEliminarPoliticaCliente,
    data: ClienteExcluidoModel.fromEntity(mb, codUsuario).toJson(),
  );

  /// Las cuatro ramas comparten forma de peticion y de respuesta.
  Future<List<PreliminarComisionEntity>> _preliminar(
    String endpoint,
    int mes,
    int anio,
    double tc,
  ) async {
    final modelos = await postAndReturnList<PreliminarComisionModel>(
      endpoint: endpoint,
      data: {'mes': mes, 'anio': anio, 'tc': tc},
      fromJson: PreliminarComisionModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }
  // ---------- Carga y ejecucion del periodo ----------

  @override
  Future<bool> sincronizarNotas() async {
    // Como estadoPeriodo: el endpoint devuelve una lista de una fila.
    final modelos = await postAndReturnList<SincronizacionNotasModel>(
      endpoint: AppConstants.comSincronizarNotas,
      data: const {},
      fromJson: SincronizacionNotasModel.fromJson,
    );
    return modelos.isNotEmpty && modelos.first.sincronizado;
  }

  @override
  Future<EstadoPeriodoEntity?> obtenerEstadoPeriodo({
    required int mes,
    required int anio,
    required int esInterno,
  }) async {
    // El endpoint responde con una lista de una fila, no con un objeto: el
    // controller usa procesarLista para mantener el mismo contrato que el resto
    // de las lecturas del modulo.
    final modelos = await postAndReturnList<EstadoPeriodoModel>(
      endpoint: AppConstants.comEstadoPeriodo,
      data: {'mes': mes, 'anio': anio, 'esInterno': esInterno},
      fromJson: EstadoPeriodoModel.fromJson,
    );
    return modelos.isEmpty ? null : modelos.first.toEntity();
  }

  @override
  Future<BigInt> cargarNotas({
    required int mes,
    required int anio,
    required int esInterno,
    required int audUsuario,
  }) async {
    return postAndReturnId(
      endpoint: AppConstants.comCargarNotas,
      data: {
        'mes': mes,
        'anio': anio,
        'esInterno': esInterno,
        'audUsuario': audUsuario,
      },
    );
  }

  @override
  Future<BigInt> ejecutarPago({
    required int mes,
    required int anio,
    required int esInterno,
    required int audUsuario,
  }) async {
    return postAndReturnId(
      endpoint: AppConstants.comEjecutarPago,
      data: {
        'mes': mes,
        'anio': anio,
        'esInterno': esInterno,
        'audUsuario': audUsuario,
      },
    );
  }
  // ---------- Notas pendientes ----------

  @override
  Future<List<NotaPendienteEntity>> obtenerNotasPendientes() async {
    final modelos = await postAndReturnList<NotaPendienteModel>(
      endpoint: AppConstants.comNotasPendientes,
      fromJson: NotaPendienteModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  // ---------- Tipo de cambio ----------

  @override
  Future<TipoCambioComisionEntity> obtenerTipoCambio({DateTime? fecha}) async {
    final modelos = await postAndReturnList<TipoCambioComisionModel>(
      endpoint: AppConstants.comObtenerTipoCambio,
      // La clave es fechaDesde porque el backend reutiliza ReporteComisionDto.
      // Sin fecha, el SP devuelve el vigente, que es el caso normal.
      data: {
        if (fecha != null)
          'fechaDesde': DateTime(
            fecha.year,
            fecha.month,
            fecha.day,
          ).toIso8601String().substring(0, 10),
      },
      fromJson: TipoCambioComisionModel.fromJson,
    );
    // El SP siempre devuelve una fila; si no llegara nada, el valor oficial.
    return modelos.isEmpty
        ? const TipoCambioComisionEntity(
          fecha: null,
          tipoCambio: 6.96,
          origen: 'POR DEFECTO',
          diasDeAntiguedad: null,
        )
        : modelos.first.toEntity();
  }

  // ---------- Reportes ----------

  @override
  Future<Uint8List> reportePagadasInternas({
    required int mes,
    required int anio,
  }) => _pdfPeriodo(AppConstants.comRptPagadasInternas, mes, anio);

  @override
  Future<Uint8List> reportePagadasExternas({
    required int mes,
    required int anio,
  }) => _pdfPeriodo(AppConstants.comRptPagadasExternas, mes, anio);

  @override
  Future<Uint8List> reporteImportaciones({
    required int mes,
    required int anio,
  }) => _pdfPeriodo(AppConstants.comRptImportaciones, mes, anio);

  @override
  Future<Uint8List> reportePagadasEpp({required int mes, required int anio}) =>
      _pdfPeriodo(AppConstants.comRptPagadasEpp, mes, anio);

  @override
  Future<Uint8List> reporteNotasPendientes() => DioClient.descargarReportePdf(
    endpoint: AppConstants.comRptNotasPendientes,
    data: const {},
  );

  @override
  Future<Uint8List> reportePorVendedor({
    required DateTime desde,
    required DateTime hasta,
  }) => DioClient.descargarReportePdf(
    endpoint: AppConstants.comRptPorVendedor,
    data: {'fechaDesde': _fecha(desde), 'fechaHasta': _fecha(hasta)},
  );

  Future<Uint8List> _pdfPeriodo(String endpoint, int mes, int anio) =>
      DioClient.descargarReportePdf(
        endpoint: endpoint,
        data: {'mes': mes, 'anio': anio},
      );

  static String _fecha(DateTime f) =>
      f.toIso8601String().substring(0, 19).replaceAll('T', ' ');
  // ---------- Comision por rango de dias ----------

  @override
  Future<List<ComisionPorRangoEntity>> obtenerRangosComision() async {
    final modelos = await postAndReturnList<ComisionPorRangoModel>(
      endpoint: AppConstants.comObtenerRangosComision,
      fromJson: ComisionPorRangoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BigInt> registrarRangoComision(ComisionPorRangoEntity rango) async {
    return postAndReturnId(
      endpoint: AppConstants.comRegistrarRangoComision,
      data: ComisionPorRangoModel.fromEntity(rango).toJson(),
    );
  }

  @override
  Future<BigInt> eliminarRangoComision(ComisionPorRangoEntity rango) async {
    return postAndReturnId(
      endpoint: AppConstants.comEliminarRangoComision,
      data: ComisionPorRangoModel.fromEntity(rango).toJson(),
    );
  }
}
