import 'package:bosque_flutter/domain/entities/hora_traspaso_cheque_entity.dart';

/// HoraAccionDto de `/cheque/traspaso/horas`: `{ codAccion, hora }`.
///
/// Lectura tolerante: una columna nula no tumba la lista (con ella, la
/// reimpresion entera).
class HoraTraspasoChequeModel {
  final int codAccion;
  final String hora;

  const HoraTraspasoChequeModel({required this.codAccion, required this.hora});

  factory HoraTraspasoChequeModel.fromJson(Map<String, dynamic> json) =>
      HoraTraspasoChequeModel(
        codAccion: (json['codAccion'] as num?)?.toInt() ?? 0,
        hora: (json['hora'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'codAccion': codAccion, 'hora': hora};

  HoraTraspasoChequeEntity toEntity() =>
      HoraTraspasoChequeEntity(codAccion: codAccion, hora: hora);

  factory HoraTraspasoChequeModel.fromEntity(HoraTraspasoChequeEntity e) =>
      HoraTraspasoChequeModel(codAccion: e.codAccion, hora: e.hora);
}
