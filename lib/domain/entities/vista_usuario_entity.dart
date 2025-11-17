class VistaUsuarioEntity {
  int codUsuario;
  int codVista;
  int nivelAcceso;
  int autorizador;
  int audUsuarioI;

  int fila;
  int codVistaPadre;
  int codBoton;
  String direccion;
  String nombreComponente;
  String modulo;
  String vista;
  String boton;
  String descripcion;
  String imagen; //hasta el momento no se utiliza
  int nivelAccesoBoton;
  String tipo;

  VistaUsuarioEntity({
    required this.codUsuario,
    required this.codVista,
    required this.nivelAcceso,
    required this.autorizador,
    required this.audUsuarioI,
    required this.fila,
    required this.codVistaPadre,
    required this.codBoton,
    required this.direccion,
    required this.nombreComponente,
    required this.modulo,
    required this.vista,
    required this.boton,
    required this.descripcion,
    required this.imagen,
    required this.nivelAccesoBoton,
    required this.tipo,
  });
}
