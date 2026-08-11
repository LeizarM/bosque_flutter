import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entregas_location_banner.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entregas_route_status_bar.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entregas_tabla_desktop.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entregas_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Verifica que el módulo de Entregas se dibuje sin desbordes en móvil, tablet
/// y escritorio.
///
/// `flutter analyze` no ve esto: un `Row` que no entra compila perfecto y recién
/// falla al renderizar, con la franja amarilla y negra. Estos tests renderizan
/// de verdad a cada ancho y fallan si aparece un `RenderFlex overflowed`.
///
/// Los textos son del largo real que devuelve la base: nombres de cliente de
/// SAP y direcciones de El Alto con saltos de línea. Con `'Cliente 1'` y
/// `'Calle 2'` no se detecta absolutamente nada.
void _sinDesborde(WidgetTester tester, String donde) {
  final e = tester.takeException();
  expect(e, isNull, reason: 'Desborde de layout en $donde');
}

EntregaEntity _entrega({
  required int docEntry,
  required String cardName,
  required String direccion,
  int fueEntregado = 0,
}) {
  // La entidad tiene 47 campos obligatorios (espeja la tabla completa), asi que
  // se rellenan todos. Solo importan los que la tabla dibuja.
  return EntregaEntity(
    idEntrega: docEntry,
    docEntry: docEntry,
    docNum: 263830311,
    docNumF: 0,
    factura: 1640,
    docDate: DateTime(2026, 7, 8),
    docTime: '1449',
    cardCode: 'IDA026',
    cardName: cardName,
    addressEntregaFac: direccion,
    addressEntregaMat: direccion,
    vendedor: 'David Quispe',
    itemCode: 'PBH065067087ABO-B',
    dscription: 'PAPEL BOND HUESO 075G 067X087CM 500HJS  B-PRISME',
    whsCode: '1',
    quantity: 60,
    openQty: 60,
    db: 'ESP',
    valido: 'V',
    peso: 1136.4,
    cochePlaca: '917-SKP',
    prioridad: 'N',
    tipo: 'Factura',
    obsF: '',
    fueEntregado: fueEntregado,
    fechaEntrega: DateTime(2026, 8, 10, 17, 26),
    latitud: -16.5,
    longitud: -68.15,
    direccionEntrega: direccion,
    obs: '',
    codSucursalChofer: 1,
    codCiudadChofer: 1,
    audUsuario: 1,
    fechaNota: null,
    nombreCompleto: 'ROLY AARON CASTAÑO HUANCA',
    diferenciaMinutos: 0,
    codEmpleado: 222,
    codSucursal: 1,
    cargo: null,
    flag: 0,
    ord: 0,
    fechaEntregaCad: null,
    rutaDiaria: 0,
    fechaInicio: null,
    fechaFin: null,
    fechaInicioRutaCad: null,
    fechaFinRutaCad: null,
    estatusRuta: null,
    uchofer: 222,
  );
}

