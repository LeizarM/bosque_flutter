import 'package:bosque_flutter/domain/entities/cargo_entity.dart';

/// Utilidades para trabajar con cargos
class CargosUtils {
  /// Aplana la estructura jerárquica de cargos a una lista plana
  static List<CargoEntity> aplanarCargos(List<CargoEntity> cargosJerarquicos) {
    List<CargoEntity> listaPlana = [];

    void agregarRecursivo(List<CargoEntity> cargos) {
      for (var cargo in cargos) {
        listaPlana.add(cargo);
        if (cargo.items.isNotEmpty) {
          agregarRecursivo(cargo.items);
        }
      }
    }

    agregarRecursivo(cargosJerarquicos);
    return listaPlana;
  }

  /// Obtiene todos los cargos de una rama específica
  static List<CargoEntity> obtenerCargosDeRama(
    CargoEntity raiz,
    List<CargoEntity> todosCargos,
    CargoEntity cargoAMover,
  ) {
    List<CargoEntity> cargosRama = [raiz];
    Set<int> visitados = {raiz.codCargo}; // Prevenir ciclos

    void agregarDescendientes(int codPadre) {
      for (var c in todosCargos) {
        if (c.codCargoPadre == codPadre &&
            !visitados.contains(c.codCargo) &&
            c.codCargo != cargoAMover.codCargo) {
          visitados.add(c.codCargo);
          cargosRama.add(c);
          agregarDescendientes(c.codCargo);
        }
      }
    }

    agregarDescendientes(raiz.codCargo);
    return cargosRama;
  }

  /// Filtra las ramas principales (nivel <= 1) excluyendo el cargo actual
  static List<CargoEntity> obtenerRamasPrincipales(
    List<CargoEntity> todosCargos,
    CargoEntity cargoActual,
  ) {
    return todosCargos
        .where(
          (c) =>
              c.nivel <= 1 &&
              c.codCargo != cargoActual.codCargo &&
              c.codCargo != cargoActual.codCargoPadre,
        )
        .toList();
  }

  /// Verifica si un cargo tiene dependencias
  static bool tieneDependencias(CargoEntity cargo) {
    return cargo.tieneEmpleadosActivos > 0 || cargo.numHijosActivos > 0;
  }

  /// Verifica si un cargo tiene subordinados
  static bool tieneSubordinados(CargoEntity cargo) {
    return cargo.numHijosActivos > 0;
  }
}
