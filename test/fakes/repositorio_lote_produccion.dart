import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/maquina_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/material_ingreso_entity.dart';
import 'package:bosque_flutter/domain/entities/material_salida_entity.dart';
import 'package:bosque_flutter/domain/entities/merma_entity.dart';
import 'package:bosque_flutter/domain/repositories/lote_produccion_repository.dart';

/// Un lote con los campos en cero, para no repetir treinta y cuatro argumentos
/// en cada prueba.
LoteProduccionEntity loteDePrueba({
  int idLp = 7,
  int numLote = 417,
  double utm = 0,
  String codArticulo = '',
  String datoArt = '',
}) => LoteProduccionEntity(
  idMa: 1,
  idLp: idLp,
  numLote: numLote,
  anio: 2026,
  fecha: DateTime(2026, 8, 19),
  hraInicioCorte: '13:00',
  hraInicio: '13:40',
  hraFin: '16:06',
  cantBobinasIngresoTotal: 0,
  pesoKilosTotalIngreso: 0,
  pesoTotalSalida: 0,
  pesoPaletaSalida: 0,
  pesoMaterialSalida: 0,
  cantResmaSalida: 0,
  cantHojasSalida: 0,
  mermaTotal: 0,
  diferenciaProduccion: 0,
  diferenciaProdResma: 0,
  cantEstimadaResma: 0,
  pesoBalanzaTotal: 0,
  estado: 1,
  obs: '',
  numCorte: 0,
  anioCorte: 2026,
  docNumOrdFab: 264410031,
  codEmpresa: 1,
  audUsuario: 0,
  codArticulo: codArticulo,
  datoArt: datoArt,
  articulo: datoArt,
  utm: utm,
  codArtEntrada: '',
  codArtSalida: '',
  db: '',
);

MaterialIngresoEntity bobina({
  required int idMi,
  required double pesoKilos,
  required double balanza,
}) => MaterialIngresoEntity(
  idMi: idMi,
  idLp: 7,
  codArticulo: 'BBH0650871200FBP',
  descripcion: 'BOBINA BOND HUESO',
  pesoKilos: pesoKilos,
  balanza: balanza,
  numImportacion: '',
  audUsuario: 0,
);

/// Repositorio falso que devuelve un lote fijo y **anota lo que le mandaron a
/// guardar**.
///
/// Sólo implementa lo que toca el detalle de un lote; el resto lo cubre
/// `noSuchMethod`, que Dart genera cuando una clase `implements` una interfaz y
/// declara un `noSuchMethod` concreto. Escribir a mano los ~15 métodos de
/// [LoteProduccionRepository] para una prueba que mira tres es ruido que
/// después hay que mantener — y si alguno se llamara por accidente, el
/// `noSuchMethod` lo hace explotar, que es justo lo que se quiere.
class RepositorioLoteProduccion implements LoteProduccionRepository {
  RepositorioLoteProduccion({
    this.ingresos = const [],
    this.articulos = const [],
  });

  final List<MaterialIngresoEntity> ingresos;
  final List<LoteProduccionEntity> articulos;

  /// La cabecera tal como viajó al backend.
  LoteProduccionEntity? cabeceraGuardada;

  /// El material de ingreso tal como viajó al backend.
  List<MaterialIngresoEntity>? ingresosGuardados;

  @override
  Future<List<MaterialIngresoEntity>> obtenerMaterialIngresoXLote(int idLp) async =>
      ingresos;

  @override
  Future<List<MaterialSalidaEntity>> obtenerMaterialSalidaXLote(int idLp) async =>
      const [];

  @override
  Future<List<MermaEntity>> obtenerMermaXLote(int idLp) async => const [];

  // Copias y no las listas de origen: `articulosProduccionProvider` ordena el
  // catalogo en el lugar, y sobre una lista constante `sort` revienta aunque
  // este vacia.
  @override
  Future<List<LoteProduccionEntity>> obtenerArticulos() async => [...articulos];

  @override
  Future<List<EmpresaEntity>> obtenerEmpresas() async => [];

  @override
  Future<List<MaquinaProduccionEntity>> obtenerMaquinas() async => [];

  @override
  Future<bool> registrarLoteProduccion(LoteProduccionEntity lote) async {
    cabeceraGuardada = lote.clonar();
    return true;
  }

  @override
  Future<bool> registrarMaterialIngreso(
    List<MaterialIngresoEntity> lista,
  ) async {
    ingresosGuardados = [
      for (final f in lista)
        bobina(idMi: f.idMi, pesoKilos: f.pesoKilos, balanza: f.balanza),
    ];
    return true;
  }

  @override
  Future<bool> registrarMaterialSalida(List<MaterialSalidaEntity> l) async =>
      true;

  @override
  Future<bool> registrarMerma(List<MermaEntity> l) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
