import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';

/// Columnas de `p_list_thex_Comida` L y V. `toJson` manda solo los parámetros de
/// `p_abm_thex_Comida`, sin auditoría; la ventana horaria es opcional.
class HexComidaModel {
  const HexComidaModel(this.entidad);

  final HexComidaEntity entidad;

  factory HexComidaModel.fromJson(Map<String, dynamic> j) => HexComidaModel(
    HexComidaEntity(
      idComida: hexBigInt(j['idComida']),
      codigo: hexTexto(j['codigo']),
      leyenda: hexTexto(j['leyenda']),
      codigoDoble: hexTexto(j['codigoDoble']),
      leyendaDoble: hexTexto(j['leyendaDoble']),
      horaDesde: hexHoraN(j['horaDesde']),
      horaHasta: hexHoraN(j['horaHasta']),
      monto: hexDecimalN(j['monto']),
      montoDoble: hexDecimalN(j['montoDoble']),
      activo: hexBool(j['activo']),
      orden: hexIntN(j['orden']),
      vigenteDesde: hexFecha(j['vigenteDesde']),
      vigenteHasta: hexFecha(j['vigenteHasta']),
      audUsuario: hexBigInt(j['audUsuario']),
      audFecha: hexFecha(j['audFecha']),
      esVigente: hexBool(j['esVigente']),
      estadoVigencia: hexTextoN(j['estadoVigencia']),
      textoVigencia: hexTextoN(j['textoVigencia']),
      // Sin la columna (SP anterior a D40) rige la doble, como el SP.
      conDoble: j['conDoble'] == null ? true : hexBool(j['conDoble']),
      minutosSimple: hexIntN(j['minutosSimple']),
      minutosDoble: hexIntN(j['minutosDoble']),
      textoDuracion: hexTextoN(j['textoDuracion']),
    ),
  );

  factory HexComidaModel.fromEntity(HexComidaEntity e) => HexComidaModel(e);

  HexComidaEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => hexCuerpo({
    'idComida': entidad.idComida,
    'codigo': entidad.codigo,
    'leyenda': entidad.leyenda,
    'codigoDoble': entidad.codigoDoble,
    'leyendaDoble': entidad.leyendaDoble,
    'horaDesde': hexHoraN(entidad.horaDesde),
    'horaHasta': hexHoraN(entidad.horaHasta),
    'monto': entidad.monto,
    'montoDoble': entidad.montoDoble,
    'activo': entidad.activo,
    'orden': entidad.orden,
    'vigenteDesde': hexDiaJson(entidad.vigenteDesde),
    'conDoble': entidad.conDoble,
    'minutosSimple': entidad.minutosSimple,
    'minutosDoble': entidad.minutosDoble,
  });
}
