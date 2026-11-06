/// Fila de la planilla por empleado: horas (`h*`) y monto (`m*`) por tipo de
/// hora, comidas (`c*`) y totales. Los nombres siguen los alias del SP.
class HexPlanillaEmpleadoEntity {
  /// El área tal cual; nula si el empleado no tiene (D39).
  final String? nombreArea;
  final int ordenArea;

  /// D39: la planilla (en un lote hay varias), quién paga y la sucursal por la
  /// que se agrupa y ordena, como en el PDF.
  final BigInt? idPlanilla;
  final BigInt? codEmpresa;
  final String? nombreEmpresa;
  final BigInt? codSucursal;
  final String? nombreSucursal;
  final int ordenSucursal;
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final String? cargo;
  final double? costoHora;

  /// Horas simples, al 50 %, al 100 %, domingo y feriado, con su monto.
  final double hHS;
  final double mHS;
  final double hH50;
  final double mH50;
  final double hH100;
  final double mH100;
  final double hHD;
  final double mHD;
  final double hHF;
  final double mHF;

  /// Comidas: desayuno, doble desayuno, almuerzo, doble almuerzo, cena y doble cena.
  final int cD;
  final int cDD;
  final int cA;
  final int cDA;
  final int cC;
  final int cDC;
  final double mOtros;
  final double totalHoras;
  final double totalComidas;
  final double total;

  const HexPlanillaEmpleadoEntity({
    this.nombreArea,
    this.ordenArea = 0,
    this.idPlanilla,
    this.codEmpresa,
    this.nombreEmpresa,
    this.codSucursal,
    this.nombreSucursal,
    this.ordenSucursal = 0,
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.cargo,
    this.costoHora,
    this.hHS = 0,
    this.mHS = 0,
    this.hH50 = 0,
    this.mH50 = 0,
    this.hH100 = 0,
    this.mH100 = 0,
    this.hHD = 0,
    this.mHD = 0,
    this.hHF = 0,
    this.mHF = 0,
    this.cD = 0,
    this.cDD = 0,
    this.cA = 0,
    this.cDA = 0,
    this.cC = 0,
    this.cDC = 0,
    this.mOtros = 0,
    this.totalHoras = 0,
    this.totalComidas = 0,
    this.total = 0,
  });
}
