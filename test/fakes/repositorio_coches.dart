// Repositorio falso del catálogo de vehículos y datos de ejemplo. Lo usan las
// pruebas del notifier y las de la pantalla: sin backend ni login, con el
// registro de lo que se pidió y fallos que cada prueba enciende a voluntad.
import 'package:bosque_flutter/domain/entities/coche_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/repositories/coche_repository.dart';

CocheEntity cocheFalso(
  int id, {
  String placa = '0000-AAA',
  String marca = 'Suzuki',
  String clase = 'Minibus',
  int? anio = 2017,
  String color = 'Blanco',
  int sucursal = 20,
  String nombreSucursal = 'CENTRAL',
  int estado = 1,
}) => CocheEntity(
  idCoche: id,
  placa: placa,
  marca: marca,
  clase: clase,
  anio: anio,
  color: color,
  codSucursal: sucursal,
  nombreSucursal: nombreSucursal,
  estado: estado,
  audUsuario: 34,
);

/// Un trozo de la flota real: cuatro sucursales, un inactivo.
List<CocheEntity> cochesDeEjemplo() => [
  cocheFalso(
    1,
    placa: '917-SKP',
    marca: 'Toyota',
    clase: 'Camioneta',
    anio: 1996,
    sucursal: 25,
    nombreSucursal: 'GALPON EL ALTO',
  ),
  cocheFalso(
    2,
    placa: '2313-ZZD',
    marca: 'Nissan',
    clase: 'Camioneta',
    anio: 2009,
    color: 'Plata',
  ),
  cocheFalso(
    3,
    placa: '3878-KCK',
    marca: 'Foton',
    clase: 'Camion',
    anio: 2015,
    color: 'Plata',
  ),
  cocheFalso(
    4,
    placa: '4829-RZI',
    marca: 'Nissan',
    clase: 'Minibus',
    anio: 2018,
    sucursal: 24,
    nombreSucursal: 'SANTA CRUZ',
  ),
  cocheFalso(
    5,
    placa: '2456-YTP',
    marca: 'Suzuki',
    clase: 'Minibus',
    anio: 2010,
    color: 'Burdeo',
    sucursal: 24,
    nombreSucursal: 'SANTA CRUZ',
  ),
  cocheFalso(
    6,
    placa: '1053-FKE',
    marca: 'Toyota',
    clase: 'Camioneta',
    anio: 1995,
    color: 'Rojo',
    estado: 0,
  ),
  cocheFalso(
    7,
    placa: '4744-CEI',
    marca: 'Suzuki',
    clase: 'Minibus',
    anio: 2018,
    color: 'Burdeo',
    sucursal: 23,
    nombreSucursal: 'COCHABAMBA',
  ),
];

SucursalEntity sucursalFalsa(int cod, String nombre) => SucursalEntity(
  codSucursal: cod,
  nombre: nombre,
  codEmpresa: 6,
  codCiudad: 1,
  audUsuarioI: 0,
  empresa: EmpresaEntity(
    codEmpresa: 6,
    nombre: 'GENERAL',
    codPadre: 0,
    sigla: 'GEN',
    audUsuario: 0,
  ),
  nombreCiudad: 'La Paz',
  codSucursalPlanilla: 0,
  nombrePlanilla: '',
);

List<SucursalEntity> sucursalesDeEjemplo() => [
  sucursalFalsa(20, 'CENTRAL'),
  sucursalFalsa(23, 'COCHABAMBA'),
  sucursalFalsa(24, 'SANTA CRUZ'),
  sucursalFalsa(25, 'GALPON EL ALTO'),
];

class RepositorioCochesFalso implements CocheRepository {
  RepositorioCochesFalso({List<CocheEntity>? coches})
    : coches = [...(coches ?? cochesDeEjemplo())];

  final List<CocheEntity> coches;

  /// Lo que llegó a `registrar` y a `eliminar`, en orden.
  final List<CocheEntity> registrados = [];
  final List<int> eliminados = [];

  int lecturas = 0;

  /// Si no es null, la operación lanza esto.
  Object? falloAlObtener;
  Object? falloAlRegistrar;
  Object? falloAlEliminar;

  @override
  Future<List<CocheEntity>> obtener({int? codSucursal, int? estado}) async {
    lecturas++;
    if (falloAlObtener != null) throw falloAlObtener!;
    return [
      for (final c in coches)
        if ((codSucursal == null || c.codSucursal == codSucursal) &&
            (estado == null || c.estado == estado))
          c,
    ];
  }

  @override
  Future<BigInt> registrar(CocheEntity item) async {
    if (falloAlRegistrar != null) throw falloAlRegistrar!;
    registrados.add(item);
    if (item.idCoche == 0) {
      final id =
          coches.fold<int>(0, (m, c) => c.idCoche > m ? c.idCoche : m) + 1;
      // El backend devuelve el nombre de la sucursal por el JOIN; aquí se
      // resuelve contra las de ejemplo.
      final nombre =
          sucursalesDeEjemplo()
              .where((s) => s.codSucursal == item.codSucursal)
              .map((s) => s.nombre)
              .firstOrNull;
      coches.add(item.copyWith(idCoche: id, nombreSucursal: nombre));
      return BigInt.from(id);
    }
    final i = coches.indexWhere((c) => c.idCoche == item.idCoche);
    if (i >= 0) coches[i] = item;
    return BigInt.from(item.idCoche);
  }

  @override
  Future<void> eliminar(int idCoche, int audUsuario) async {
    if (falloAlEliminar != null) throw falloAlEliminar!;
    eliminados.add(idCoche);
    coches.removeWhere((c) => c.idCoche == idCoche);
  }
}
