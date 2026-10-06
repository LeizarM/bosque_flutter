// Arnes de las pruebas de pantalla del modulo de cheques: monta la app con el
// repositorio falso, los permisos que cada prueba elija y la tipografia real.
//
// Sigue a `test/depositos_cheques_pantallas_test.dart`: los widgets de pantalla
// se montan un fotograma despues de `ResponsiveBreakpoints` y Roboto se carga
// aparte, porque con la fuente de reemplazo del test el texto se ensancha y
// desborda filas que en la app caben.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart'
    show obtenerBancos;
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/documento_pdf_cheque.dart';

import 'repositorio_cheques.dart';

// ── Permisos de ejemplo ────────────────────────────────────────────────────

/// Administrador: ve todo, tambien con el cheque cerrado.
const permisosAdmin = PermisosCheque(botones: <String>{}, esAdmin: true);

/// Un cajero: registra, edita cheques abiertos y completa.
const permisosCajero = PermisosCheque(
  botones: <String>{
    PermisosCheque.btnNuevo,
    PermisosCheque.btnEditar,
    PermisosCheque.btnDetalle,
  },
  esAdmin: false,
);

/// Sin ningun boton de la vista 42.
const permisosNinguno = PermisosCheque.ninguno;

PermisosCheque permisosCon(Iterable<String> botones) =>
    PermisosCheque(botones: botones.toSet(), esAdmin: false);

// ── Datos de ejemplo ───────────────────────────────────────────────────────

/// El login de las pruebas **es el del bug que se corrigio**: entra con la
/// empresa 6 (GENERAL, sin cheques ni clientes) y el login no trae el nombre de
/// la empresa. Si algo del modulo vuelve a leer `codEmpresa` o `nombreEmpresa`
/// de la sesion, las pruebas piden las cosas de la empresa 6 y fallan.
LoginEntity loginCheques({String tipo = 'ROLE_LIM'}) =>
    LoginEntity.fromJson(<String, dynamic>{
      'tipoUsuario': tipo,
      'codUsuario': 34,
      'codEmpresa': 6,
      'nombreEmpresa': '',
    });

final bancosFalsos = [
  BancoEntity(codBanco: 7, nombre: 'BANCO UNION', audUsuario: 1, fila: 1),
  BancoEntity(codBanco: 8, nombre: 'BANCO MERCANTIL', audUsuario: 1, fila: 2),
];

SocioNegocioEntity clienteDeCheque(String cod, String nombre) =>
    SocioNegocioEntity(
      codCliente: cod,
      datoCliente: nombre,
      razonSocial: nombre,
      nit: '1',
      codCiudad: 1,
      datoCiudad: 'La Paz',
      esVigente: 'Y',
      codEmpresa: 1,
      audUsuario: 0,
      nombreCompleto: nombre,
    );

/// El «ahora» de la grilla en las pruebas de pantalla: con el rango de recepcion
/// por defecto (hoy menos tres meses) pide del 03/07/2026 al 03/10/2026. Va con
/// hora para comprobar que el rango sale sin ella.
final DateTime relojFijoCheques = DateTime(2026, 10, 3, 16, 20);

/// Hoy, sin hora. Las fechas de las acciones no pueden ser anteriores a hoy y
/// el calendario abre en esta fecha.
DateTime hoyDeLaPrueba() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

String isoDia(DateTime f) =>
    '${f.year.toString().padLeft(4, '0')}-'
    '${f.month.toString().padLeft(2, '0')}-'
    '${f.day.toString().padLeft(2, '0')}';

// ── Combos de los filtros ──────────────────────────────────────────────────

/// El desplegable «Empresa» de los filtros. Hay otro desplegable de enteros
/// (Sucursal) y no se puede buscar «el primero»: se piden por su marco.
Finder comboEmpresa() => find.descendant(
  of: find.byKey(const ValueKey('combo-empresa')),
  matching: find.byType(DropdownButtonFormField<int>),
);

/// El desplegable «Sucursal» de los filtros.
Finder comboSucursal() => find.descendant(
  of: find.byKey(const ValueKey('combo-sucursal')),
  matching: find.byType(DropdownButtonFormField<int>),
);

// ── Montaje ────────────────────────────────────────────────────────────────

