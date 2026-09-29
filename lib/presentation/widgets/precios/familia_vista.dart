/// La fila de la grilla de familias de producto, ya lista para dibujar.
///
/// **Por que no se usa [ProductoFamiliaEntity] aca.** La entity es el reflejo
/// crudo de tpr_producto: guarda los ids de las claves foraneas, no los nombres.
/// Lo que la pantalla tiene que mostrar —"Bond", "Blanco", "80 a 120 g"— no es
/// ninguna columna de esa tabla: sale de seis JOIN que resuelve el backend en el
/// listado. El contrato de `PreciosRepository.obtenerFamilias` lo dice de
/// frente: esas lecturas devuelven `Map<String, dynamic>` porque no hay tabla
/// detras del DTO de despliegue.
///
/// Asi que esta clase es el unico lugar del modulo donde se tocan las claves de
/// ese mapa. Todo lo demas —tabla, tarjeta, dialogo— habla con campos tipados y
/// no con cadenas magicas: si el backend renombra una clave, se arregla aqui y
/// no en cinco archivos.
///
/// **Los ids son opcionales a proposito.** El contrato documenta que el listado
/// trae las descripciones y no los ids. Si el backend igual los manda, se leen
/// y sirven para preseleccionar los combos del formulario con exactitud; si no
/// vienen, el formulario cae a emparejar por descripcion (ver `dialogo_familia`)
/// y esta clase deja los ids en null en lugar de inventar ceros, que son un
/// valor con significado propio en este modulo ("sin asignar").
library;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class FamiliaVista {
  const FamiliaVista({
    required this.codigoFamilia,
    required this.grupoFamiliaSap,
    required this.proveedorSap,
    required this.presentacion,
    required this.tipo,
    required this.rangoGramaje,
    required this.color,
    required this.formato,
    required this.gramaje,
    required this.estado,
    required this.costoTM,
    required this.idPropuestaAprobada,
    this.idGrpFamiliaSap,
    this.idProveedorSap,
    this.idPresentacion,
    this.idTipo,
    this.idRangoGram,
    this.idColor,
  });

  /// PK de la familia. Es int y NO la genera la base: en el alta la escribe el
  /// usuario.
  final int codigoFamilia;

  // Descripciones resueltas por el backend.
  final String grupoFamiliaSap;
  final String proveedorSap;
  final String presentacion;
  final String tipo;
  final String rangoGramaje;
  final String color;

  /// Las dos columnas que estan 100% vacias en la base de produccion. No ocupan
  /// una columna de la tabla: viven en el formulario y en el detalle.
  final String formato;
  final String gramaje;

  /// 1 activa, 0 inactiva. Entero y no bool, igual que en la entity: la columna
  /// es int y nada garantiza que solo existan esos dos valores.
  final int estado;

  /// Costo por tonelada metrica. Viaja en double y por eso se muestra siempre
  /// redondeado, nunca crudo.
  final double costoTM;

  /// Ultima propuesta aprobada. Cero = todavia ninguna.
  final BigInt idPropuestaAprobada;

  // Ids de las claves foraneas, cuando el backend los manda. Ver el encabezado.
  final BigInt? idGrpFamiliaSap;
  final BigInt? idProveedorSap;
  final BigInt? idPresentacion;
  final BigInt? idTipo;
  final BigInt? idRangoGram;
  final BigInt? idColor;

  factory FamiliaVista.deMapa(Map<String, dynamic> fila) => FamiliaVista(
    codigoFamilia: _entero(fila['codigoFamilia']),
    grupoFamiliaSap: _sinRelleno(_texto(fila['grpFamilia'] ?? fila['grpFam'])),
    proveedorSap: _sinRelleno(
      _texto(fila['proveedorSap'] ?? fila['proveedorExtSap']),
    ),
    presentacion: _texto(fila['presentacion']),
    tipo: _texto(fila['tipo']),
    rangoGramaje: _texto(fila['rangoGramaje'] ?? fila['rangoGram']),
    color: _texto(fila['color']),
    formato: _texto(fila['formato']),
    gramaje: _texto(fila['gramaje']),
    estado: _estado(fila['estado']),
    costoTM: _decimal(fila['costoTM']),
    idPropuestaAprobada:
        _granEntero(fila['idPropuestaAprobada']) ?? BigInt.zero,
    idGrpFamiliaSap: _granEntero(fila['idGrpFamiliaSap']),
    idProveedorSap: _granEntero(fila['idProveedorSap']),
    idPresentacion: _granEntero(fila['idPresentacion']),
    idTipo: _granEntero(fila['idTipo']),
    idRangoGram: _granEntero(fila['idRangoGram']),
    idColor: _granEntero(fila['idColor']),
  );

  /// Familia habilitada para operar. Mismo criterio que
  /// `ProductoFamiliaEntity.esActiva`.
  bool get esActiva => estado == 1;

  String get estadoLegible => esActiva ? 'Activa' : 'Inactiva';

  String get codigoLegible => codigoFamilia.toString();

  /// Costo por tonelada con dos decimales. El double se muestra redondeado
  /// siempre: crudo arrastra la basura binaria de la representacion.
  /// Como en los reportes: coma para los miles y punto para los decimales.
  String get costoTmLegible => _fmtCosto.format(costoTM);

  /// Todavia no tiene costo cargado por una propuesta.
  bool get sinCosto => costoTM <= 0;

  bool get tienePropuestaAprobada => idPropuestaAprobada > BigInt.zero;

  /// Lo que el catalogo llama "la familia" cuando se la nombra en una linea:
  /// grupo, tipo, presentacion, gramaje y color. Es lo que va en la tarjeta de
  /// movil, donde no entran nueve columnas.
  ///
  /// Se saltean las partes vacias en lugar de dejar separadores colgando: hay
  /// familias sin grupo y sin proveedor asignado, y "· · Bond" no es una
  /// descripcion.
  String get descripcion {
    final partes = <String>[
      for (final p in [
        grupoFamiliaSap,
        tipo,
        presentacion,
        rangoGramaje,
        color,
      ])
        if (p.trim().isNotEmpty) p.trim(),
    ];
    return partes.isEmpty ? 'Sin descripción' : partes.join(' · ');
  }

  /// Todo el texto de la fila en minusculas, para el buscador de la pantalla.
  /// Se calcula una vez por fila y no en cada tecla.
  String get textoBuscable =>
      '$codigoFamilia $grupoFamiliaSap $proveedorSap $presentacion $tipo '
              '$rangoGramaje $color $estadoLegible'
          .toLowerCase();

  /// Muestra un guion en lugar de una celda en blanco.
  static String oGuion(String valor) =>
      valor.trim().isEmpty ? '-' : valor.trim();
}

