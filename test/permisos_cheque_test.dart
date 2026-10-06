import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';

/// Las reglas de visibilidad de cheque.xhtml («Condiciones por componente» de
/// CLAUDE.md). El servidor las repite; estas pruebas fijan que la pantalla
/// dibuje lo mismo que el legacy, incluidas las rarezas que se conservan a
/// proposito.
void main() {
  PermisosCheque usuario(Set<String> botones) =>
      PermisosCheque(botones: botones, esAdmin: false);
  const admin = PermisosCheque(botones: <String>{}, esAdmin: true);

  const estados = <String?>['PEN', 'CER', null, '', ' CER ', 'XYZ'];

  bool cerrado(String? e) => (e ?? '').trim() == 'CER';

  group('el administrador pasa siempre', () {
    test('todas las reglas de la barra y del detalle', () {
      expect(admin.puedeRegistrar, isTrue);
      expect(admin.puedeRegistrarComoAdmin, isTrue);
      expect(admin.puedeTraspasar, isTrue);
      expect(admin.puedeEntregarACustodia, isTrue);
      expect(admin.puedeDarCustodia, isTrue);
      expect(admin.puedeElegirSucursal, isTrue);
      expect(admin.puedeCompletar, isTrue);
      expect(admin.puedeEliminarAccion, isTrue);
      expect(admin.fechaCobroSinLimite, isTrue);
      expect(admin.puedeFechaCobroDesdeDetalle, isTrue);
      expect(admin.puedeCrearBanco, isTrue);
      expect(admin.puedeEditarBanco, isTrue);
      expect(admin.puedeEliminarBanco, isTrue);
      expect(admin.puedeReporteRecibidos, isTrue);
      expect(admin.puedeReporteCobranzas, isTrue);
      expect(admin.puedeReporteCustodio, isTrue);
      expect(admin.puedeReciboUltimoCheque, isTrue);
      expect(admin.puedeReimprimirTraspaso, isTrue);
      expect(admin.puedeVerReportes, isTrue);
    });

    test('las variantes con estado, tambien con el cheque CER', () {
      for (final e in estados) {
        expect(admin.puedeEditar(e), isTrue, reason: 'editar $e');
        expect(admin.puedeEditarTalonario(e), isTrue, reason: 'talonario $e');
        expect(admin.puedeCambiarFechaCobro(e), isTrue, reason: 'cobro $e');
        expect(admin.puedeEditarComoAdmin(e), isTrue, reason: 'editar adm $e');
        expect(
          admin.puedeCambiarFechaCobroComoAdmin(e),
          isTrue,
          reason: 'cobro adm $e',
        );
      }
    });

    test(
      'pasa en las dos «Editar», aunque la pantalla le muestre un solo lapiz',
      () {
        expect(admin.puedeEditar('CER'), isTrue);
        expect(admin.puedeEditarTalonario('PEN'), isTrue);
      },
    );
  });

  group('sin ningun boton nada se habilita', () {
    final nadie = usuario({});
    test('barra y detalle', () {
      expect(nadie.puedeRegistrar, isFalse);
      expect(nadie.puedeRegistrarComoAdmin, isFalse);
      expect(nadie.puedeTraspasar, isFalse);
      expect(nadie.puedeEntregarACustodia, isFalse);
      expect(nadie.puedeDarCustodia, isFalse);
      expect(nadie.puedeElegirSucursal, isFalse);
      expect(nadie.puedeCompletar, isFalse);
      expect(nadie.puedeEliminarAccion, isFalse);
      expect(nadie.fechaCobroSinLimite, isFalse);
      expect(nadie.puedeFechaCobroDesdeDetalle, isFalse);
      expect(nadie.puedeReporteRecibidos, isFalse);
      expect(nadie.puedeReporteCobranzas, isFalse);
      expect(nadie.puedeReporteCustodio, isFalse);
      expect(nadie.puedeReciboUltimoCheque, isFalse);
      expect(nadie.puedeReimprimirTraspaso, isFalse);
      expect(nadie.puedeVerReportes, isFalse);
    });

    test('filas', () {
      for (final e in estados) {
        expect(nadie.puedeEditar(e), isFalse);
        expect(nadie.puedeEditarTalonario(e), isFalse);
        expect(nadie.puedeCambiarFechaCobro(e), isFalse);
        expect(nadie.puedeEditarComoAdmin(e), isFalse);
        expect(nadie.puedeCambiarFechaCobroComoAdmin(e), isFalse);
      }
    });

    test('PermisosCheque.ninguno es lo mismo', () {
      expect(PermisosCheque.ninguno.puedeRegistrar, isFalse);
      expect(PermisosCheque.ninguno.puedeEditar('PEN'), isFalse);
      expect(PermisosCheque.ninguno.esAdmin, isFalse);
    });
  });

  group('botones de la barra: solo el ACL, no dependen del registro', () {
    test('cada boton habilita solo lo suyo', () {
      expect(usuario({'btnNuevoCH'}).puedeRegistrar, isTrue);
      expect(usuario({'btnNuevo2CH'}).puedeRegistrar, isFalse);
      expect(usuario({'btnNuevo2CH'}).puedeRegistrarComoAdmin, isTrue);
      expect(usuario({'btnTraspasoCH'}).puedeTraspasar, isTrue);
      expect(usuario({'btnCustodiaCH'}).puedeEntregarACustodia, isTrue);
      expect(usuario({'btnCustodiaCH'}).puedeDarCustodia, isFalse);
      expect(usuario({'btnCustodia2CH'}).puedeDarCustodia, isTrue);
      expect(usuario({'btnChqSucrs'}).puedeElegirSucursal, isTrue);
    });

    test('el combo de sucursal se habilita solo con btnChqSucrs', () {
      expect(
        usuario({'btnNuevoCH', 'btnDetalleCH'}).puedeElegirSucursal,
        isFalse,
      );
    });
  });

  group('un solo «Registrar» (btnNuevoCH o btnNuevo2CH)', () {
    test('se ve con btnNuevoCH, con btnNuevo2CH o con los dos', () {
      expect(usuario({'btnNuevoCH'}).puedeVerRegistrar, isTrue);
      expect(usuario({'btnNuevo2CH'}).puedeVerRegistrar, isTrue);
      expect(usuario({'btnNuevoCH', 'btnNuevo2CH'}).puedeVerRegistrar, isTrue);
      expect(admin.puedeVerRegistrar, isTrue);
    });

    test('sin ninguno de los dos no se ve', () {
      expect(usuario({}).puedeVerRegistrar, isFalse);
      expect(usuario({'btnEditar1CH', 'btnTraspasoCH'}).puedeVerRegistrar, isFalse);
      expect(PermisosCheque.ninguno.puedeVerRegistrar, isFalse);
    });

    test('abre en modo administrador con btnNuevo2CH y el administrador', () {
      expect(admin.modoDeRegistro, ModoRegistroCheque.admin);
      expect(usuario({'btnNuevo2CH'}).modoDeRegistro, ModoRegistroCheque.admin);
      expect(
        usuario({'btnNuevoCH', 'btnNuevo2CH'}).modoDeRegistro,
        ModoRegistroCheque.admin,
      );
    });

    test('abre en modo estandar con solo btnNuevoCH', () {
      expect(usuario({'btnNuevoCH'}).modoDeRegistro, ModoRegistroCheque.estandar);
    });
  });

  group('reportes en PDF: un boton por reporte (btnRpt1CH a btnRpt5CH)', () {
    test('cada boton habilita solo su reporte', () {
      expect(usuario({'btnRpt1CH'}).puedeReporteRecibidos, isTrue);
      expect(usuario({'btnRpt2CH'}).puedeReporteCobranzas, isTrue);
      expect(usuario({'btnRpt3CH'}).puedeReporteCustodio, isTrue);
      expect(usuario({'btnRpt4CH'}).puedeReciboUltimoCheque, isTrue);
      expect(usuario({'btnRpt5CH'}).puedeReimprimirTraspaso, isTrue);

      // Y ninguno habilita al vecino.
      final u1 = usuario({'btnRpt1CH'});
      expect(u1.puedeReporteCobranzas, isFalse);
      expect(u1.puedeReporteCustodio, isFalse);
      expect(u1.puedeReciboUltimoCheque, isFalse);
      expect(u1.puedeReimprimirTraspaso, isFalse);
      final u5 = usuario({'btnRpt5CH'});
      expect(u5.puedeReporteRecibidos, isFalse);
      expect(u5.puedeReporteCobranzas, isFalse);
      expect(u5.puedeReporteCustodio, isFalse);
      expect(u5.puedeReciboUltimoCheque, isFalse);
    });

    test('la nomina del traspaso la gobierna btnTraspasoCH, no un rpt', () {
      expect(usuario({'btnTraspasoCH'}).puedeTraspasar, isTrue);
      expect(usuario({'btnTraspasoCH'}).puedeVerReportes, isFalse);
      final todosLosRpt = usuario({
        'btnRpt1CH',
        'btnRpt2CH',
        'btnRpt3CH',
        'btnRpt4CH',
        'btnRpt5CH',
      });
      expect(todosLosRpt.puedeTraspasar, isFalse);
    });

    test('puedeVerReportes: con cualquiera de los cinco', () {
      for (final b in const [
        'btnRpt1CH',
        'btnRpt2CH',
        'btnRpt3CH',
        'btnRpt4CH',
        'btnRpt5CH',
      ]) {
        expect(usuario({b}).puedeVerReportes, isTrue, reason: b);
      }
      // Otros botones de la barra no cuentan como reporte.
      expect(
        usuario({'btnNuevoCH', 'btnCustodiaCH', 'btnDetalleCH'}).puedeVerReportes,
        isFalse,
      );
    });

    test('los reportes no dependen del estado de ningun cheque', () {
      // Son de la barra: no reciben estado y no los toca un cheque CER.
      expect(usuario({'btnRpt1CH'}).puedeReporteRecibidos, isTrue);
    });
  });

  test('estaCerrado: solo CER, con espacios y sin importar nulos', () {
    expect(PermisosCheque.estaCerrado('CER'), isTrue);
    expect(PermisosCheque.estaCerrado(' CER '), isTrue);
    expect(PermisosCheque.estaCerrado('PEN'), isFalse);
    expect(PermisosCheque.estaCerrado(''), isFalse);
    expect(PermisosCheque.estaCerrado(null), isFalse);
  });

  group('editar y editar talonario (btnEditar1CH)', () {
    final u = usuario({'btnEditar1CH'});

    test('editar: cheque abierto, nunca cerrado', () {
      for (final e in estados) {
        expect(u.puedeEditar(e), !cerrado(e), reason: 'estado $e');
      }
    });

    test('editar talonario: solo con el cheque cerrado', () {
      for (final e in estados) {
        expect(u.puedeEditarTalonario(e), cerrado(e), reason: 'estado $e');
      }
    });

    test('un cheque nunca ofrece las dos a la vez a un usuario comun', () {
      for (final e in estados) {
        expect(u.puedeEditar(e) && u.puedeEditarTalonario(e), isFalse);
      }
    });

    test('otro boton de edicion no sirve', () {
      final otro = usuario({'btnEditar2CH', 'btnEditar3CH'});
      expect(otro.puedeEditar('PEN'), isFalse);
      expect(otro.puedeEditarTalonario('CER'), isFalse);
    });
  });

  group('fecha de cobro de la fila (btnEditar2CH)', () {
    final u = usuario({'btnEditar2CH'});

    test('solo con el cheque abierto', () {
      for (final e in estados) {
        expect(u.puedeCambiarFechaCobro(e), !cerrado(e), reason: 'estado $e');
      }
    });

    test('btnEditar1CH no da la fecha de cobro', () {
      expect(usuario({'btnEditar1CH'}).puedeCambiarFechaCobro('PEN'), isFalse);
    });
  });

  group('variantes de administrador (btnEditar3CH)', () {
    final u = usuario({'btnEditar3CH'});

    test('editar y fecha de cobro: solo con el cheque abierto', () {
      for (final e in estados) {
        expect(u.puedeEditarComoAdmin(e), !cerrado(e), reason: 'editar $e');
        expect(
          u.puedeCambiarFechaCobroComoAdmin(e),
          !cerrado(e),
          reason: 'cobro $e',
        );
      }
    });

    test('quita el limite de +-28 dias de la fecha de cobro', () {
      expect(u.fechaCobroSinLimite, isTrue);
      expect(usuario({'btnEditar2CH'}).fechaCobroSinLimite, isFalse);
    });
  });

  group('completar y detalle', () {
    test('completar vale en cualquier estado: no recibe el estado', () {
      expect(usuario({'btnDetalleCH'}).puedeCompletar, isTrue);
      expect(usuario({'btnEditar1CH'}).puedeCompletar, isFalse);
    });

    test('«Fecha Cobro» desde el detalle: cualquiera de los tres botones', () {
      expect(usuario({'btnEditar2CH'}).puedeFechaCobroDesdeDetalle, isTrue);
      expect(usuario({'btnEditar3CH'}).puedeFechaCobroDesdeDetalle, isTrue);
      expect(usuario({'btnDetalleCH'}).puedeFechaCobroDesdeDetalle, isTrue);
      expect(usuario({'btnEditar1CH'}).puedeFechaCobroDesdeDetalle, isFalse);
    });

    test(
      'eliminar una accion no mira el estado: se conserva asi a proposito',
      () {
        // puedeEliminarAccion es un getter: no tiene parametro de estado.
        expect(usuario({'btnEliminarSegCH'}).puedeEliminarAccion, isTrue);
        expect(usuario({'btnDetalleCH'}).puedeEliminarAccion, isFalse);
      },
    );
  });

  group('bancos (vista 43)', () {
    test('un boton por operacion', () {
      expect(usuario({'btnNuevoB'}).puedeCrearBanco, isTrue);
      expect(usuario({'btnNuevoB'}).puedeEditarBanco, isFalse);
      expect(usuario({'btnEditarB'}).puedeEditarBanco, isTrue);
      expect(usuario({'btnEliminarB'}).puedeEliminarBanco, isTrue);
      expect(usuario({'btnEliminarB'}).puedeCrearBanco, isFalse);
    });
  });

  group('PermisosCheque.desde (la regla de esAdmin y de los botones)', () {
    UsuarioBtnEntity btn(String nombre, int permiso) => UsuarioBtnEntity(
      codUsuario: 1,
      codBtn: 1,
      nivelAcceso: permiso,
      audUsuario: 1,
      boton: nombre,
      permiso: permiso,
      pertenVist: 42,
    );

    test('ROLE_ADM es administrador; otros tipos no', () {
      PermisosCheque con(String? tipo) =>
          PermisosCheque.desde(tipoUsuario: tipo, botones: const []);
      expect(con('ROLE_ADM').esAdmin, isTrue);
      expect(con('ROLE_LIM').esAdmin, isFalse);
      expect(con('adm').esAdmin, isFalse);
      expect(con('').esAdmin, isFalse);
      expect(con(null).esAdmin, isFalse);
    });

    test('un boton cuenta con permiso distinto de 0', () {
      final p = PermisosCheque.desde(
        tipoUsuario: 'ROLE_LIM',
        botones: [btn('btnNuevoCH', 1), btn('btnTraspasoCH', 0)],
      );
      expect(p.botones, {'btnNuevoCH'});
      expect(p.puedeRegistrar, isTrue);
      expect(p.puedeTraspasar, isFalse);
    });

    test(
      'permiso 2 tambien cuenta: es la condicion literal de autorizarBtn',
      () {
        final p = PermisosCheque.desde(
          tipoUsuario: 'ROLE_LIM',
          botones: [btn('btnDetalleCH', 2)],
        );
        expect(p.puedeCompletar, isTrue);
      },
    );

    test('el administrador pasa aunque su lista de botones este vacia', () {
      final p = PermisosCheque.desde(
        tipoUsuario: 'ROLE_ADM',
        botones: const [],
      );
      expect(p.puedeRegistrar, isTrue);
      expect(p.puedeEditar('CER'), isTrue);
    });
  });

  test('igualdad por valor: el provider no avisa si nada cambio', () {
    expect(usuario({'a', 'b'}), usuario({'b', 'a'}));
    expect(usuario({'a'}), isNot(usuario({'a', 'b'})));
    expect(
      usuario({'a'}),
      isNot(const PermisosCheque(botones: {'a'}, esAdmin: true)),
    );
    expect(usuario({'a', 'b'}).hashCode, usuario({'b', 'a'}).hashCode);
  });
}
