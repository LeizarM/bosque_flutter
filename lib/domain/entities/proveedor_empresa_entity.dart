class ProveedorEmpresaEntity {
  final String cardCode;
  final String cardName;

  const ProveedorEmpresaEntity({
    required this.cardCode,
    required this.cardName,
  });

  @override
  String toString() => '$cardCode - $cardName';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProveedorEmpresaEntity && other.cardCode == cardCode;

  @override
  int get hashCode => cardCode.hashCode;
}
