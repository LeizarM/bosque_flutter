import 'package:bosque_flutter/domain/entities/configuracion_recuperacion_entity.dart';

/// Fila de trec_configuracion tal como la manda `POST /recuperacion-configuracion/listar`.
class ConfiguracionRecuperacionModel {
  final String clave;
  final String? valor;
  final String nombre;
  final String descripcion;
  final String tipo;
  final String? opciones;
  final int? minimo;
  final int? maximo;
  final String grupo;
  final int orden;
  final int? audUsuario;
  final DateTime? audFecha;
  final bool configurado;

  const ConfiguracionRecuperacionModel({
    required this.clave,
    required this.valor,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.opciones,
    required this.minimo,
    required this.maximo,
    required this.grupo,
    required this.orden,
    required this.audUsuario,
    required this.audFecha,
    required this.configurado,
  });

  factory ConfiguracionRecuperacionModel.fromJson(Map<String, dynamic> json) {
    return ConfiguracionRecuperacionModel(
      clave: json['clave'] as String? ?? '',
      valor: json['valor'] as String?,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'texto',
      opciones: json['opciones'] as String?,
      minimo: (json['minimo'] as num?)?.toInt(),
      maximo: (json['maximo'] as num?)?.toInt(),
      grupo: json['grupo'] as String? ?? '',
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      audUsuario: (json['audUsuario'] as num?)?.toInt(),
      audFecha:
          json['audFecha'] != null
              ? DateTime.tryParse(json['audFecha'].toString())
              : null,
      configurado: json['configurado'] as bool? ?? false,
    );
  }

  ConfiguracionRecuperacionEntity toEntity() => ConfiguracionRecuperacionEntity(
    clave: clave,
    valor: valor,
    nombre: nombre,
    descripcion: descripcion,
    tipo: tipo,
    opciones:
        (opciones ?? '')
            .split(',')
            .map((o) => o.trim())
            .where((o) => o.isNotEmpty)
            .toList(),
    minimo: minimo,
    maximo: maximo,
    grupo: grupo,
    orden: orden,
    audUsuario: audUsuario,
    audFecha: audFecha,
    configurado: configurado,
  );
}
