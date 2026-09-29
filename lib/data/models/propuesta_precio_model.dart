import 'dart:convert';
import 'package:bosque_flutter/domain/entities/propuesta_precio_entity.dart';

PropuestaPrecioModel propuestaPrecioModelFromJson(String str) =>
    PropuestaPrecioModel.fromJson(json.decode(str));

String propuestaPrecioModelToJson(PropuestaPrecioModel data) =>
    json.encode(data.toJson());

/// Espeja 1:1 la tabla tpr_propuesta y el POJO Propuesta del backend.
///
/// El ABM p_abm_propuesta recibe los campos del POJO tal cual, por eso las
/// claves del toJson son exactamente los nombres del POJO: un parametro que no
/// exista en el procedimiento hace fallar el EXEC entero. Los datos de JOIN o
/// subconsulta (esAprobada de la rama C de p_list_propuesta) viajan en el DTO,
/// no aca.
///
/// Todas las columnas salvo idPropuesta admiten NULL en la base, por eso cada
/// lectura del fromJson tiene default defensivo.
class PropuestaPrecioModel {
  BigInt idPropuesta;
  BigInt codEmpresa;

  /// Dominio de codigos, no una bandera. Es int a proposito, nunca bool.
  int tipo;

  /// varchar(200). El historico tpr_propuestaEliminado lo guarda en
  /// varchar(50): si se archiva, se trunca.
  String titulo;

  /// varchar(250). En el historico es varchar(150): si se archiva, se trunca.
  String obs;

  /// Columna practicamente muerta: 1121 de 1123 filas en cero y los
  /// procedimientos la ignoran. El estado real del flujo vive en
  /// tpr_autorizacion.esAprobada, no aqui. Se conserva solo porque la columna
  /// existe; no se usa para decidir nada ni se manda en el toJson.
  int estado;

  /// Usuario que genero (exporto) la propuesta; lo setea la accion B del ABM.
  BigInt audUsGenerado;

  /// Fecha de generacion. La accion B la pisa con GETDATE() del servidor.
  /// Null mientras la propuesta no se genero.
  DateTime? audFecGenerado;

  BigInt audUsuario;

  /// El SP la escribe con GETDATE() en las acciones I y U: lo que se mande se
  /// ignora al grabar. Se sigue enviando porque en p_list_propuesta si filtra.
  DateTime? audFecha;

  PropuestaPrecioModel({
    required this.idPropuesta,
    required this.codEmpresa,
    required this.tipo,
    required this.titulo,
    required this.obs,
    required this.estado,
    required this.audUsGenerado,
    required this.audFecGenerado,
    required this.audUsuario,
    required this.audFecha,
  });

  factory PropuestaPrecioModel.fromJson(Map<String, dynamic> json) =>
      PropuestaPrecioModel(
        idPropuesta:
            json["idPropuesta"] != null
                ? BigInt.from(json["idPropuesta"])
                : BigInt.zero,
        codEmpresa:
            json["codEmpresa"] != null
                ? BigInt.from(json["codEmpresa"])
                : BigInt.zero,
        tipo: json["tipo"] ?? 0,
        titulo: json["titulo"] ?? '',
        obs: json["obs"] ?? '',
        // Default 0, que es el literal que graba el alta del procedimiento.
        estado: json["estado"] ?? 0,
        audUsGenerado:
            json["audUsGenerado"] != null
                ? BigInt.from(json["audUsGenerado"])
                : BigInt.zero,
        // Nulo real: sin fecha de generacion la propuesta no fue exportada.
        audFecGenerado:
            json["audFecGenerado"] != null
                ? DateTime.parse(json["audFecGenerado"])
                : null,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        audFecha:
            json["audFecha"] != null ? DateTime.parse(json["audFecha"]) : null,
      );

  // estado no se envia: es de solo lectura desde el cliente. El alta graba el
  // literal 0 sin mirar el parametro y la modificacion no lo toca, asi que
  // mandarlo solo genera confusion. El estado real se lee de la autorizacion.
  //
  // audFecha y audFecGenerado si se mandan, aunque el servidor las pise con
  // GETDATE() al grabar: son parametros del listado y ahi si filtran.
  Map<String, dynamic> toJson() => {
    "idPropuesta": idPropuesta.toInt(),
    "codEmpresa": codEmpresa.toInt(),
    "tipo": tipo,
    "titulo": titulo,
    "obs": obs,
    "audUsGenerado": audUsGenerado.toInt(),
    "audFecGenerado": audFecGenerado?.toIso8601String(),
    "audUsuario": audUsuario.toInt(),
    "audFecha": audFecha?.toIso8601String(),
  };

  PropuestaPrecioEntity toEntity() => PropuestaPrecioEntity(
    idPropuesta: idPropuesta,
    codEmpresa: codEmpresa,
    tipo: tipo,
    titulo: titulo,
    obs: obs,
    estado: estado,
    audUsGenerado: audUsGenerado,
    audFecGenerado: audFecGenerado,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory PropuestaPrecioModel.fromEntity(PropuestaPrecioEntity e) =>
      PropuestaPrecioModel(
        idPropuesta: e.idPropuesta,
        codEmpresa: e.codEmpresa,
        tipo: e.tipo,
        titulo: e.titulo,
        obs: e.obs,
        estado: e.estado,
        audUsGenerado: e.audUsGenerado,
        audFecGenerado: e.audFecGenerado,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}
