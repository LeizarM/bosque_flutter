import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/data/repositories/hex_reporte_impl.dart';
import 'package:bosque_flutter/data/repositories/hex_ubicacion_impl.dart';
import 'package:bosque_flutter/domain/entities/hex_jornada_pasada_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_leyenda_codigos_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_linea_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_tramo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_requisito_marca_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_roles_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_vista_marcacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_ubicacion_repository.dart';

/// Repositorio de reportes. Las pruebas lo cambian con `overrideWithValue`.
final hexReporteRepositoryProvider = Provider<HexReporteRepository>(
  (ref) => HexReporteImpl(),
);

/// Ubicación del teléfono para marcar; una sola instancia, que recuerda un
/// permiso negado para siempre. Las pruebas la cambian por una falsa.
final hexUbicacionProvider = Provider<UbicacionHex>(
  (ref) => GeolocatorUbicacionHex(),
);

/// Tramos y comidas vigentes hoy; nulo si el SP no devolvió ninguno.
final hexLeyendaCodigosProvider =
    FutureProvider.autoDispose<HexLeyendaCodigosEntity?>(
      (ref) => ref.watch(hexReporteRepositoryProvider).leyendaCodigos(),
    );

/// Requisitos para marcar en la app; lista vacía si el SP respondió 204. La
/// app no decide con esto: solo muestra y el SP vuelve a validar al marcar.
final hexRequisitosMarcaProvider =
    FutureProvider.autoDispose<List<HexRequisitoMarcaEntity>>(
      (ref) => ref.watch(hexReporteRepositoryProvider).requisitosMarca(),
    );

/// D37: si «Mis horas extras» está habilitada y qué teclas valen; nulo si el
/// SP respondió 204. Se recarga al abrir la pantalla y después de marcar.
final hexReporteHoyProvider =
    FutureProvider.autoDispose<HexVistaMarcacionEntity?>(
      (ref) => ref.watch(hexReporteRepositoryProvider).hoy(),
    );

final hexMisRolesProvider = FutureProvider.autoDispose<HexRolesEntity?>(
  (ref) => ref.watch(hexReporteRepositoryProvider).misRoles(),
);

final hexMisReportesProvider = FutureProvider.autoDispose
    .family<PaginaHex<HexReporteEntity>, FiltroReportesHex>(
      (ref, f) => ref.watch(hexReporteRepositoryProvider).misReportes(f),
    );

final hexBandejaEncargadoProvider = FutureProvider.autoDispose
    .family<PaginaHex<HexReporteEntity>, FiltroReportesHex>(
      (ref, f) => ref.watch(hexReporteRepositoryProvider).bandejaEncargado(f),
    );

/// D43: jornadas pasadas que el actor puede registrar; vacía si el SP
/// respondió 204. Con filas, la revisión muestra el botón de crear.
final hexJornadasPasadasProvider =
    FutureProvider.autoDispose<List<HexJornadaPasadaEntity>>(
      (ref) => ref.watch(hexReporteRepositoryProvider).jornadasPasadas(),
    );

final hexBandejaJefeProvider = FutureProvider.autoDispose
    .family<PaginaHex<HexReporteEntity>, FiltroReportesHex>(
      (ref, f) => ref.watch(hexReporteRepositoryProvider).bandejaJefe(f),
    );

/// D45: la bandeja de solo lectura del observador (todos los estados).
final hexBandejaObservadorProvider = FutureProvider.autoDispose
    .family<PaginaHex<HexReporteEntity>, FiltroReportesHex>(
      (ref, f) => ref.watch(hexReporteRepositoryProvider).bandejaObservador(f),
    );

/// Nulo si el reporte no existe o no es del usuario (el SP responde 204).
final hexDetalleReporteProvider = FutureProvider.autoDispose
    .family<HexReporteEntity?, BigInt>(
      (ref, id) => ref.watch(hexReporteRepositoryProvider).detalle(id),
    );

final hexLineasReporteProvider = FutureProvider.autoDispose
    .family<List<HexReporteLineaEntity>, BigInt>(
      (ref, id) => ref.watch(hexReporteRepositoryProvider).lineas(id),
    );

/// Los tramos de tiempo del reporte (D36), como los arma el SP.
final hexTramosReporteProvider = FutureProvider.autoDispose
    .family<List<HexReporteTramoEntity>, BigInt>(
      (ref, id) => ref.watch(hexReporteRepositoryProvider).tramos(id),
    );

final hexHistorialReporteProvider = FutureProvider.autoDispose
    .family<List<HexReporteEventoEntity>, BigInt>(
      (ref, id) => ref.watch(hexReporteRepositoryProvider).historial(id),
    );
