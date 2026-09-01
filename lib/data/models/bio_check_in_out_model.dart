import 'package:bosque_flutter/domain/entities/bio_check_in_out_entity.dart';

/// Origen: tabla `dbo.tbio_bioCHECKINOUT`, via `p_list_BioCHECKINOUT`.
///
/// Los nombres de columna en el JSON vienen tal cual del backend (mayusculas
/// heredadas del dispositivo biometrico) — no se renombran aca.
class BioCheckInOutModel {
  final int userId;
  final DateTime? checkTime;
  final String checkType;
  final int? verifyCode;
  final String sensorId;
  final String memoInfo;
  final String workCode;
  final String sn;
  final int? userExtFmt;
  final String fechaString;

  const BioCheckInOutModel({
    required this.userId,
    this.checkTime,
    required this.checkType,
    this.verifyCode,
    required this.sensorId,
    required this.memoInfo,
    required this.workCode,
    required this.sn,
    this.userExtFmt,
    required this.fechaString,
  });

  factory BioCheckInOutModel.fromJson(Map<String, dynamic> json) =>
      BioCheckInOutModel(
        userId: json['USERID'] ?? 0,
        checkTime:
            json['CHECKTIME'] != null
                ? DateTime.tryParse(json['CHECKTIME'])
                : null,
        checkType: json['CHECKTYPE'] ?? '',
        verifyCode: json['VERIFYCODE'],
        sensorId: json['SENSORID'] ?? '',
        memoInfo: json['Memoinfo'] ?? '',
        workCode: json['WorkCode'] ?? '',
        sn: json['sn'] ?? '',
        userExtFmt: json['UserExtFmt'],
        fechaString: json['fechaString'] ?? '',
      );

  factory BioCheckInOutModel.fromEntity(BioCheckInOutEntity e) =>
      BioCheckInOutModel(
        userId: e.userId,
        checkTime: e.checkTime,
        checkType: e.checkType,
        verifyCode: e.verifyCode,
        sensorId: e.sensorId,
        memoInfo: e.memoInfo,
        workCode: e.workCode,
        sn: e.sn,
        userExtFmt: e.userExtFmt,
        fechaString: e.fechaString,
      );

  Map<String, dynamic> toJson() => {
    'USERID': userId,
    'CHECKTIME': checkTime?.toIso8601String(),
    'CHECKTYPE': checkType,
    'VERIFYCODE': verifyCode,
    'SENSORID': sensorId,
    'Memoinfo': memoInfo,
    'WorkCode': workCode,
    'sn': sn,
    'UserExtFmt': userExtFmt,
    'fechaString': fechaString,
  };

  BioCheckInOutEntity toEntity() => BioCheckInOutEntity(
    userId: userId,
    checkTime: checkTime,
    checkType: checkType,
    verifyCode: verifyCode,
    sensorId: sensorId,
    memoInfo: memoInfo,
    workCode: workCode,
    sn: sn,
    userExtFmt: userExtFmt,
    fechaString: fechaString,
  );
}
