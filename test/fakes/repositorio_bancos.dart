// Repositorio falso de bancos para las pruebas de pantalla: guarda la lista en
// memoria, asi un alta, una edicion o una baja se ven al releer, y anota las
// llamadas y los cuerpos que ChequesImpl/BancosImpl mandarian al backend.
import 'package:bosque_flutter/data/models/banco_registro_model.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_registro_entity.dart';
import 'package:bosque_flutter/domain/repositories/bancos_repository.dart';

BancoEntity bancoFalso(int cod, String nombre) =>
    BancoEntity(codBanco: cod, nombre: nombre, audUsuario: 1, fila: cod);

/// Unos bancos de ejemplo, en orden alfabetico como los da el servidor.
List<BancoEntity> bancosDeEjemplo() => [
  bancoFalso(8, 'BANCO MERCANTIL SANTA CRUZ'),
  bancoFalso(7, 'BANCO UNION'),
  bancoFalso(12, 'BISA'),
];

class RepositorioBancosFalso implements BancosRepository {
  RepositorioBancosFalso({List<BancoEntity>? bancos})
    : bancos = bancos ?? bancosDeEjemplo();

  List<BancoEntity> bancos;

  /// Orden de las llamadas, por nombre de metodo.
  final List<String> llamadas = [];

  /// Los cuerpos JSON de las escrituras.
  final List<({String metodo, Map<String, dynamic> cuerpo})> cuerpos = [];

  Object? errorLectura;
  Object? errorEscritura;

  /// Sustituye a `listar`; sirve para controlar cuando responde.
  Future<List<BancoEntity>> Function()? alListar;

  int contar(String metodo) => llamadas.where((m) => m == metodo).length;

  Map<String, dynamic> ultimoCuerpo(String metodo) =>
      cuerpos.lastWhere((c) => c.metodo == metodo).cuerpo;

  @override
  Future<List<BancoEntity>> listar() async {
    llamadas.add('listar');
    if (alListar != null) return alListar!();
    if (errorLectura != null) throw errorLectura!;
    return List.of(bancos);
  }

  @override
  Future<BigInt> registrar(BancoRegistroEntity registro) async {
    llamadas.add('registrar');
    cuerpos.add((
      metodo: 'registrar',
      cuerpo: BancoRegistroModel.fromEntity(registro).toJson(),
    ));
    if (errorEscritura != null) throw errorEscritura!;
    final nombre = registro.nombre.trim();
    if (registro.esAlta) {
      final nuevo =
          bancos.fold<int>(0, (m, b) => b.codBanco > m ? b.codBanco : m) + 1;
      bancos = [...bancos, bancoFalso(nuevo, nombre)];
      return BigInt.from(nuevo);
    }
    bancos = [
      for (final b in bancos)
        if (b.codBanco == registro.codBanco)
          bancoFalso(b.codBanco, nombre)
        else
          b,
    ];
    return BigInt.from(registro.codBanco);
  }

  @override
  Future<BigInt> eliminar(int codBanco) async {
    llamadas.add('eliminar');
    cuerpos.add((metodo: 'eliminar', cuerpo: {'id': codBanco}));
    if (errorEscritura != null) throw errorEscritura!;
    bancos = [
      for (final b in bancos)
        if (b.codBanco != codBanco) b,
    ];
    return BigInt.from(codBanco);
  }
}