/// Envuelve como lo hace la app: `ResponsiveBreakpoints` es obligatorio porque
/// `ResponsiveUtilsBosque` lo consulta para decidir el padding.
Widget _app(Widget child, {bool oscuro = false}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      brightness: oscuro ? Brightness.dark : Brightness.light,
      colorSchemeSeed: Colors.green,
    ),
    builder: (context, widget) => ResponsiveBreakpoints.builder(
      child: widget!,
      breakpoints: const [
        Breakpoint(start: 0, end: 450, name: MOBILE),
        Breakpoint(start: 451, end: 800, name: TABLET),
        Breakpoint(start: 801, end: 1920, name: DESKTOP),
        Breakpoint(start: 1921, end: double.infinity, name: '4K'),
      ],
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  final tamanos = <String, Size>{
    'móvil 360×740': const Size(360, 740),
    'móvil chico 320×568': const Size(320, 568),
    'móvil ancho 414×896': const Size(414, 896),
    'tablet vertical 768×1024': const Size(768, 1024),
    'tablet horizontal 1024×768': const Size(1024, 768),
    'escritorio 1440×900': const Size(1440, 900),
    'escritorio ancho 1920×1080': const Size(1920, 1080),
  };

  // Nombre y dirección reales del registro que se ve en la pantalla.
  const nombreLargo = 'I.D.A. - IMPRESIÓN DESARROLLO Y ASESORAMIENTO';
  const direccionLarga =
      'C/ILLIMANI N°50 Z/ALTO LIMA  ENTRE LA CALLE ACHACHICALA Y AV/\n'
      'CHACALTAYA\n\nEL ALTO\nBOLIVIA';

  for (final entrada in tamanos.entries) {
    final nombre = entrada.key;
    final size = entrada.value;

    Future<void> montar(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(child));
      await tester.pumpAndSettle();
    }

    group(nombre, () {
      testWidgets('barra de ruta, sin iniciar y sin ubicación', (tester) async {
        await montar(
          tester,
          EntregasRouteStatusBar(
            rutaIniciada: false,
            isLocationEnabled: false,
            isProcessing: false,
            entregasVacias: false,
            onIniciarRuta: () {},
            onFinalizarRuta: () {},
          ),
        );
        _sinDesborde(tester, 'barra de ruta sin iniciar en $nombre');
      });

      testWidgets('barra de ruta, iniciada con fecha', (tester) async {
        await montar(
          tester,
          EntregasRouteStatusBar(
            rutaIniciada: true,
            fechaInicio: DateTime(2026, 8, 10, 17, 26),
            isLocationEnabled: true,
            isProcessing: false,
            entregasVacias: false,
            onIniciarRuta: () {},
            onFinalizarRuta: () {},
          ),
        );
        _sinDesborde(tester, 'barra de ruta iniciada en $nombre');
      });

      testWidgets('banner de ubicación desactivada', (tester) async {
        await montar(
          tester,
          EntregasLocationBanner(
            isLocationEnabled: false,
            onVerifyPermissions: () {},
          ),
        );
        _sinDesborde(tester, 'banner de ubicación en $nombre');
      });

      testWidgets('contadores del encabezado', (tester) async {
        await montar(
          tester,
          const Row(
            children: [
              EntregasStat(valor: '12', etiqueta: 'FACTURAS'),
              SizedBox(width: EntregasUI.s6),
              EntregasStat(valor: '148', etiqueta: 'PRODUCTOS'),
            ],
          ),
        );
        _sinDesborde(tester, 'contadores en $nombre');
      });
    });
  }

  // La tabla solo se usa en escritorio; se prueba en los anchos donde vive.
  for (final entrada in {
    'escritorio 1024×768': const Size(1024, 768),
    'escritorio 1440×900': const Size(1440, 900),
    'escritorio ancho 1920×1080': const Size(1920, 1080),
  }.entries) {
    testWidgets('tabla de escritorio sin desbordes en ${entrada.key}',
        (tester) async {
      tester.view.physicalSize = entrada.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          EntregasTablaDesktop(
            filteredEntregas: [
              MapEntry(1, [
                _entrega(
                  docEntry: 1107,
                  cardName: nombreLargo,
                  direccion: direccionLarga,
                ),
                _entrega(
                  docEntry: 1107,
                  cardName: nombreLargo,
                  direccion: direccionLarga,
                ),
              ]),
              MapEntry(2, [
                _entrega(
                  docEntry: 2048,
                  cardName: 'EDITORIAL DEL ESTADO 2',
                  direccion:
                      'CALLE 3 NRO 22 ESQ SEMPERTEGUI  EL ALTO BOLIVIA',
                  fueEntregado: 1,
                ),
              ]),
            ],
            rutaIniciada: true,
            onMarcarEntrega: (_) {},
            sortColumnIndex: 0,
            sortAscending: true,
            onSort: (_, __) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      _sinDesborde(tester, 'tabla en ${entrada.key}');
    });
  }

  testWidgets('la tabla dibuja SOLO las filas que existen', (tester) async {
    // El bug que motivó el rediseño: PaginatedDataTable con rowsPerPage=8
    // pintaba 8 franjas aunque hubiera una sola entrega. Con dos documentos
    // tiene que haber exactamente dos botones/estados, no ocho.
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        EntregasTablaDesktop(
          filteredEntregas: [
            MapEntry(1, [
              _entrega(
                docEntry: 1,
                cardName: nombreLargo,
                direccion: direccionLarga,
              ),
            ]),
            MapEntry(2, [
              _entrega(
                docEntry: 2,
                cardName: 'EDITORIAL DEL ESTADO 2',
                direccion: 'CALLE 3 NRO 22',
                fueEntregado: 1,
              ),
            ]),
          ],
          rutaIniciada: true,
          onMarcarEntrega: (_) {},
          sortColumnIndex: null,
          sortAscending: true,
          onSort: (_, __) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Entregado'), findsOneWidget);
    // Un solo botón "Marcar": la fila ya entregada muestra un check, no un
    // botón deshabilitado que invita a un clic que no hace nada.
    expect(find.widgetWithText(FilledButton, 'Marcar'), findsOneWidget);
    _sinDesborde(tester, 'conteo de filas');
  });

  testWidgets('el estado se lee en modo oscuro', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        const Row(
          children: [
            EstadoEntregaPill(entregado: true),
            SizedBox(width: 8),
            EstadoEntregaPill(entregado: false),
          ],
        ),
        oscuro: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Entregado'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    _sinDesborde(tester, 'pastillas en modo oscuro');
  });
}
