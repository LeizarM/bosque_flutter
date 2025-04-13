class MenuItemEntity {
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
  final List<MenuItemEntity>? items;
  final String? label;
  final int tieneHijo;
  final String? routerLink;
  final String? icon;

  MenuItemEntity({
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
    this.items,
    this.label,
    required this.tieneHijo,
    this.routerLink,
    this.icon,
  });

  factory MenuItemEntity.fromJson(Map<String, dynamic> json) {
    return MenuItemEntity(
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
      items: json['items'] != null
          ? (json['items'] as List<dynamic>)
              .map((item) => MenuItemEntity.fromJson(item))
              .toList()
          : null,
      label: json['label'],
      tieneHijo: json['tieneHijo'] ?? -1,
      routerLink: json['routerLink'],
      icon: json['icon'],
    );
  }
}