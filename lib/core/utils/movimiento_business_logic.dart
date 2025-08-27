class MovimientoBusinessLogic {
  /// Tipos de contenedores según el response
  static const String CONTENEDOR = 'CONTENEDOR';
  static const String VEHICULO = 'VEHICULO';
  static const String MONTACARGA = 'MONTACARGA';
  static const String MAQUINA = 'MAQUINA';

  /// Tipos de movimiento
  static const String ENTRADA = 'Entrada';
  static const String SALIDA = 'Salida';
  static const String TRASPASO = 'Traspaso';

  /// Determina automáticamente el tipo de movimiento basado en origen y destino
  static String determinarTipoMovimiento({
    required String claseOrigen,
    required String? claseDestino,
  }) {
    // Si no hay destino, no podemos determinar el tipo
    if (claseDestino == null) {
      return ENTRADA; // Por defecto
    }

    // Reglas de negocio exactas según las restricciones:

    // 1. De VEHICULO hacia CONTENEDOR = ENTRADA (Ingreso)
    if (claseOrigen == VEHICULO && claseDestino == CONTENEDOR) {
      return ENTRADA;
    }

    // 2. De CONTENEDOR hacia VEHICULO/MAQUINA/MONTACARGA = SALIDA
    if (claseOrigen == CONTENEDOR &&
        (claseDestino == VEHICULO ||
            claseDestino == MONTACARGA ||
            claseDestino == MAQUINA)) {
      return SALIDA;
    }

    // 3. De CONTENEDOR hacia CONTENEDOR = TRASPASO
    if (claseOrigen == CONTENEDOR && claseDestino == CONTENEDOR) {
      return TRASPASO;
    }

    // Por defecto, si no cumple ninguna regla específica
    return ENTRADA;
  }

  /// Valida si la combinación origen-destino es válida
  static bool esCombinacionValida({
    required String claseOrigen,
    required String? claseDestino,
    int? sucursalOrigen,
    int? sucursalDestino,
    String? unidadMedidaOrigen,
    String? unidadMedidaDestino,
  }) {
    if (claseDestino == null) {
      return true; // Permitir sin destino para casos específicos
    }

    // Aplicar las restricciones exactas:

    // 1. VEHICULO solo puede ir hacia CONTENEDOR (Ingreso)
    if (claseOrigen == VEHICULO) {
      if (claseDestino == CONTENEDOR) {
        return true; // Válido: Vehiculo -> Contenedor = Ingreso
      }
      // No se puede de Vehiculo a Vehiculo/Maquina/Montacarga
      return false;
    }

    // 2. CONTENEDOR puede ir hacia VEHICULO/MAQUINA/MONTACARGA (Salida) o CONTENEDOR (Traspaso)
    if (claseOrigen == CONTENEDOR) {
      if (claseDestino == VEHICULO ||
          claseDestino == MAQUINA ||
          claseDestino == MONTACARGA) {
        return true; // Válido: Contenedor -> Vehiculo/Maquina/Montacarga = Salida
      }
      if (claseDestino == CONTENEDOR) {
        // Validar restricciones específicas de traspaso
        return esTraspasosValido(
          sucursalOrigen: sucursalOrigen,
          sucursalDestino: sucursalDestino,
          unidadMedidaOrigen: unidadMedidaOrigen,
          unidadMedidaDestino: unidadMedidaDestino,
        );
      }
      return false;
    }

    // 3. MAQUINA no puede ir hacia ningún destino
    if (claseOrigen == MAQUINA) {
      return false; // No se puede de Maquina a Vehiculo/Maquina/Montacarga
    }

    // 4. MONTACARGA no puede ir hacia ningún destino
    if (claseOrigen == MONTACARGA) {
      return false; // No se puede de Montacarga a Vehiculo/Maquina/Montacarga
    }

    return false; // Por defecto, no permitir combinaciones no especificadas
  }

  /// Valida específicamente los traspasos entre contenedores
  static bool esTraspasosValido({
    int? sucursalOrigen,
    int? sucursalDestino,
    String? unidadMedidaOrigen,
    String? unidadMedidaDestino,
  }) {
    // Los traspasos solo son válidos entre contenedores de diferentes sucursales
    if (sucursalOrigen == null || sucursalDestino == null) {
      return false; // Ambas sucursales deben estar definidas
    }

    if (sucursalOrigen == sucursalDestino) {
      return false; // No hay traspasos dentro de la misma sucursal
    }

    // Las unidades de medida deben ser iguales
    if (unidadMedidaOrigen == null || unidadMedidaDestino == null) {
      return false; // Ambas unidades deben estar definidas
    }

    if (unidadMedidaOrigen != unidadMedidaDestino) {
      return false; // Las unidades de medida deben coincidir
    }

    return true; // Traspaso válido
  }

  /// Obtiene la etiqueta del campo de cantidad según el tipo de movimiento y unidad
  static String obtenerEtiquetaCantidad({
    required String tipoMovimiento,
    required String unidadMedida,
  }) {
    String unidad = unidadMedida.toLowerCase();

    switch (tipoMovimiento) {
      case ENTRADA:
        if (unidad.contains('litro')) {
          return 'Litros de Entrada';
        } else if (unidad.contains('unidad')) {
          return 'Unidades de Entrada';
        }
        return 'Cantidad de Entrada';

      case SALIDA:
        if (unidad.contains('litro')) {
          return 'Litros de Salida';
        } else if (unidad.contains('unidad')) {
          return 'Unidades de Salida';
        }
        return 'Cantidad de Salida';

      case TRASPASO:
        // Para traspaso se usan ambos campos
        return 'Cantidad a Traspasar';

      default:
        return 'Cantidad';
    }
  }

  /// Determina qué campos de cantidad deben estar habilitados
  static Map<String, bool> camposHabilitados({required String tipoMovimiento}) {
    switch (tipoMovimiento) {
      case ENTRADA:
        return {'valorEntrada': true, 'valorSalida': false};

      case SALIDA:
        return {'valorEntrada': false, 'valorSalida': true};

      case TRASPASO:
        return {'valorEntrada': true, 'valorSalida': true};

      default:
        return {'valorEntrada': false, 'valorSalida': false};
    }
  }

  /// Obtiene un mensaje descriptivo del movimiento
  static String obtenerDescripcionMovimiento({
    required String claseOrigen,
    required String? claseDestino,
    required String tipoMovimiento,
  }) {
    if (claseDestino == null) {
      return 'Movimiento desde ${claseOrigen.toLowerCase()}';
    }

    String accion = '';
    switch (tipoMovimiento) {
      case ENTRADA:
        accion = 'Ingreso';
        break;
      case SALIDA:
        accion = 'Salida';
        break;
      case TRASPASO:
        accion = 'Traspaso';
        break;
    }

    return '$accion: ${claseOrigen.toLowerCase()} → ${claseDestino.toLowerCase()}';
  }

  /// Obtiene el mensaje de error específico para validaciones fallidas
  static String? obtenerMensajeError({
    required String claseOrigen,
    required String? claseDestino,
    int? sucursalOrigen,
    int? sucursalDestino,
    String? unidadMedidaOrigen,
    String? unidadMedidaDestino,
  }) {
    if (claseDestino == null) return null;

    // Validar restricciones específicas según tipo de origen

    // 1. VEHICULO solo puede ir hacia CONTENEDOR
    if (claseOrigen == VEHICULO && claseDestino != CONTENEDOR) {
      return 'Los vehículos solo pueden realizar movimientos hacia contenedores (Ingreso)';
    }

    // 2. MAQUINA no puede ser origen de movimientos
    if (claseOrigen == MAQUINA) {
      return 'Las máquinas no pueden ser origen de movimientos';
    }

    // 3. MONTACARGA no puede ser origen de movimientos
    if (claseOrigen == MONTACARGA) {
      return 'Los montacargas no pueden ser origen de movimientos';
    }

    // 4. Validar traspasos entre contenedores
    if (claseOrigen == CONTENEDOR && claseDestino == CONTENEDOR) {
      if (sucursalOrigen == null || sucursalDestino == null) {
        return 'Las sucursales de origen y destino deben estar definidas para traspasos';
      }

      if (sucursalOrigen == sucursalDestino) {
        return 'No se pueden realizar traspasos dentro de la misma sucursal';
      }

      if (unidadMedidaOrigen == null || unidadMedidaDestino == null) {
        return 'Las unidades de medida deben estar definidas para traspasos';
      }

      if (unidadMedidaOrigen != unidadMedidaDestino) {
        return 'Las unidades de medida deben ser iguales para realizar traspasos';
      }
    }

    // 5. CONTENEDOR hacia destinos no válidos
    if (claseOrigen == CONTENEDOR &&
        claseDestino != CONTENEDOR &&
        claseDestino != VEHICULO &&
        claseDestino != MAQUINA &&
        claseDestino != MONTACARGA) {
      return 'Los contenedores solo pueden moverse hacia otros contenedores, vehículos, máquinas o montacargas';
    }

    return null; // Sin errores
  }
}
