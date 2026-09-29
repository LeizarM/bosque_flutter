/// Rango de gramaje de papel (tabla tpr_RangoGramaje del modulo de Precios).
/// Cada fila es un intervalo cerrado [min - max] expresado en gramos por metro
/// cuadrado. Lo consumen tpr_grupoFamTipoRangoGram (que asigna un rango a cada
/// par grupo de familia / tipo de papel) y tpr_producto.idRangoGram.
///
/// OJO con la precision: en la base min y max son decimal(16,2), los unicos
/// numericos EXACTOS de todo el modulo de precios (el resto es float(53)).
/// Dart no tiene BigDecimal, asi que aqui viajan en double. Sirve para mostrar
/// y para comparar, pero no hay que acumular ni redondear con ellos: el valor
/// exacto lo mantiene el backend en BigDecimal. El modelo viejo declaraba estos
/// campos como float contra un parametro INT del SP y un rango 80,50 se
/// guardaba como 80; por eso el decimal de dos posiciones no es un detalle.
///
/// Salvo la PK todas las columnas admiten NULL en la base, por eso el model
/// lee todo con default defensivo.
class RangoGramajeEntity {
  /// bigint identity. PK. En un alta todavia no existe: vale BigInt.zero y el
  /// backend lo devuelve en el idGenerado de la respuesta del SP.
  final BigInt idRangoGram;

  /// Limite inferior del rango, en g/m2. decimal(16,2) en la base.
  final double min;

  /// Limite superior del rango, en g/m2. decimal(16,2) en la base.
  final double max;

  /// Usuario que hizo el ultimo movimiento.
  final BigInt audUsuario;

  /// Fecha del ultimo movimiento. Solo lectura desde la aplicacion: el SP de
  /// ABM ignora el valor que se le mande y siempre estampa GETDATE(). Puede
  /// llegar null cuando el listado no la trae.
  final DateTime? audFecha;

  const RangoGramajeEntity({
    required this.idRangoGram,
    required this.min,
    required this.max,
    required this.audUsuario,
    this.audFecha,
  });

  /// Registro nuevo, todavia sin PK asignada por la base.
  bool get esNuevo => idRangoGram == BigInt.zero;

  /// El intervalo esta bien armado cuando el tope no es menor que el piso.
  /// Sirve para pintar el error en el formulario antes de mandar el ABM.
  bool get esRangoValido => max >= min;

  /// Ancho del intervalo en g/m2. Es un calculo de presentacion sobre doubles:
  /// puede arrastrar el tipico ruido binario (0.1 + 0.2), no usarlo para nada
  /// que se guarde.
  double get amplitud => max - min;

  /// Rango legible y corto para tarjetas, combos y titulos: "70 a 90 g".
  /// Oculta los dos decimales cuando no aportan.
  String get rangoLegible => '${_gramaje(min)} a ${_gramaje(max)} g';

  /// Rango con los dos decimales visibles, igual que la etiqueta que arma el
  /// SP en el listado: "[ 80.00 - 120.00 ]". Util cuando la pantalla necesita
  /// mostrar el dato tal como esta guardado.
  String get rangoConDecimales =>
      '[ ${min.toStringAsFixed(2)} - ${max.toStringAsFixed(2)} ]';

  /// Fecha del ultimo movimiento en formato dd/MM/yyyy. Cadena vacia si el
  /// backend no la mando.
  String get audFechaLegible {
    final f = audFecha;
    if (f == null) return '';
    final d = f.day.toString().padLeft(2, '0');
    final m = f.month.toString().padLeft(2, '0');
    return '$d/$m/${f.year}';
  }

  /// Muestra 80.00 como "80" y 80.50 como "80.5", pero respeta 80.25.
  /// Solo formateo: no cambia el valor que se envia al backend.
  static String _gramaje(double valor) {
    if (valor == valor.roundToDouble()) return valor.toStringAsFixed(0);
    final texto = valor.toStringAsFixed(2);
    return texto.endsWith('0') ? texto.substring(0, texto.length - 1) : texto;
  }

  RangoGramajeEntity copyWith({
    BigInt? idRangoGram,
    double? min,
    double? max,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => RangoGramajeEntity(
    idRangoGram: idRangoGram ?? this.idRangoGram,
    min: min ?? this.min,
    max: max ?? this.max,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
