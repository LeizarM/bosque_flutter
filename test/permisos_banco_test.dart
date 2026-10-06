import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_banco.dart';
import 'package:bosque_flutter/presentation/widgets/bancos/lista_bancos.dart';

/// Los tres botones de la vista 43. El servidor exige el mismo boton; esto solo
/// fija lo que la pantalla dibuja: el ACL de `tb_usuarioBtn` mas el fallback del
/// administrador.
void main() {
  PermisosBanco usuario(Set<String> botones) =>
      PermisosBanco(botones: botones, esAdmin: false);
  const admin = PermisosBanco(botones: <String>{}, esAdmin: true);

  UsuarioBtnEntity btn(String nombre, int permiso) => UsuarioBtnEntity(
    codUsuario: 1,
    codBtn: 1,
    nivelAcceso: permiso,
    audUsuario: 1,
    boton: nombre,
    permiso: permiso,
    pertenVist: 43,
  );

  test('los nombres son los de tb_vistaBtn de la vista 43', () {
    expect(PermisosBanco.btnNuevo, 'btnNuevoB');
    expect(PermisosBanco.btnEditar, 'btnEditarB');
    expect(PermisosBanco.btnEliminar, 'btnEliminarB');
  });

  group('el administrador pasa siempre', () {
    test('aunque ningun boton figure en su ACL', () {
      expect(admin.puedeCrear, isTrue);
      expect(admin.puedeEditar, isTrue);
      expect(admin.puedeEliminar, isTrue);
      expect(admin.hayAccionesPorFila, isTrue);
    });
  });

  group('un usuario ve solo los botones de su ACL', () {
    test('sin ningun boton nada se habilita', () {
      final nadie = usuario({});
      expect(nadie.puedeCrear, isFalse);
      expect(nadie.puedeEditar, isFalse);
      expect(nadie.puedeEliminar, isFalse);
      expect(nadie.hayAccionesPorFila, isFalse);
    });

    test('cada boton habilita solo lo suyo', () {
      final nuevo = usuario({PermisosBanco.btnNuevo});
      expect(nuevo.puedeCrear, isTrue);
      expect(nuevo.puedeEditar, isFalse);
      expect(nuevo.puedeEliminar, isFalse);
      // Crear no es una accion de fila.
      expect(nuevo.hayAccionesPorFila, isFalse);

      final editar = usuario({PermisosBanco.btnEditar});
      expect(editar.puedeCrear, isFalse);
      expect(editar.puedeEditar, isTrue);
      expect(editar.puedeEliminar, isFalse);
      expect(editar.hayAccionesPorFila, isTrue);

      final eliminar = usuario({PermisosBanco.btnEliminar});
      expect(eliminar.puedeCrear, isFalse);
      expect(eliminar.puedeEditar, isFalse);
      expect(eliminar.puedeEliminar, isTrue);
      expect(eliminar.hayAccionesPorFila, isTrue);
    });

    test('los botones de la vista 42 no abren nada en bancos', () {
      final deCheques = usuario({
        'btnNuevoCH',
        'btnEditar1CH',
        'btnEliminarSegCH',
      });
      expect(deCheques.puedeCrear, isFalse);
      expect(deCheques.puedeEditar, isFalse);
      expect(deCheques.puedeEliminar, isFalse);
    });
  });

  group('desde: arma los permisos con las dos fuentes', () {
    test('un boton cuenta solo si su permiso es distinto de 0', () {
      final p = PermisosBanco.desde(
        tipoUsuario: 'ROLE_LIM',
        botones: [
          btn('btnNuevoB', 1),
          btn('btnEditarB', 0),
          btn('btnEliminarB', 2),
        ],
      );
      expect(p.botones, {'btnNuevoB', 'btnEliminarB'});
      expect(p.puedeCrear, isTrue);
      expect(p.puedeEditar, isFalse);
      expect(p.puedeEliminar, isTrue);
      expect(p.esAdmin, isFalse);
    });

    test('ROLE_ADM es administrador, otro rol no', () {
      expect(
        PermisosBanco.desde(tipoUsuario: 'ROLE_ADM', botones: const []).esAdmin,
        isTrue,
      );
      expect(
        PermisosBanco.desde(tipoUsuario: 'ROLE_LIM', botones: const []).esAdmin,
        isFalse,
      );
      expect(
        PermisosBanco.desde(tipoUsuario: null, botones: const []).esAdmin,
        isFalse,
      );
    });

    test('el administrador pasa aunque la lista venga vacia', () {
      final p = PermisosBanco.desde(tipoUsuario: 'ROLE_ADM', botones: const []);
      expect(p.puedeCrear && p.puedeEditar && p.puedeEliminar, isTrue);
    });

    test('«ninguno» es lo que se ve mientras llegan los permisos', () {
      const n = PermisosBanco.ninguno;
      expect(n.esAdmin, isFalse);
      expect(n.botones, isEmpty);
      expect(n.puedeCrear || n.puedeEditar || n.puedeEliminar, isFalse);
    });
  });

  test('igualdad por contenido', () {
    expect(
      usuario({'btnNuevoB', 'btnEditarB'}),
      usuario({'btnEditarB', 'btnNuevoB'}),
    );
    expect(usuario({'btnNuevoB'}), isNot(usuario({'btnEditarB'})));
    expect(admin, isNot(usuario({})));
    expect(usuario({'btnNuevoB'}).hashCode, usuario({'btnNuevoB'}).hashCode);
  });

  group('las acciones de fila salen de los permisos', () {
    test('en el orden de los botones del legacy', () {
      expect(accionesDeBanco(admin), [
        AccionFilaBanco.editar,
        AccionFilaBanco.eliminar,
      ]);
      expect(accionesDeBanco(usuario({PermisosBanco.btnEliminar})), [
        AccionFilaBanco.eliminar,
      ]);
      expect(accionesDeBanco(usuario({PermisosBanco.btnNuevo})), isEmpty);
      expect(accionesDeBanco(PermisosBanco.ninguno), isEmpty);
    });
  });
}
