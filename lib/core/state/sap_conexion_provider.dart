import 'package:bosque_flutter/data/repositories/sap_conexion_impl.dart';
import 'package:bosque_flutter/domain/entities/sap_conexion_entity.dart';
import 'package:bosque_flutter/domain/repositories/sap_conexion_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sapConexionRepoProvider = Provider<SapConexionRepository>(
  (ref) => SapConexionImpl(),
);

/// Todas las conexiones a SAP, para Administración > Conexiones SAP.
final sapConexionesProvider = FutureProvider.autoDispose<List<SapConexionEntity>>(
  (ref) => ref.read(sapConexionRepoProvider).listar(),
);

/// El mensaje del backend sin el «Exception: » de Dart: el motivo exacto (lo que respondió SAP,
/// el módulo que la usa) es lo que sirve para corregir.
String mensajeSapConexion(Object e) => e.toString().replaceFirst('Exception: ', '');
