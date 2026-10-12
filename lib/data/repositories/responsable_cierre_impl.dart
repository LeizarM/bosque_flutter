// Destino final: lib/data/repositories/responsable_cierre_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/responsable_cierre_model.dart';
import 'package:bosque_flutter/domain/entities/responsable_cierre_entity.dart';
import 'package:bosque_flutter/domain/repositories/responsable_cierre_repository.dart';

class ResponsableCierreImpl extends BaseApiRepository
    implements ResponsableCierreRepository {
  @override
  Future<List<ResponsableCierre>> lista(int idTarRuti) => postAndReturnList(
    endpoint: AppConstants.tarCierreResponsablesLista,
    data: {'idTarRuti': idTarRuti},
    fromJson: ResponsableCierreModel.fila,
  );

  @override
  Future<List<CandidatoCierre>> candidatos(int idTarRuti) => postAndReturnList(
    endpoint: AppConstants.tarCierreResponsablesCandidatos,
    data: {'idTarRuti': idTarRuti},
    fromJson: ResponsableCierreModel.candidato,
  );

  @override
  Future<List<SucursalCaja>> sucursales() => postAndReturnList(
    endpoint: AppConstants.tarCierreResponsablesSucursales,
    data: const <String, dynamic>{},
    fromJson: ResponsableCierreModel.sucursal,
  );

  @override
  Future<void> agregar({
    required int idTarRuti,
    required String seccion,
    int? codSucursal,
    int? codCargoSucursal,
    int? codEmpleado,
    bool puedeAutorrevisar = false,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.tarCierreResponsablesAgregar,
      data: {
        'idTarRuti': idTarRuti,
        'seccion': seccion,
        'codSucursal': codSucursal,
        'codCargoSucursal': codCargoSucursal,
        'codEmpleado': codEmpleado,
        'puedeAutorrevisar': puedeAutorrevisar ? 1 : 0,
      },
      errorMessage: 'No se pudo agregar.',
    );
  }

  @override
  Future<void> cambiarAutorrevision(ResponsableCierre f, bool puede) async {
    await postAndReturnId(
      endpoint: AppConstants.tarCierreResponsablesCambiar,
      data: {
        'idRC': f.idRC,
        'idTarRuti': f.idTarRuti,
        'seccion': f.codigoSeccion,
        'codSucursal': f.codSucursal,
        'codCargoSucursal': f.codCargoSucursal,
        'codEmpleado': f.codEmpleado,
        'puedeAutorrevisar': puede ? 1 : 0,
      },
      errorMessage: 'No se pudo guardar.',
    );
  }

  @override
  Future<List<SeccionCierre>> secciones(int idTarRuti) => postAndReturnList(
    endpoint: AppConstants.tarCierreSecciones,
    data: {'idTarRuti': idTarRuti},
    fromJson: ResponsableCierreModel.seccion,
  );

  @override
  Future<List<FuenteCierre>> fuentes() => postAndReturnList(
    endpoint: AppConstants.tarCierreFuentes,
    data: const <String, dynamic>{},
    fromJson: ResponsableCierreModel.fuente,
  );

  @override
  Future<void> guardarSeccion({
    String? codigo,
    required String nombre,
    String? queRevisar,
    bool? porSucursal,
    String? fuente,
    bool? marcaPorFila,
    bool? firmaSola,
    int? obsDesde,
    String? diaRevisado,
    int? orden,
  }) async {
    final id = await postAndReturnId(
      endpoint: AppConstants.tarCierreGuardarSeccion,
      data: {
        'seccion': codigo,
        'nombre': nombre,
        'queRevisar': queRevisar,
        if (porSucursal != null) 'porSucursal': porSucursal ? 1 : 0,
        'fuente': fuente,
        if (marcaPorFila != null) 'marcaPorFila': marcaPorFila ? 1 : 0,
        if (firmaSola != null) 'firmaSola': firmaSola ? 1 : 0,
        'obsDesde': obsDesde,
        'diaRevisado': diaRevisado,
        'orden': orden,
      },
      errorMessage: 'No se pudo guardar la sección.',
    );
    _exigirScript(id);
  }

  @override
  Future<void> quitarSeccion(String codigo, {required bool quitar}) async {
    final id = await postAndReturnId(
      endpoint: AppConstants.tarCierreQuitarSeccion,
      data: {'seccion': codigo, 'estado': quitar ? 0 : 1},
      errorMessage: 'No se pudo cambiar la sección.',
    );
    _exigirScript(id);
  }

  @override
  Future<List<FuenteCierre>> fuentesTodas() => postAndReturnList(
    endpoint: AppConstants.tarCierreFuentesTodas,
    data: const <String, dynamic>{},
    fromJson: ResponsableCierreModel.fuente,
  );

  @override
  Future<List<CandidatoFuente>> candidatasFuente() => postAndReturnList(
    endpoint: AppConstants.tarCierreFuentesCandidatas,
    data: const <String, dynamic>{},
    fromJson: ResponsableCierreModel.candidatoFuente,
  );

  @override
  Future<void> guardarFuente({
    required String fuente,
    required String nombre,
    String? descripcion,
    String? spMarcar,
  }) async {
    final id = await postAndReturnId(
      endpoint: AppConstants.tarCierreGuardarFuente,
      data: {
        'fuente': fuente,
        'nombre': nombre,
        'descripcion': descripcion,
        'spMarcar': spMarcar,
      },
      errorMessage: 'No se pudo guardar la fuente.',
    );
    _exigirScript(id, 87);
  }

  @override
  Future<void> activarFuente(String fuente, {required bool activa}) async {
    final id = await postAndReturnId(
      endpoint: AppConstants.tarCierreEstadoFuente,
      data: {'fuente': fuente, 'estado': activa ? 1 : 0},
      errorMessage: 'No se pudo cambiar la fuente.',
    );
    _exigirScript(id, 87);
  }

  @override
  Future<void> borrarFuente(String fuente) async {
    final id = await postAndReturnId(
      endpoint: AppConstants.tarCierreBorrarFuente,
      data: {'fuente': fuente},
      errorMessage: 'No se pudo borrar la fuente.',
    );
    _exigirScript(id, 87);
  }

  /// Un SP sin las ramas nuevas contesta "bien" con 0: falta el script.
  void _exigirScript(BigInt id, [int numero = 86]) {
    if (id <= BigInt.zero) {
      throw Exception('Falta correr el script $numero en la base.');
    }
  }

  @override
  Future<void> quitar(int idRC) async {
    await postAndReturnId(
      endpoint: AppConstants.tarCierreResponsablesQuitar,
      data: {'idRC': idRC},
      errorMessage: 'No se pudo quitar.',
    );
  }
}
