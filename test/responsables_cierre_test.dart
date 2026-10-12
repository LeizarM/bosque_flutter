// Responsables del cierre (archivo SQL 81): la matriz de Verificar Cierre.
//
// Lo que estas pruebas cuidan (Marcelo, 2026-10-08):
// - Quién revisa qué lo deciden RRHH o un administrador; las reglas (sección,
//   sucursal, duplicados) son del servidor y su mensaje vuelve al diálogo.
// - Un cargo con la tarea y sin secciones se avisa: la recibe en "No aplica".
// - Archivo 86: las columnas salen del catálogo; una sección quitada no se ve
//   y una nueva sí. Crear, quitar y volver a pedir las decide el servidor.
// - Archivo 87: el registro de fuentes se administra desde la app; una fuente
//   en uso no se borra (el botón ni se activa) y el servidor dice por qué.
import 'package:bosque_flutter/core/state/cierre_operaciones_provider.dart';
import 'package:bosque_flutter/core/state/responsables_cierre_provider.dart';
import 'package:bosque_flutter/data/models/responsable_cierre_model.dart';
import 'package:bosque_flutter/domain/entities/responsable_cierre_entity.dart';
import 'package:bosque_flutter/domain/repositories/responsable_cierre_repository.dart';
import 'package:bosque_flutter/presentation/screens/estructura-organizacional/responsables_cierre_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements ResponsableCierreRepository {
  List<ResponsableCierre> filas;
  List<CandidatoCierre> candidatosHoy;
  String? rechazo;
  final pedidos = <String>[];
  List<SeccionCierre> catalogo = List.of(_catalogo);
  List<FuenteCierre> fuentesHoy = const [
    FuenteCierre(
      fuente: 'fn_tac_cierre_vales',
      nombre: 'Vales del arqueo',
      descripcion: 'Vales de los arqueos del día',
    ),
  ];

  _Repo(this.filas, this.candidatosHoy);

  @override
  Future<List<SeccionCierre>> secciones(int idTarRuti) async => catalogo;

  @override
  Future<List<FuenteCierre>> fuentes() async => fuentesHoy;

  @override
  Future<void> guardarSeccion({
    String? codigo,
    required String nombre,
    String? queRevisar,
    bool? porSucursal,
    String? fuente,
    bool? marcaPorFila,
    bool? firmaSola,
    int? obsDesde,
    String? diaRevisado,
    int? orden,
  }) async {
    if (rechazo != null) throw Exception(rechazo);
    pedidos.add(
      'seccion ${codigo ?? 'nueva'} $nombre fuente=$fuente suc=$porSucursal '
      'dia=$diaRevisado obs=$obsDesde',
    );
    if (codigo == null) {
      catalogo = [
        ...catalogo,
        SeccionCierre(codigo: 'G', nombre: nombre, fuente: fuente),
      ];
    }
  }

  List<FuenteCierre> registro = const [
    FuenteCierre(
      fuente: 'fn_tac_cierre_vales',
      nombre: 'Vales del arqueo',
      descripcion: 'Vales de los arqueos del día',
      secciones: 1,
      usadaPor: 'Vales del día',
    ),
    FuenteCierre(
      fuente: 'fn_tac_cierre_cajaChicaSinFactura',
      nombre: 'Caja chica sin factura',
    ),
  ];
  List<CandidatoFuente> candidatas = const [
    CandidatoFuente(fuente: 'fn_tac_cierre_chequesRechazados'),
  ];

  @override
  Future<List<FuenteCierre>> fuentesTodas() async => registro;

  @override
  Future<List<CandidatoFuente>> candidatasFuente() async => candidatas;

  @override
  Future<void> guardarFuente({
    required String fuente,
    required String nombre,
    String? descripcion,
    String? spMarcar,
  }) async {
    if (rechazo != null) throw Exception(rechazo);
    pedidos.add('fuente $fuente $nombre');
  }

  @override
  Future<void> activarFuente(String fuente, {required bool activa}) async {
    if (rechazo != null) throw Exception(rechazo);
    pedidos.add('${activa ? 'activar' : 'desactivar'} $fuente');
  }

  @override
  Future<void> borrarFuente(String fuente) async {
    pedidos.add('borrar $fuente');
    registro = registro.where((f) => f.fuente != fuente).toList();
  }

  @override
  Future<void> quitarSeccion(String codigo, {required bool quitar}) async {
    pedidos.add('${quitar ? 'quitar' : 'volver'} seccion $codigo');
    catalogo = [
      for (final x in catalogo)
        x.codigo == codigo
            ? SeccionCierre(
              codigo: x.codigo,
              nombre: x.nombre,
              porSucursal: x.porSucursal,
              propia: x.propia,
              vigente: !quitar,
            )
            : x,
    ];
  }

  @override
  Future<List<ResponsableCierre>> lista(int idTarRuti) async => filas;

  @override
  Future<List<CandidatoCierre>> candidatos(int idTarRuti) async =>
      candidatosHoy;

  @override
  Future<List<SucursalCaja>> sucursales() async => const [
    SucursalCaja(20, 'CENTRAL'),
    SucursalCaja(26, 'ACHOCALLA'),
  ];

  @override
  Future<void> agregar({
    required int idTarRuti,
    required String seccion,
    int? codSucursal,
    int? codCargoSucursal,
    int? codEmpleado,
    bool puedeAutorrevisar = false,
  }) async {
    if (rechazo != null) throw rechazo!;
    pedidos.add(
      'agregar $seccion suc=$codSucursal cs=$codCargoSucursal emp=$codEmpleado',
    );
  }

  @override
  Future<void> cambiarAutorrevision(ResponsableCierre fila, bool puede) async =>
      pedidos.add('propio ${fila.idRC}=$puede');

  @override
  Future<void> quitar(int idRC) async {
    pedidos.add('quitar $idRC');
    filas = filas.where((f) => f.idRC != idRC).toList();
  }
}

