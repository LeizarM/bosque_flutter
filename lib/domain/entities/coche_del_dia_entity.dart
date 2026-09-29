// Destino final: lib/domain/entities/coche_del_dia_entity.dart

/// Una fila de la lista "coches del día" de una ocurrencia puntual de tarea
/// rutinaria (idATR=6). `llego` es `null` mientras no se marcó, 0=NO, 1=SI —
/// distinto del legacy, que usaba 0 como valor por defecto Y como "NO" a la
/// vez.
class CocheDelDiaEntity {
  final int idCo;
  final int? idTarRuti;
  final int? idBitTarRuti;
  final int? idCoche;
  final String? descripcion;
  final DateTime? fecha;
  final int? llego;
  final String? obs;
  final String? marca;
  final String? clase;
  final String? placa;
  final String? color;
  final int? anio;

  /// Lo que marcó OTRA persona sobre este mismo coche, hoy (archivo SQL 45).
  ///
  /// Las filas se siembran por ocurrencia: si dos choferes abren la pantalla el
  /// mismo día, cada uno tiene su propia copia de la lista y no ve la del otro.
  /// Estos tres campos traen la marca más reciente del mismo coche hecha en
  /// cualquier otra ocurrencia del día, para que nadie salga a revisar un
  /// vehículo que otro ya revisó.
  ///
  /// `null` cuando nadie más lo tocó, que es el caso normal: en cuatro años de
  /// datos nunca hubo dos personas marcando coches el mismo día.
  final int? otroLlego;
  final String? otroQuien;
  final DateTime? otroCuando;

  const CocheDelDiaEntity({
    required this.idCo,
    this.idTarRuti,
    this.idBitTarRuti,
    this.idCoche,
    this.descripcion,
    this.fecha,
    this.llego,
    this.obs,
    this.marca,
    this.clase,
    this.placa,
    this.color,
    this.anio,
    this.otroLlego,
    this.otroQuien,
    this.otroCuando,
  });

  bool get yaMarcado => llego != null;

  /// Si alguien más ya se ocupó de este coche hoy.
  bool get marcadoPorOtro => otroLlego != null;

  /// El nombre del otro, o algo legible si ese usuario no tiene empleado
  /// asociado y el join volvió vacío.
  String get quienLoMarco =>
      (otroQuien?.trim().isNotEmpty ?? false)
          ? otroQuien!.trim()
          : 'otra persona';

  /// El nombre y el auto arman una sola línea: "Ya lo marcó X como Llegó".
  String get queMarcoElOtro => otroLlego == 1 ? 'Llegó' : 'No llegó';

  CocheDelDiaEntity copyWith({int? llego, String? obs}) {
    return CocheDelDiaEntity(
      idCo: idCo,
      idTarRuti: idTarRuti,
      idBitTarRuti: idBitTarRuti,
      idCoche: idCoche,
      descripcion: descripcion,
      fecha: fecha,
      llego: llego ?? this.llego,
      obs: obs ?? this.obs,
      marca: marca,
      clase: clase,
      placa: placa,
      color: color,
      anio: anio,
      otroLlego: otroLlego,
      otroQuien: otroQuien,
      otroCuando: otroCuando,
    );
  }
}
