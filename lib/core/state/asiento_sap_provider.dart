import 'package:bosque_flutter/data/repositories/asiento_sap_impl.dart';
import 'package:bosque_flutter/domain/entities/asiento_sap_entity.dart';
import 'package:bosque_flutter/domain/repositories/asiento_sap_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final asientoSapRepoProvider = Provider<AsientoSapRepository>(
  (ref) => AsientoSapImpl(),
);

/// Las empresas que se pueden enviar. Sale de la configuración del backend: una empresa
/// nueva aparece aquí sin compilar la app.
final asientoSapEmpresasProvider =
    FutureProvider.autoDispose<List<AsientoSapEmpresaEntity>>(
      (ref) => ref.read(asientoSapRepoProvider).empresas(),
    );

/// Vista previa del asiento de planilla de un periodo y una empresa. No toca SAP.
final asientoSapVistaPreviaProvider = FutureProvider.autoDispose
    .family<AsientoSapEntity?, ({int anio, int mes, int codEmpresa})>((
      ref,
      p,
    ) {
      return ref
          .read(asientoSapRepoProvider)
          .vistaPrevia(anio: p.anio, mes: p.mes, codEmpresa: p.codEmpresa);
    });

/// La configuración de todas las empresas, para su pantalla.
final asientoSapConfigProvider =
    FutureProvider.autoDispose<List<AsientoSapConfigEntity>>(
      (ref) => ref.read(asientoSapRepoProvider).listarConfig(),
    );

/// El mensaje del backend sin el «Exception: » de Dart. No pasa por textoParaUsuario: el
/// motivo exacto (la columna que falta, lo que respondió SAP) es lo que sirve para corregir.
String mensajeAsientoSap(Object e) =>
    e.toString().replaceFirst('Exception: ', '');
