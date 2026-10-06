import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';

/// Reglas de visibilidad de la pantalla de Bancos (tch_banco, vista 43). Es
/// logica pura, sin Flutter ni Riverpod.
///
/// **Son solo para dibujar**: el servidor exige el mismo boton (`btnNuevoB`,
/// `btnEditarB`, `btnEliminarB`) y responde 403 si la pantalla se equivoca. El
/// administrador (`tipoUsuario == 'ROLE_ADM'`) pasa siempre, aunque el boton no
/// figure en su ACL; para el resto, un boton cuenta si su `permiso != 0`, la
/// misma condicion que `Loggin.autorizarBtn()` del ERP viejo.
class PermisosBanco {
  static const String btnNuevo = PermisosCheque.btnNuevoBanco;
  static const String btnEditar = PermisosCheque.btnEditarBanco;
  static const String btnEliminar = PermisosCheque.btnEliminarBanco;

  /// Nombres de los botones a los que el usuario tiene acceso.
  final Set<String> botones;

  /// `tipoUsuario == 'ROLE_ADM'`.
  final bool esAdmin;

  const PermisosBanco({required this.botones, required this.esAdmin});

  /// Sin ningun boton y sin ser administrador: lo que se ve mientras llegan los
  /// permisos o si no hay sesion.
  static const PermisosBanco ninguno = PermisosBanco(
    botones: <String>{},
    esAdmin: false,
  );

  /// Arma los permisos con las dos fuentes del frontend: el `tipoUsuario` del
  /// usuario y su lista de botones.
  factory PermisosBanco.desde({
    required String? tipoUsuario,
    required Iterable<UsuarioBtnEntity> botones,
  }) => PermisosBanco(
    botones: {
      for (final b in botones)
        if (b.permiso != 0) b.boton,
    },
    esAdmin: tipoUsuario == 'ROLE_ADM',
  );

  /// El ACL del boton, con el fallback del administrador.
  bool tiene(String boton) => esAdmin || botones.contains(boton);

  bool get puedeCrear => tiene(btnNuevo);
  bool get puedeEditar => tiene(btnEditar);
  bool get puedeEliminar => tiene(btnEliminar);

  /// Alguna accion por fila: de eso depende que se dibuje la columna de acciones.
  bool get hayAccionesPorFila => puedeEditar || puedeEliminar;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermisosBanco &&
          other.esAdmin == esAdmin &&
          other.botones.length == botones.length &&
          other.botones.containsAll(botones);

  @override
  int get hashCode => Object.hash(esAdmin, botones.length);
}
