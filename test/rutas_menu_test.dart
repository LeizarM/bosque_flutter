import 'package:bosque_flutter/core/config/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// El ítem del menú abre el módulo, y no la pantalla de «Página no encontrada».
///
/// **Por qué esto necesita un test.** Un path mal escrito compila perfecto: el
/// error aparece recién en producción, cuando alguien toca el ítem y cae en el
/// `errorBuilder`. Y es un error fácil de cometer, porque hacen falta DOS
/// entradas y sólo una es obvia:
///
///  - `/dashboard/<direccion>` adentro del `ShellRoute`, que es la que dibuja;
///  - `/<direccion>` afuera, que redirige a la anterior.
///
/// La segunda es la que se olvida. `menu_provider.dart:481` arma el destino con
/// `'/' + item.direccion` —sin `/dashboard`— así que sin ella el ítem no llega
/// nunca a la pantalla.
///
/// Los valores de `direccion` salen de `tb_vista` en SQL Server y son la fuente
/// de verdad; acá se copian a mano porque el test no habla con la base.
void main() {
  const direcciones = <String, String>{
    // codVista 24 — 'Permisos / Vacaciones / Abono Dias'
    'trhPermiso/permiso': 'PermisosRrhhScreen',
    // codVista 154 — 'Turnos Sabados'
    'trs_Sabados/Main': 'RolSabadosScreen',
  };

  late Set<String> paths;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);
    // Sólo se lee la configuración: no se navega, así que el `redirect` de nivel
    // superior —que consulta SecureStorage— no llega a ejecutarse.
    paths = _pathsDe(contenedor.read(routerProvider).configuration.routes);
  });

  for (final entrada in direcciones.entries) {
    final direccion = entrada.key;

    test('${entrada.value}: el sidebar navega a /$direccion y ahí hay algo', () {
      expect(
        paths,
        contains('/$direccion'),
        reason:
            'Falta la entrada de redirección de /$direccion. Sin ella el ítem '
            'del menú cae en el errorBuilder: menu_provider arma el destino '
            'como "/" + tb_vista.direccion, sin /dashboard.',
      );
    });

    test('${entrada.value}: /dashboard/$direccion dibuja la pantalla', () {
      expect(
        paths,
        contains('/dashboard/$direccion'),
        reason:
            'La ruta del ShellRoute tiene que ser EXACTAMENTE '
            '/dashboard/ + tb_vista.direccion, respetando mayúsculas.',
      );
    });
  }
}

/// Todos los `path` del árbol, aplanados. `ShellRoute` no tiene path propio:
/// sus hijos ya declaran el suyo completo, con `/dashboard` adelante.
Set<String> _pathsDe(List<RouteBase> rutas) => {
  for (final r in rutas) ...[
    if (r is GoRoute) r.path,
    ..._pathsDe(r.routes),
  ],
};