const _catalogo = [
  SeccionCierre(
    codigo: 'A',
    nombre: 'Arqueos de caja',
    porSucursal: true,
    propia: true,
  ),
  SeccionCierre(
    codigo: 'F',
    nombre: 'Caja fuerte',
    porSucursal: true,
    propia: true,
  ),
  SeccionCierre(codigo: 'T', nombre: 'Traspasos Caja AXA', propia: true),
  SeccionCierre(codigo: 'C', nombre: 'Cheques', propia: true),
  SeccionCierre(codigo: 'R', nombre: 'Tareas del día', propia: true),
];

ResponsableCierre _f(
  int idRC,
  String seccion, {
  int? cs = 176,
  int? emp,
  int? suc,
  bool activo = true,
}) => ResponsableCierreModel.fila({
  'idRC': idRC,
  'idTarRuti': 39,
  'seccion': seccion,
  'nombreSeccion': 'Sección $seccion',
  'codSucursal': suc,
  'nombreSucursal': suc == null ? 'Todas' : 'SUC $suc',
  'codCargoSucursal': cs,
  'cargo': 'JEFE DE CONTABILIDAD',
  'sucursalDelCargo': 'CENTRAL',
  'codEmpleado': emp,
  'personas': emp == null ? 'PAOLA RODRIGO' : 'HANS ANEIVA',
  'puedeAutorrevisar': 0,
  'estado': activo ? 1 : 0,
});

const _claudia = CandidatoCierre(
  esCargo: true,
  codCargoSucursal: 166,
  cargo: 'SUPERVISOR DE COBRANZAS',
  sucursal: 'CENTRAL',
  personas: 'CLAUDIA GABRIELA QUIROGA',
  tieneLaTarea: true,
);

Widget _app(_Repo repo) => ProviderScope(
  overrides: [responsableCierreRepoProvider.overrideWithValue(repo)],
  child: const MaterialApp(home: ResponsablesCierreScreen()),
);

Future<void> _ancho(WidgetTester t, double ancho) async {
  await t.binding.setSurfaceSize(Size(ancho, 1000));
  addTearDown(() => t.binding.setSurfaceSize(null));
}

