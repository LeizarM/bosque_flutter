import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/ciudad_model.dart';
import 'package:bosque_flutter/data/models/pais_model.dart';
import 'package:bosque_flutter/data/models/resultado_escritura_model.dart';
import 'package:bosque_flutter/data/models/zona_model.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/pais_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';
import 'package:bosque_flutter/domain/repositories/ubicacion_geografica_repository.dart';

/// Ubicación geográfica contra el backend. Los textos de éxito y de error los
/// redactan `p_abm_Pais`, `p_abm_Ciudad` y `p_abm_Zona`.
class UbicacionGeograficaImpl extends BaseApiRepository
    implements UbicacionGeograficaRepository {
  @override
  Future<List<PaisEntity>> listarPaises() async {
    final m = await postAndReturnList<PaisModel>(
      endpoint: AppConstants.ubicacionPaisesListar,
      fromJson: PaisModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<List<CiudadEntity>> listarCiudades() async {
    final m = await postAndReturnList<CiudadModel>(
      endpoint: AppConstants.ubicacionCiudadesListar,
      data: const {'id': 0},
      fromJson: CiudadModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<List<ZonaEntity>> listarZonas() async {
    final m = await postAndReturnList<ZonaModel>(
      endpoint: AppConstants.ubicacionZonasListar,
      data: const {'id': 0},
      fromJson: ZonaModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<ResultadoEscrituraEntity> registrarPais(PaisEntity pais) => _escribir(
    AppConstants.ubicacionPaisesRegistrar,
    PaisModel.fromEntity(pais).toJson(),
  );

  @override
  Future<ResultadoEscrituraEntity> registrarCiudad(CiudadEntity ciudad) =>
      _escribir(
        AppConstants.ubicacionCiudadesRegistrar,
        CiudadModel.fromEntity(ciudad).toJson(),
      );

  @override
  Future<ResultadoEscrituraEntity> registrarZona(ZonaEntity zona) => _escribir(
    AppConstants.ubicacionZonasRegistrar,
    ZonaModel.fromEntity(zona).toJson(),
  );

  @override
  Future<ResultadoEscrituraEntity> eliminarPais(int codPais) =>
      _escribir(AppConstants.ubicacionPaisesEliminar, {'id': codPais});

  @override
  Future<ResultadoEscrituraEntity> eliminarCiudad(int codCiudad) =>
      _escribir(AppConstants.ubicacionCiudadesEliminar, {'id': codCiudad});

  @override
  Future<ResultadoEscrituraEntity> eliminarZona(int codZona) =>
      _escribir(AppConstants.ubicacionZonasEliminar, {'id': codZona});

  Future<ResultadoEscrituraEntity> _escribir(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final modelo = await postAndReturnFullResponse<ResultadoEscrituraModel>(
      endpoint: endpoint,
      data: data,
      fromJson: ResultadoEscrituraModel.fromJson,
    );
    return modelo.toEntity();
  }
}
