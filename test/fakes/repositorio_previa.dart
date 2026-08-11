import 'package:bosque_flutter/domain/entities/programador_dependiente_entity.dart';
import 'package:bosque_flutter/domain/repositories/rol_sabados_repository.dart';

/// Lo que se le pidió al backend, para poder afirmarlo en un test.
class LlamadaPrevia {
  const LlamadaPrevia({
    required this.codEmpleado,
    required this.codSucursal,
    required this.alcance,
    required this.idRol,
  });

  final int codEmpleado;
  final int codSucursal;
  final String alcance;
  final int idRol;

  @override
  String toString() =>
      'previsualizar(emp:$codEmpleado, suc:$codSucursal, $alcance, rol:$idRol)';
}

/// Repositorio falso que **anota lo que le preguntaron**.
///
/// Sólo implementa `previsualizarDependientes`; el resto lo cubre
/// `noSuchMethod`, que en Dart genera los reenvíos automáticos cuando una clase
/// `implements` una interfaz y declara un `noSuchMethod` concreto. Escribir a
/// mano los ~40 métodos de [RolSabadosRepository] para un test que mira uno
/// solo es ruido que después hay que mantener cada vez que la interfaz crece —
/// y si alguno se llamara por accidente, el `noSuchMethod` lo hace explotar,
/// que es justo lo que se quiere.
class RepositorioPrevia implements RolSabadosRepository {
  final List<LlamadaPrevia> llamadas = [];

  @override
  Future<List<ProgramadorDependienteEntity>> previsualizarDependientes({
    required int codEmpleado,
    required int codSucursal,
    required String alcance,
    required int idRol,
  }) async {
    llamadas.add(
      LlamadaPrevia(
        codEmpleado: codEmpleado,
        codSucursal: codSucursal,
        alcance: alcance,
        idRol: idRol,
      ),
    );
    // Dos directos, uno de ellos fuera del rol, y uno más abajo sólo cuando se
    // pide el árbol entero: alcanza para distinguir las cuatro combinaciones.
    return [
      const ProgramadorDependienteEntity(
        idProgramador: 0,
        codProgramador: 65,
        profundidad: 1,
        codDependiente: 223,
        nombreDependiente: 'BUITRAGO JULIO ANDRES',
        sucDependiente: 20,
        sucursal: 'CENTRAL',
        enElRol: 1,
      ),
      const ProgramadorDependienteEntity(
        idProgramador: 0,
        codProgramador: 65,
        profundidad: 1,
        codDependiente: 245,
        nombreDependiente: 'HOWARD ROGER',
        sucDependiente: 20,
        sucursal: 'CENTRAL',
        enElRol: 0,
      ),
      if (alcance == 'SUBARBOL')
        const ProgramadorDependienteEntity(
          idProgramador: 0,
          codProgramador: 65,
          profundidad: 2,
          codDependiente: 206,
          nombreDependiente: 'BALDERRAMA CRISTHIAN GONZALO',
          sucDependiente: 26,
          sucursal: 'ACHOCALLA',
          enElRol: 1,
        ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
