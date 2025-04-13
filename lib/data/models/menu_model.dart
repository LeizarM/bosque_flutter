import 'package:bosque_flutter/domain/entities/menu_entity.dart';
class MenuItemModel {
  final int codVista;
  final int codVistaPadre;
  final String direccion;
  final String titulo;
  final String? descripcion;
  final String? imagen;
  final int esRaiz;
  final int autorizar;
  final int audUsuarioI;
  final int fila;
  final String? label;
  final int tieneHijo;
  final String? routerLink;
  final String? icon;
  final List<MenuItemModel>? items;

  MenuItemModel({
    required this.codVista,
    required this.codVistaPadre,
    required this.direccion,
    required this.titulo,
    this.descripcion,
    this.imagen,
    required this.esRaiz,
    required this.autorizar,
    required this.audUsuarioI,
    required this.fila,
    this.label,
    required this.tieneHijo,
    this.routerLink,
    this.icon,
    this.items,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      codVista: json['codVista'] ?? 0,
      codVistaPadre: json['codVistaPadre'] ?? 0,
      direccion: json['direccion'] ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'],
      imagen: json['imagen'],
      esRaiz: json['esRaiz'] ?? 0,
      autorizar: json['autorizar'] ?? 0,
      audUsuarioI: json['audUsuarioI'] ?? 0,
      fila: json['fila'] ?? 0,
      label: json['label'],
      tieneHijo: json['tieneHijo'] ?? -1,
      routerLink: json['routerLink'],
      icon: json['icon'],
      items: json['items'] != null
          ? (json['items'] as List<dynamic>)
              .map((item) => MenuItemModel.fromJson(item))
              .toList()
          : null,
    );
  }

  MenuItemEntity toEntity() {
    return MenuItemEntity(
      codVista: codVista,
      codVistaPadre: codVistaPadre,
      direccion: direccion,
      titulo: titulo,
      descripcion: descripcion,
      imagen: imagen,
      esRaiz: esRaiz,
      autorizar: autorizar,
      audUsuarioI: audUsuarioI,
      fila: fila,
      label: label,
      tieneHijo: tieneHijo,
      routerLink: routerLink,
      icon: icon,
      items: items?.map((model) => model.toEntity()).toList(),
    );
  }
}