// ── Lectura defensiva del mapa ──────────────────────────────────────────────
//
// El backend responde JSON: un bigint puede llegar como numero o como cadena
// segun por donde pase, y las columnas nulables de la tabla llegan en null. Se
// lee todo con default en vez de confiar en el tipo.

int _entero(Object? valor) => switch (valor) {
  int v => v,
  num v => v.toInt(),
  String v => int.tryParse(v.trim()) ?? 0,
  _ => 0,
};

double _decimal(Object? valor) => switch (valor) {
  double v => v,
  num v => v.toDouble(),
  String v => double.tryParse(v.trim()) ?? 0,
  _ => 0,
};

String _texto(Object? valor) => valor == null ? '' : valor.toString().trim();

/// `p_list_producto 'L'` no devuelve NULL cuando falta el grupo o el
/// proveedor SAP: devuelve una frase ("-Sin Grupo de Proveedor SAP
/// Asignado-"). Tomada como nombre, no empareja con ningun catalogo -y la
/// ficha creia que el proveedor "no figura"- y ocupa la celda entera. Vacio
/// es lo que significa.
String _sinRelleno(String valor) => valor.startsWith('-Sin') ? '' : valor;

/// Null cuando la clave no vino: ese dato lo usa el formulario para saber si
/// puede preseleccionar un combo por id o tiene que emparejar por descripcion.
BigInt? _granEntero(Object? valor) => switch (valor) {
  BigInt v => v,
  int v => BigInt.from(v),
  num v => BigInt.from(v.toInt()),
  String v => BigInt.tryParse(v.trim()),
  _ => null,
};

/// El estado puede venir como entero, como cadena numerica o ya resuelto a
/// texto por el DTO. Cualquier cosa que no sea reconocible se toma como
/// inactiva: mostrar de mas una familia como activa es peor que de menos.
int _estado(Object? valor) => switch (valor) {
  int v => v,
  num v => v.toInt(),
  bool v => v ? 1 : 0,
  String v => switch (v.trim().toLowerCase()) {
    'activa' || 'activo' || 'true' || 's' => 1,
    final t => int.tryParse(t) ?? 0,
  },
  _ => 0,
};

final NumberFormat _fmtCosto = NumberFormat('#,##0.00', 'en_US');
