import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_juego_entity.dart';

/// Columnas de `p_list_ttk_BingoJuego` L. `toJson` es el cuerpo de
/// `/bingo/juego/guardar` (nombre, figura y premio).
class TtkBingoJuegoModel {
  const TtkBingoJuegoModel(this.entidad);

  final TtkBingoJuegoEntity entidad;

  factory TtkBingoJuegoModel.fromJson(Map<String, dynamic> j) =>
      TtkBingoJuegoModel(
        TtkBingoJuegoEntity(
          codJuego: ttkBigInt(j['codJuego']),
          codBingo: ttkBigInt(j['codBingo']),
          nroJuego: ttkInt(j['nroJuego']),
          nombre: ttkTexto(j['nombre']),
          figura: ttkTexto(j['figura']),
          premio: ttkTextoN(j['premio']),
          filas: ttkInt(j['filas']),
          columnas: ttkInt(j['columnas']),
          conComodin: ttkBool(j['conComodin']),
          casillasFigura: ttkInt(j['casillasFigura']),
          estado: ttkTexto(j['estado']),
          estadoTexto: ttkTexto(j['estadoTexto']),
          fechaInicio: ttkFecha(j['fechaInicio']),
          fechaFin: ttkFecha(j['fechaFin']),
          bolillosMarcados: ttkInt(j['bolillosMarcados']),
          ganadoresConfirmados: ttkInt(j['ganadoresConfirmados']),
          puedeEditarFigura: ttkBool(j['puedeEditarFigura']),
          puedeEditarPremio: ttkBool(j['puedeEditarPremio']),
          puedeComenzar: ttkBool(j['puedeComenzar']),
          puedeFinalizar: ttkBool(j['puedeFinalizar']),
          audUsuario: ttkBigInt(j['audUsuario']),
          audFecha: ttkFecha(j['audFecha']),
        ),
      );

  factory TtkBingoJuegoModel.fromEntity(TtkBingoJuegoEntity e) =>
      TtkBingoJuegoModel(e);

  TtkBingoJuegoEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codJuego': entidad.codJuego,
    'nombre': entidad.nombre,
    'figura': entidad.figura,
    // Vacío lo quita: el diálogo manda siempre lo que muestra.
    'premio': entidad.premio ?? '',
  });
}
