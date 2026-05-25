class DocsVencidosEntity {
  final int fila;
  final int codEmpleado;
  final String nombreCompleto;
  final String ciNumero;
  final String ciFechaVencimiento; // "DD/MM/YYYY" o "SIN FECHA"
  final String licenciaVencimiento; // "DD/MM/YYYY" o "SIN LICENCIA REGISTRADA"
  //final String estadoCI; // "VENCIDO" | "PRÓXIMO A VENCER" | "VIGENTE"
  //final String
  //estadoLicencia; // "NO REGISTRADA" | "VENCIDO" | "PRÓXIMO A VENCER" | "VIGENTE"
  final String estadoDocumentos;

  const DocsVencidosEntity({
    required this.fila,
    required this.codEmpleado,
    required this.nombreCompleto,
    required this.ciNumero,
    required this.ciFechaVencimiento,
    required this.licenciaVencimiento,
    // required this.estadoCI,
    // required this.estadoLicencia,
    required this.estadoDocumentos,
  });
}