void main() {
  test('el modelo lee la fila, el candidato y la sucursal', () {
    final f = ResponsableCierreModel.fila({
      'idRC': 7,
      'seccion': 'F ',
      'codSucursal': null,
      'nombreSucursal': null,
      'codCargoSucursal': 154,
      'puedeAutorrevisar': 1,
    });
    expect(f.codigoSeccion, 'F');
    expect(f.seccionVigente, isTrue);
    expect(f.nombreSucursal, 'Todas');
    expect(f.puedeAutorrevisar, isTrue);
    expect(f.claveResponsable, 'C154');

    final c = ResponsableCierreModel.candidato({
      'tipo': 'P',
      'codEmpleado': 56,
      'cargo': 'SUPERVISOR DE COBRANZAS',
      'sucursal': 'CENTRAL',
      'personas': 'CLAUDIA  GABRIELA',
      'tieneLaTarea': 1,
      'secciones': 0,
    });
    expect(c.esCargo, isFalse);
    expect(c.personas, 'CLAUDIA GABRIELA');
    expect(c.claveResponsable, 'P56');

    final s = ResponsableCierreModel.sucursal({
      'codSucursal': 26,
      'nombreSucursal': 'ACHOCALLA',
    });
    expect((s.codSucursal, s.nombre), (26, 'ACHOCALLA'));
  });

  test('agrupa por responsable, sin las filas dadas de baja', () {
    final s = ResponsablesCierreState(
      filas: PanelDatos(
        cargado: true,
        filas: [
          _f(1, 'A', suc: 20),
          _f(2, 'A', suc: 26),
          _f(3, 'R'),
          _f(4, 'T', cs: null, emp: 20),
          _f(5, 'C', activo: false),
        ],
      ),
      candidatos: const PanelDatos(
        cargado: true,
        filas: [
          _claudia,
          CandidatoCierre(
            esCargo: false,
            codEmpleado: 56,
            cargo: 'SUPERVISOR DE COBRANZAS',
            sucursal: 'CENTRAL',
            tieneLaTarea: true,
          ),
        ],
      ),
    );
    final r = s.responsables;
    expect(r, hasLength(2));
    final paola = r.firstWhere((x) => x.esCargo);
    expect(paola.filasDe('A'), hasLength(2));
    expect(paola.filasDe('C'), isEmpty);
    expect(r.firstWhere((x) => !x.esCargo).titulo, 'HANS ANEIVA');
    // La persona no se cuenta dos veces: el aviso es por cargo.
    expect(s.sinSecciones.map((c) => c.codCargoSucursal), [166]);
  });

  testWidgets('muestra la matriz y avisa del cargo sin secciones', (t) async {
    await _ancho(t, 1300);
    await t.pumpWidget(
      _app(_Repo([_f(1, 'A', suc: 20), _f(2, 'R')], [_claudia])),
    );
    await t.pumpAndSettle();

    expect(find.text('Arqueos de caja'), findsOneWidget);
    expect(find.text('SUC 20'), findsOneWidget);
    expect(find.text('Asignada'), findsOneWidget);
    expect(find.textContaining('Tienen la tarea pero ninguna'), findsOneWidget);
    expect(
      find.text('SUPERVISOR DE COBRANZAS · CENTRAL (CLAUDIA GABRIELA QUIROGA)'),
      findsOneWidget,
    );
  });

  testWidgets('asigna una sección al cargo del aviso', (t) async {
    await _ancho(t, 1300);
    final repo = _Repo([_f(1, 'A', suc: 20)], [_claudia]);
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();

    await t.tap(find.text('Agregar secciones'));
    await t.pumpAndSettle();
    expect(find.text('SUPERVISOR DE COBRANZAS · CENTRAL'), findsOneWidget);
    await t.tap(find.widgetWithText(ChoiceChip, 'Cheques'));
    await t.pumpAndSettle();
    expect(find.text('Esta sección es de toda la empresa.'), findsOneWidget);
    await t.tap(find.text('Asignar'));
    await t.pumpAndSettle();

    expect(repo.pedidos, ['agregar C suc=null cs=166 emp=null']);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('desde la celda de un cargo o persona que ya está en la matriz', (
    t,
  ) async {
    await _ancho(t, 1300);
    final repo = _Repo([
      _f(1, 'A', suc: 20),
      _f(4, 'R', cs: null, emp: 20),
    ], []);
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();

    // Orden alfabético: primero la persona (HANS), después el cargo (JEFE).
    // Caja fuerte de la persona y cheques del cargo.
    await t.tap(find.byTooltip('Asignar').at(1));
    await t.pumpAndSettle();
    expect(find.text('Asignar caja fuerte'), findsOneWidget);
    await t.tap(find.text('Asignar'));
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    await t.tap(find.byTooltip('Asignar').at(6));
    await t.pumpAndSettle();
    expect(find.text('Asignar cheques'), findsOneWidget);
    await t.tap(find.text('Asignar'));
    await t.pumpAndSettle();

    expect(repo.pedidos, [
      'agregar F suc=null cs=null emp=20',
      'agregar C suc=null cs=176 emp=null',
    ]);
  });

  testWidgets('si el servidor no acepta, su mensaje queda en el diálogo', (
    t,
  ) async {
    await _ancho(t, 1300);
    final repo = _Repo([], [_claudia])
      ..rechazo = 'Ese responsable ya revisa esa sección en esa sucursal.';
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();

    await t.tap(find.text('Agregar secciones'));
    await t.pumpAndSettle();
    await t.tap(find.text('Asignar'));
    await t.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text('Ese responsable ya revisa esa sección en esa sucursal.'),
      findsOneWidget,
    );
    expect(repo.pedidos, isEmpty);
  });

  testWidgets('quitar pide confirmación y cancelar no quita nada', (t) async {
    await _ancho(t, 1300);
    final repo = _Repo([_f(1, 'A', suc: 20)], []);
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();

    Future<void> abrirQuitar() async {
      await t.tap(find.text('SUC 20'));
      await t.pumpAndSettle();
      await t.tap(find.text('Quitar'));
      await t.pumpAndSettle();
    }

    await abrirQuitar();
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(repo.pedidos, isEmpty);

    await abrirQuitar();
    await t.tap(find.widgetWithText(FilledButton, 'Quitar'));
    await t.pumpAndSettle();
    expect(repo.pedidos, ['quitar 1']);
    expect(find.text('Nadie revisa el cierre todavía'), findsOneWidget);
  });

  testWidgets('en el celular cada responsable es una tarjeta', (t) async {
    await _ancho(t, 400);
    await t.pumpWidget(_app(_Repo([_f(1, 'A', suc: 20)], [])));
    await t.pumpAndSettle();

    expect(find.text('JEFE DE CONTABILIDAD · CENTRAL'), findsOneWidget);
    expect(find.text('Tareas del día'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  test('el modelo lee el catálogo y las fuentes', () {
    final x = ResponsableCierreModel.seccion({
      'seccion': 'G',
      'nombre': 'Vales del día',
      'porSucursal': 1,
      'propia': 0,
      'fuente': 'fn_tac_cierre_vales',
      'marcaPorFila': 0,
      'firmaSola': 1,
      'obsDesde': 2,
      'diaRevisado': 'M',
      'orden': 60,
      'vigente': 0,
      'responsables': 3,
    });
    expect(x.porSucursal, isTrue);
    expect(x.propia, isFalse);
    expect(x.marcaPorFila, isFalse);
    expect(x.obsDesde, 2);
    expect(x.diaRevisado, 'M');
    expect(x.vigente, isFalse);
    expect(ResponsableCierreModel.fuente({'fuente': 'fn_x'}).nombre, 'fn_x');
    expect(
      ResponsableCierreModel.fila({
        'seccion': 'G',
        'seccionVigente': 0,
      }).seccionVigente,
      isFalse,
    );
  });

  testWidgets('una sección quitada no es columna; una nueva sí', (t) async {
    await _ancho(t, 1400);
    final repo = _Repo([_f(1, 'A', suc: 20), _f(2, 'T')], [])
      ..catalogo = [
        for (final x in _catalogo)
          x.codigo == 'T'
              ? SeccionCierre(
                codigo: 'T',
                nombre: 'Traspasos Caja AXA',
                propia: true,
                vigente: false,
              )
              : x,
        const SeccionCierre(
          codigo: 'G',
          nombre: 'Vales del día',
          fuente: 'fn_tac_cierre_vales',
        ),
      ];
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();

    expect(find.text('Traspasos Caja AXA'), findsNothing);
    expect(find.text('Vales del día'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('crea una sección nueva con su fuente', (t) async {
    await _ancho(t, 1300);
    final repo = _Repo([_f(1, 'A', suc: 20)], []);
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();

    await t.tap(find.text('Secciones'));
    await t.pumpAndSettle();
    await t.tap(find.text('Nueva sección'));
    await t.pumpAndSettle();
    await t.enterText(
      find.widgetWithText(TextField, 'Nombre'),
      'Vales del día',
    );
    // La lista dice de dónde salen y qué trae cada opción.
    expect(find.textContaining('Secciones > Fuentes'), findsOneWidget);
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    expect(find.text('Vales de los arqueos del día'), findsWidgets);
    await t.tap(find.text('Vales del arqueo').last);
    await t.pumpAndSettle();
    await t.tap(find.text('El mismo día'));
    await t.pumpAndSettle();
    await t.tap(find.text('Guardar'));
    await t.pumpAndSettle();

    expect(repo.pedidos, [
      'seccion nueva Vales del día fuente=fn_tac_cierre_vales suc=false dia=M obs=1',
    ]);
    // Vuelve a la lista de secciones, que ya la tiene.
    expect(find.text('Secciones del cierre'), findsOneWidget);
    expect(find.text('Vales del día'), findsWidgets);
  });

  testWidgets('si el servidor no acepta la sección, su mensaje queda', (
    t,
  ) async {
    await _ancho(t, 1300);
    final repo = _Repo([], [])..rechazo = 'Ya hay una sección con ese nombre.';
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();

    await t.tap(find.text('Secciones'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Cambiar').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Guardar'));
    await t.pumpAndSettle();

    expect(find.text('Ya hay una sección con ese nombre.'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    expect(find.text('Guardando…'), findsNothing);
  });

  testWidgets('dejar de pedir pide confirmación; cancelar no cambia nada', (
    t,
  ) async {
    await _ancho(t, 1300);
    final repo = _Repo([_f(1, 'A', suc: 20)], []);
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();

    await t.tap(find.text('Secciones'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Dejar de pedirla').at(1));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(repo.pedidos, isEmpty);

    await t.tap(find.byTooltip('Dejar de pedirla').at(1));
    await t.pumpAndSettle();
    await t.tap(find.text('Dejar de pedirla'));
    await t.pumpAndSettle();
    expect(repo.pedidos, ['quitar seccion F']);
    expect(find.byTooltip('Volver a pedirla'), findsOneWidget);
  });

  Future<void> abrirFuentes(WidgetTester t) async {
    await t.tap(find.text('Secciones'));
    await t.pumpAndSettle();
    await t.tap(find.text('Fuentes'));
    await t.pumpAndSettle();
  }

  testWidgets('las fuentes: quién las usa, y en uso no se borran', (t) async {
    await _ancho(t, 1300);
    await t.pumpWidget(_app(_Repo([_f(1, 'A', suc: 20)], [])));
    await t.pumpAndSettle();
    await abrirFuentes(t);

    expect(find.text('Fuentes de las secciones'), findsOneWidget);
    expect(find.textContaining('La usa: Vales del día'), findsOneWidget);
    final borrar = find.widgetWithIcon(IconButton, Icons.delete_outline);
    expect(t.widget<IconButton>(borrar.at(0)).onPressed, isNull);
    expect(t.widget<IconButton>(borrar.at(1)).onPressed, isNotNull);
  });

  testWidgets('registra una consulta de la base como fuente', (t) async {
    await _ancho(t, 1300);
    final repo = _Repo([_f(1, 'A', suc: 20)], []);
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();
    await abrirFuentes(t);

    await t.tap(find.text('Registrar fuente'));
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('fn_tac_cierre_chequesRechazados').last);
    await t.pumpAndSettle();
    await t.enterText(
      find.widgetWithText(TextField, 'Nombre'),
      'Cheques rechazados',
    );
    await t.tap(find.text('Registrar'));
    await t.pumpAndSettle();

    expect(repo.pedidos, [
      'fuente fn_tac_cierre_chequesRechazados Cheques rechazados',
    ]);
    expect(find.text('Fuentes de las secciones'), findsOneWidget);
  });

  testWidgets('desactivar una en uso: el motivo del servidor se ve', (t) async {
    await _ancho(t, 1300);
    final repo = _Repo([_f(1, 'A', suc: 20)], [])
      ..rechazo =
          'La usa Vales del día: cámbiale la fuente o deja de pedirla antes.';
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();
    await abrirFuentes(t);

    await t.tap(find.byTooltip('Desactivar').first);
    await t.pumpAndSettle();
    expect(find.textContaining('cámbiale la fuente'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('borrar pide confirmación; cancelar no borra', (t) async {
    await _ancho(t, 1300);
    final repo = _Repo([_f(1, 'A', suc: 20)], []);
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();
    await abrirFuentes(t);

    final borrar = find.widgetWithIcon(IconButton, Icons.delete_outline).at(1);
    await t.tap(borrar);
    await t.pumpAndSettle();
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(repo.pedidos, isEmpty);

    await t.tap(find.widgetWithIcon(IconButton, Icons.delete_outline).at(1));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Borrar'));
    await t.pumpAndSettle();
    expect(repo.pedidos, ['borrar fn_tac_cierre_cajaChicaSinFactura']);
    expect(find.text('Caja chica sin factura'), findsNothing);
  });
}
