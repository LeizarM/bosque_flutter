import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_entity.dart';

/// Columnas de `p_list_ttk_Bingo` L. `toJson` es el cuerpo de `/bingo/guardar`
/// (parámetros de configuración de `p_abm_ttk_Bingo`, con el vale enlazado).
class TtkBingoModel {
  const TtkBingoModel(this.entidad);

  final TtkBingoEntity entidad;

  factory TtkBingoModel.fromJson(Map<String, dynamic> j) => TtkBingoModel(
    TtkBingoEntity(
      codBingo: ttkBigInt(j['codBingo']),
      codEvento: ttkBigInt(j['codEvento']),
      nombreEvento: ttkTexto(j['nombreEvento']),
      fechaEvento: ttkFecha(j['fechaEvento']),
      nroBolillos: ttkInt(j['nroBolillos']),
      filas: ttkInt(j['filas']),
      columnas: ttkInt(j['columnas']),
      letras: ttkTextoN(j['letras']),
      conComodin: ttkBool(j['conComodin']),
      nroJuegos: ttkInt(j['nroJuegos']),
      nroCartones: ttkInt(j['nroCartones']),
      codTipoTicket: ttkBigInt(j['codTipoTicket']),
      nombreTipoTicket: ttkTextoN(j['nombreTipoTicket']),
      valesBingo: ttkInt(j['valesBingo']),
      cartonesObjetivo: ttkInt(j['cartonesObjetivo']),
      cartonesFaltantes: ttkInt(j['cartonesFaltantes']),
      maxCartonesEmpleado: ttkInt(j['maxCartonesEmpleado']),
      tamRanking: ttkInt(j['tamRanking']),
      modalidad: ttkTextoN(j['modalidad']) ?? 'A',
      modalidadTexto: ttkTexto(j['modalidadTexto']),
      conAviso: ttkBool(j['conAviso']),
      estado: ttkTexto(j['estado']),
      estadoTexto: ttkTexto(j['estadoTexto']),
      nroGeneracion: ttkIntN(j['nroGeneracion']),
      fechaGeneracion: ttkFecha(j['fechaGeneracion']),
      cartonesGenerados: ttkInt(j['cartonesGenerados']),
      cartonesAsignados: ttkInt(j['cartonesAsignados']),
      cartonesDisponibles: ttkInt(j['cartonesDisponibles']),
      cartonesImpresos: ttkInt(j['cartonesImpresos']),
      empleadosConCarton: ttkInt(j['empleadosConCarton']),
      juegosFinalizados: ttkInt(j['juegosFinalizados']),
      nroJuegoActual: ttkIntN(j['nroJuegoActual']),
      nombreJuegoActual: ttkTextoN(j['nombreJuegoActual']),
      rangos: ttkTextoN(j['rangos']),
      mensajeEstado: ttkTexto(j['mensajeEstado']),
      puedeConfigurar: ttkBool(j['puedeConfigurar']),
      puedeGenerar: ttkBool(j['puedeGenerar']),
      puedeAbrirEleccion: ttkBool(j['puedeAbrirEleccion']),
      puedeIniciar: ttkBool(j['puedeIniciar']),
      puedeAsignar: ttkBool(j['puedeAsignar']),
      puedeFinalizar: ttkBool(j['puedeFinalizar']),
      puedeImprimir: ttkBool(j['puedeImprimir']),
      audUsuario: ttkBigInt(j['audUsuario']),
      audFecha: ttkFecha(j['audFecha']),
    ),
  );

  factory TtkBingoModel.fromEntity(TtkBingoEntity e) => TtkBingoModel(e);

  TtkBingoEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codBingo': entidad.codBingo,
    'codEvento': entidad.codEvento,
    'nroBolillos': entidad.nroBolillos,
    'filas': entidad.filas,
    'columnas': entidad.columnas,
    'letras': entidad.letras,
    'conComodin': ttkBandera(entidad.conComodin),
    'nroJuegos': entidad.nroJuegos,
    'nroCartones': entidad.nroCartones,
    // 0 quita el enlace con el vale: la pantalla manda siempre lo que muestra.
    'codTipoTicket': entidad.codTipoTicket ?? BigInt.zero,
    'maxCartonesEmpleado': entidad.maxCartonesEmpleado,
    'tamRanking': entidad.tamRanking,
    'modalidad': entidad.modalidad,
    'conAviso': ttkBandera(entidad.conAviso),
  });
}
