import 'package:bosque_flutter/domain/entities/banco_registro_entity.dart';

/// Cuerpo de `/banco/registrar`. Solo de ida: el backend responde el codigo.
///
/// La lectura de bancos sigue en `BancoModel`, que ademas lleva `fila`, un
/// campo de pantalla que aqui no tiene sentido.
class BancoRegistroModel {
  final BancoRegistroEntity registro;

  const BancoRegistroModel._(this.registro);

  factory BancoRegistroModel.fromEntity(BancoRegistroEntity e) =>
      BancoRegistroModel._(e);

  Map<String, dynamic> toJson() => {
    'codBanco': registro.codBanco,
    'nombre': registro.nombre.trim(),
  };
}
