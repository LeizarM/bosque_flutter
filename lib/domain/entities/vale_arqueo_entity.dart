// Destino final: lib/domain/entities/vale_arqueo_entity.dart

/// Una fila de vale, local hasta el submit del arqueo (idATR=2) — igual
/// criterio que LlegadaCajaFuerteEntity: no se lista desde el backend, se
/// arma en la pantalla.
class ValeArqueoEntity {
  final String id;
  final int? numVale;
  final String nombre;
  final double? monto;
  final String obs;

  const ValeArqueoEntity({
    required this.id,
    this.numVale,
    this.nombre = '',
    this.monto,
    this.obs = '',
  });

  bool get esValido => (monto ?? 0) > 0;

  ValeArqueoEntity copyWith({int? numVale, String? nombre, double? monto, String? obs}) {
    return ValeArqueoEntity(
      id: id,
      numVale: numVale ?? this.numVale,
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      obs: obs ?? this.obs,
    );
  }
}
