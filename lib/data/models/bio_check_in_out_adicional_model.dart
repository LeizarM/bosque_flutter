import 'package:bosque_flutter/domain/entities/bio_check_in_out_adicional_entity.dart';

/// Origen: tabla `dbo.tbio_bioCHECKINOUTAdicinal`, via
/// `p_list_BioCHECKINOUTAdicinal`.
class BioCheckInOutAdicionalModel {
  final int userId;
  final DateTime? checkTime;
  final int codEmpleado;
  final String fechaString;
  final int audUsuario;
  final DateTime? audFecha;

  const BioCheckInOutAdicionalModel({
    required this.userId,
    this.checkTime,
    required this.codEmpleado,
    required this.fechaString,
    required this.audUsuario,
    this.audFecha,
  });

  factory BioCheckInOutAdicionalModel.fromJson(Map<String, dynamic> json) =>
      BioCheckInOutAdicionalModel(
        userId: json['USERID'] ?? 0,
        checkTime:
            json['CHECKTIME'] != null
                ? DateTime.tryParse(json['CHECKTIME'])
                : null,
        codEmpleado: json['CODEMPLEADO'] ?? 0,
        fechaString: json['fechaString'] ?? '',
        audUsuario: json['audUsuario'] ?? 0,
        audFecha:
            json['audFecha'] != null
                ? DateTime.tryParse(json['audFecha'])
                : null,
      );

  factory BioCheckInOutAdicionalModel.fromEntity(
    BioCheckInOutAdicionalEntity e,
  ) => BioCheckInOutAdicionalModel(
    userId: e.userId,
    checkTime: e.checkTime,
    codEmpleado: e.codEmpleado,
    fechaString: e.fechaString,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
  );

  Map<String, dynamic> toJson() => {
    'USERID': userId,
    'CHECKTIME': checkTime?.toIso8601String(),
    'CODEMPLEADO': codEmpleado,
    'fechaString': fechaString,
    'audUsuario': audUsuario,
  };

  BioCheckInOutAdicionalEntity toEntity() => BioCheckInOutAdicionalEntity(
    userId: userId,
    checkTime: checkTime,
    codEmpleado: codEmpleado,
    fechaString: fechaString,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}