/// Carga las fuentes: con la de reemplazo todos los glifos miden igual y el
/// texto se ensancha. Va en el `setUpAll` de cada archivo.
///
/// Roboto es la del tema de la app. **Plus Jakarta Sans y JetBrains Mono** son
/// las del modulo (`ChequesScope`): sin ellas la pantalla se mediria con la de
/// reemplazo y aparecerian desbordes que en la app no existen.
Future<void> cargarRoboto() async {
  const archivos = ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold'];
  final cargador = FontLoader('Roboto');
  for (final archivo in archivos) {
    final f = File('assets/fonts/$archivo.ttf');
    if (f.existsSync()) {
      cargador.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
  }
  await cargador.load();

  const propias = {
    'PlusJakartaSans': ['400', '500', '600', '700'],
    'JetBrainsMono': ['400', '500', '700'],
  };
  for (final e in propias.entries) {
    final propia = FontLoader(e.key);
    for (final peso in e.value) {
      final f = File('assets/fonts/${e.key}-$peso.ttf');
      if (f.existsSync()) {
        propia.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await propia.load();
  }
}

/// La app de prueba: tema real, localizacion en espanol, breakpoints de
/// Bosque y los providers del modulo sustituidos.
Widget appCheques({
  required Widget hijo,
  required RepositorioChequesFalso repo,
  PermisosCheque permisos = permisosAdmin,
  List<BancoEntity>? bancos,
  LoginEntity? login,
  List<Override> extra = const [],
}) {
  return ProviderScope(
    overrides: [
      chequesRepositoryProvider.overrideWithValue(repo),
      relojChequesProvider.overrideWithValue(() => relojFijoCheques),
      permisosChequeProvider.overrideWithValue(permisos),
      userProvider.overrideWith(
        (ref) => UserStateNotifier.sinStorage(login ?? loginCheques()),
      ),
      obtenerBancos.overrideWith((ref) async => bancos ?? bancosFalsos),
      ...extra,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder:
          (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: ResponsiveUtilsBosque.breakpoints,
          ),
      // En la app viven dentro del Scaffold del dashboard (ShellRoute) y se
      // montan cuando los breakpoints ya se resolvieron.
      home: Scaffold(body: UnFotogramaDespues(child: hijo)),
    ),
  );
}

/// Fija el tamano de la ventana, monta [app] y deja pasar los fotogramas que
/// hacen falta para que la pantalla pida y pinte sus datos. `pump()` y no
/// `pumpAndSettle()`: una barra de progreso anima en bucle.
Future<void> montar(
  WidgetTester tester,
  Widget app, {
  double ancho = 1400,
  double? alto,
}) async {
  tester.view.physicalSize = Size(ancho, alto ?? (ancho <= 450 ? 844 : 900));
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(app);
  await esperar(tester);
}

/// Deja correr las peticiones falsas y las animaciones cortas.
Future<void> esperar(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Elige [etiqueta] (Traspaso, A Custodio o Dar Custodia) en la barra de
/// escritorio: con dos o tres permisos hay que abrir antes el menu «Custodia»;
/// con uno solo la accion es un boton directo y no hay menu que abrir.
Future<void> tocarCustodia(WidgetTester tester, String etiqueta) async {
  final menu = find.text('Custodia');
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu);
    await esperar(tester);
  }
  await tester.tap(find.text(etiqueta));
  await esperar(tester);
}

/// Texto al [factor] (1.5 = 150 %).
void conTexto(WidgetTester tester, double factor) {
  tester.platformDispatcher.textScaleFactorTestValue = factor;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Captura los errores de dibujo (desbordes) mientras corre [cuerpo]. Se
/// restaura el manejador antes de cualquier `expect`: el binding lo exige.
Future<List<FlutterErrorDetails>> capturandoErrores(
  Future<void> Function() cuerpo,
) async {
  final errores = <FlutterErrorDetails>[];
  final previo = FlutterError.onError;
  FlutterError.onError = errores.add;
  try {
    await cuerpo();
  } finally {
    FlutterError.onError = previo;
  }
  for (final e in errores) {
    debugPrint('DETALLE DE ERROR DE DIBUJO:\n$e');
  }
  return errores;
}

/// Monta [child] un fotograma despues. En el arnes de prueba la pantalla
/// nacería en el mismo fotograma que `ResponsiveBreakpoints`, antes de que este
/// resuelva el punto de quiebre, y por un instante se dibujaria el diseno
/// equivocado (desbordes de un fotograma que la app real nunca ve).
class UnFotogramaDespues extends StatefulWidget {
  const UnFotogramaDespues({super.key, required this.child});

  final Widget child;

  @override
  State<UnFotogramaDespues> createState() => _UnFotogramaDespuesState();
}

class _UnFotogramaDespuesState extends State<UnFotogramaDespues> {
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _listo = true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      _listo ? widget.child : const SizedBox.shrink();
}

// ── Documento PDF: visor y selector de archivos falsos ─────────────────────

/// El visor de PDF de las pruebas: anota lo que se le pidio abrir en vez de
/// montar `PdfPreview` (que usa plugins que `flutter test` no tiene). Se inyecta
/// con `visorPdfChequeProvider.overrideWithValue(visor.abrir)`.
class VisorPdfFalso {
  final List<({Uint8List bytes, String titulo, String nombreArchivo})> abiertos =
      [];

  Future<void> abrir(
    BuildContext context, {
    required Uint8List bytes,
    required String titulo,
    required String nombreArchivo,
  }) async {
    abiertos.add((bytes: bytes, titulo: titulo, nombreArchivo: nombreArchivo));
  }
}

/// El selector de archivos de las pruebas: devuelve [archivo] (o null, como si el
/// usuario cancelara) y cuenta cuantas veces se abrio. Se inyecta con
/// `selectorPdfChequeProvider.overrideWithValue(selector.elegir)`.
class SelectorPdfFalso {
  SelectorPdfFalso([this.archivo]);

  ArchivoPdfElegido? archivo;
  int aperturas = 0;

  /// Si se asigna, el selector falla con esto (la plataforma no lo pudo abrir).
  Object? error;

  Future<ArchivoPdfElegido?> elegir() async {
    aperturas++;
    if (error != null) throw error!;
    return archivo;
  }
}

/// Un archivo de [tamano] bytes que empieza como un PDF.
ArchivoPdfElegido archivoPdfFalso(String nombre, {int tamano = 120000}) {
  final bytes = Uint8List(tamano);
  const cabecera = [0x25, 0x50, 0x44, 0x46, 0x2d]; // %PDF-
  for (var i = 0; i < cabecera.length && i < tamano; i++) {
    bytes[i] = cabecera[i];
  }
  return ArchivoPdfElegido(nombre: nombre, bytes: bytes);
}
