/// Un cliente de SAP para elegir al dar de alta una garantia
/// (ClienteSapDto de `/garantias/clientes-sap`).
class ClienteSapEntity {
  final String codClienteSAP;
  final String datoCliente;

  const ClienteSapEntity({
    required this.codClienteSAP,
    required this.datoCliente,
  });

  String get etiqueta => '$datoCliente · $codClienteSAP';

  @override
  bool operator ==(Object other) =>
      other is ClienteSapEntity && other.codClienteSAP == codClienteSAP;

  @override
  int get hashCode => codClienteSAP.hashCode;
}
