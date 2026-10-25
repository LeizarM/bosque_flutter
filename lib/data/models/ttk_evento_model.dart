import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_evento_entity.dart';

/// Columnas de `p_list_ttk_Evento` L. `toJson` es el cuerpo de
/// `/tickets/evento/guardar` (solo los parámetros de `p_abm_ttk_Evento`).
class TtkEventoModel {
  const TtkEventoModel(this.entidad);

  final TtkEventoEntity entidad;

  factory TtkEventoModel.fromJson(Map<String, dynamic> j) => TtkEventoModel(
    TtkEventoEntity(
      codEvento: ttkBigInt(j['codEvento']),
      nombre: ttkTexto(j['nombre']),
      descripcion: ttkTextoN(j['descripcion']),
      fecha: ttkFecha(j['fecha']),
      lugar: ttkTextoN(j['lugar']),
      usaTickets: ttkBool(j['usaTickets']),
      usaBingo: ttkBool(j['usaBingo']),
      mesesReciente: ttkInt(j['mesesReciente']),
      estado: ttkTexto(j['estado']),
      estadoTexto: ttkTexto(j['estadoTexto']),
      totalParticipantes: ttkInt(j['totalParticipantes']),
      totalEmpleados: ttkInt(j['totalEmpleados']),
      totalRecientes: ttkInt(j['totalRecientes']),
      totalInvitados: ttkInt(j['totalInvitados']),
      totalTipos: ttkInt(j['totalTipos']),
      totalTickets: ttkInt(j['totalTickets']),
      codBingo: ttkBigInt(j['codBingo']),
      estadoBingo: ttkTextoN(j['estadoBingo']),
      puedeEditar: ttkBool(j['puedeEditar']),
      puedeEmitir: ttkBool(j['puedeEmitir']),
      puedeVolverBorrador: ttkBool(j['puedeVolverBorrador']),
      puedeImprimir: ttkBool(j['puedeImprimir']),
      puedeCerrar: ttkBool(j['puedeCerrar']),
      puedeEliminar: ttkBool(j['puedeEliminar']),
      audUsuario: ttkBigInt(j['audUsuario']),
      audFecha: ttkFecha(j['audFecha']),
    ),
  );

  factory TtkEventoModel.fromEntity(TtkEventoEntity e) => TtkEventoModel(e);

  TtkEventoEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codEvento': entidad.codEvento,
    'nombre': entidad.nombre,
    'descripcion': entidad.descripcion,
    'fecha': ttkFechaJson(entidad.fecha),
    'lugar': entidad.lugar,
    'usaTickets': ttkBandera(entidad.usaTickets),
    'usaBingo': ttkBandera(entidad.usaBingo),
    'mesesReciente': entidad.mesesReciente,
  });
}
