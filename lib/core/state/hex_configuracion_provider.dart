import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/data/repositories/hex_configuracion_impl.dart';
import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_configuracion_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_encargado_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_clave_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_rama_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_mapa_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_configuracion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';

/// Repositorio de configuración. Las pruebas lo cambian con `overrideWithValue`.
final hexConfiguracionRepositoryProvider = Provider<HexConfiguracionRepository>(
  (ref) => HexConfiguracionImpl(),
);

/// Todas las vigencias, la actual y las pasadas o futuras.
final hexParametrosProvider =
    FutureProvider.autoDispose<List<HexParametroEntity>>(
      (ref) => ref.watch(hexConfiguracionRepositoryProvider).parametros(),
    );

/// El catálogo de claves (D33): de él salen los avisos de obligatorios sin
/// valor vigente.
final hexParametroCatalogoProvider = FutureProvider.autoDispose<
  List<HexParametroClaveEntity>
>((ref) => ref.watch(hexConfiguracionRepositoryProvider).catalogoParametros());

final hexTramosProvider = FutureProvider.autoDispose<List<HexTramoEntity>>(
  (ref) => ref.watch(hexConfiguracionRepositoryProvider).tramos(),
);

/// El día 00–24 h de los tres tipos de día hoy. Se invalida junto con
/// [hexTramosProvider] tras escribir un tramo.
final hexTramoMapaProvider =
    FutureProvider.autoDispose<List<HexTramoMapaEntity>>(
      (ref) => ref.watch(hexConfiguracionRepositoryProvider).mapaTramos(),
    );

/// Una simulación de jornada; se pide recién al tocar «Simular».
final hexSimulacionProvider = FutureProvider.autoDispose
    .family<HexSimulacionEntity, FiltroSimulacionHex>(
      (ref, f) => ref
          .watch(hexConfiguracionRepositoryProvider)
          .simularJornada(
            codEmpleado: f.codEmpleado,
            fechaJornada: f.fechaJornada,
            inicio: f.inicio,
            fin: f.fin,
          ),
    );

final hexComidasProvider = FutureProvider.autoDispose<List<HexComidaEntity>>(
  (ref) => ref.watch(hexConfiguracionRepositoryProvider).comidas(),
);

final hexAprobadoresProvider = FutureProvider.autoDispose
    .family<List<HexAprobadorEntity>, FiltroAprobadoresHex>(
      (ref, f) => ref
          .watch(hexConfiguracionRepositoryProvider)
          .aprobadores(codEmpleado: f.codEmpleado, nivel: f.nivel),
    );

/// La rama de un aprobador (D34): se pide recién al abrir «Ver rama».
final hexRamaAprobadorProvider = FutureProvider.autoDispose
    .family<List<HexRamaEmpleadoEntity>, BigInt>(
      (ref, codEmpleado) => ref
          .watch(hexConfiguracionRepositoryProvider)
          .ramaAprobador(codEmpleado),
    );

/// Los encargados para elegir al asignar un jefe de área (D35): se piden
/// recién al abrir la pestaña Jefe de área del diálogo.
final hexEncargadosParaJefeProvider = FutureProvider.autoDispose<
  List<HexEncargadoOpcionEntity>
>((ref) => ref.watch(hexConfiguracionRepositoryProvider).encargadosParaJefe());

/// Una página de la bitácora de configuración (D22). Tras una escritura se
/// invalida la familia entera: el cambio cae en la primera página.
final hexHistorialConfiguracionProvider = FutureProvider.autoDispose
    .family<PaginaHex<HexConfiguracionEventoEntity>, FiltroHistorialHex>(
      (ref, f) => ref.watch(hexConfiguracionRepositoryProvider).historial(f),
    );
