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

  /*
  REGLAS DE NEGOCIO IMPLEMENTADAS:
  
  ✅ PERMITIDAS:
  1. VEHICULO → CONTENEDOR = ENTRADA (Ingreso) - SOLO para combustibles líquidos (Litros)
  2. CONTENEDOR → VEHICULO/MAQUINA/MONTACARGA = SALIDA
  3. CONTENEDOR → CONTENEDOR = TRASPASO (solo entre diferentes sucursales)
  
  ❌ NO PERMITIDAS:
  4. VEHICULO → VEHICULO/MAQUINA/MONTACARGA
  5. MAQUINA → cualquier destino
  6. MONTACARGA → cualquier destino
  7. VEHICULO/MAQUINA/MONTACARGA → CONTENEDOR de GARRAFAS (Unidades)
  
  ℹ️ RESTRICCIONES ADICIONALES:
  8. Traspasos solo entre DIFERENTES sucursales (codSucursal)
  9. SALIDAS: No pueden exceder el saldo disponible del contenedor origen
  10. TRASPASOS: No pueden exceder el saldo disponible del contenedor origen
  11. ENTRADAS DE GARRAFAS: Solo permitidas desde control_garrafas_registro_screen.dart
  */

  /// Determina automáticamente el tipo de movimiento basado en origen y destino
  static String determinarTipoMovimiento({
    required String claseOrigen,
    required String? claseDestino,
  }) {
    // Si no hay destino, no podemos determinar el tipo
    if (claseDestino == null) {
      return ENTRADA; // Por defecto
    }

    // Regla 1: VEHICULO → CONTENEDOR = ENTRADA (Ingreso)
    if (claseOrigen == VEHICULO && claseDestino == CONTENEDOR) {
      return ENTRADA;
    }

    // Regla 2: CONTENEDOR → VEHICULO/MAQUINA/MONTACARGA = SALIDA
    if (claseOrigen == CONTENEDOR &&
        (claseDestino == VEHICULO ||
            claseDestino == MONTACARGA ||
            claseDestino == MAQUINA)) {
      return SALIDA;
    }

    // Regla 3: CONTENEDOR → CONTENEDOR = TRASPASO
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

    // Regla 1: VEHICULO → CONTENEDOR = ENTRADA (Ingreso) ✅
    if (claseOrigen == VEHICULO && claseDestino == CONTENEDOR) {
      return true;
    }

    // Regla 2: CONTENEDOR → VEHICULO/MAQUINA/MONTACARGA = SALIDA ✅
    if (claseOrigen == CONTENEDOR &&
        (claseDestino == VEHICULO ||
            claseDestino == MAQUINA ||
            claseDestino == MONTACARGA)) {
      return true;
    }

    // Regla 3: CONTENEDOR → CONTENEDOR = TRASPASO ✅
    if (claseOrigen == CONTENEDOR && claseDestino == CONTENEDOR) {
      return esTraspasosValido(
        sucursalOrigen: sucursalOrigen,
        sucursalDestino: sucursalDestino,
        unidadMedidaOrigen: unidadMedidaOrigen,
        unidadMedidaDestino: unidadMedidaDestino,
      );
    }

    // Regla 4: NO se puede VEHICULO → VEHICULO/MAQUINA/MONTACARGA ❌
    if (claseOrigen == VEHICULO &&
        (claseDestino == VEHICULO ||
            claseDestino == MAQUINA ||
            claseDestino == MONTACARGA)) {
      return false;
    }

    // Regla 5: NO se puede MAQUINA → VEHICULO/MAQUINA/MONTACARGA ❌
    if (claseOrigen == MAQUINA) {
      return false;
    }

    // Regla 6: NO se puede MONTACARGA → VEHICULO/MAQUINA/MONTACARGA ❌
    if (claseOrigen == MONTACARGA) {
      return false;
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
    // Regla 7: Traspasos entre contenedores de DIFERENTES sucursales
    if (sucursalOrigen == null || sucursalDestino == null) {
      return false; // Ambas sucursales deben estar definidas
    }

    // SOLO permitir traspasos entre DIFERENTES sucursales
    if (sucursalOrigen == sucursalDestino) {
      return false; // NO se permiten traspasos dentro de la misma sucursal
    }

    // Las unidades de medida deben ser iguales
    if (unidadMedidaOrigen == null || unidadMedidaDestino == null) {
      return false; // Ambas unidades deben estar definidas
    }

    if (unidadMedidaOrigen != unidadMedidaDestino) {
      return false; // Las unidades de medida deben coincidir
    }

    return true; // Traspaso válido entre diferentes sucursales
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

  /// Determina si un contenedor es una garrafa basándose en su unidad de medida
  static bool esGarrafa(String unidadMedida) {
    final unidad = unidadMedida.toLowerCase();
    return unidad.contains('unidad') ||
        unidad.contains('und') ||
        unidad.contains('pza') ||
        unidad.contains('pieza') ||
        unidad.contains('u');
  }

  /// Valida que las cantidades no excedan los saldos disponibles
  static String? validarSaldosSuficientes({
    required String tipoMovimiento,
    required double cantidad,
    required double saldoOrigen,
    double? saldoDestino,
  }) {
    // Validar SALIDA: no puede exceder el saldo del contenedor origen
    if (tipoMovimiento == SALIDA) {
      if (cantidad > saldoOrigen) {
        return 'La cantidad de salida ($cantidad) no puede ser mayor al saldo disponible ($saldoOrigen)';
      }
    }

    // Validar TRASPASO: no puede exceder el saldo del contenedor origen
    if (tipoMovimiento == TRASPASO) {
      if (cantidad > saldoOrigen) {
        return 'La cantidad a traspasar ($cantidad) no puede ser mayor al saldo disponible en origen ($saldoOrigen)';
      }
    }

    return null; // Sin errores - saldos suficientes
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

    // Regla 4: NO se puede VEHICULO → VEHICULO/MAQUINA/MONTACARGA
    if (claseOrigen == VEHICULO &&
        (claseDestino == VEHICULO ||
            claseDestino == MAQUINA ||
            claseDestino == MONTACARGA)) {
      return 'Los vehículos solo pueden realizar movimientos hacia contenedores (Regla 4)';
    }

    // Regla 5: NO se puede MAQUINA → cualquier destino
    if (claseOrigen == MAQUINA) {
      return 'Las máquinas no pueden ser origen de movimientos (Regla 5)';
    }

    // Regla 6: NO se puede MONTACARGA → cualquier destino
    if (claseOrigen == MONTACARGA) {
      return 'Los montacargas no pueden ser origen de movimientos (Regla 6)';
    }

    // Regla 7: Validar traspasos entre contenedores (solo diferentes sucursales)
    if (claseOrigen == CONTENEDOR && claseDestino == CONTENEDOR) {
      if (sucursalOrigen == null || sucursalDestino == null) {
        return 'Las sucursales de origen y destino deben estar definidas para traspasos';
      }

      if (sucursalOrigen == sucursalDestino) {
        return 'Los traspasos solo se permiten entre DIFERENTES sucursales (Regla 7)';
      }

      if (unidadMedidaOrigen == null || unidadMedidaDestino == null) {
        return 'Las unidades de medida deben estar definidas para traspasos';
      }

      if (unidadMedidaOrigen != unidadMedidaDestino) {
        return 'Las unidades de medida deben ser iguales para realizar traspasos';
      }
    }

    // Destinos no válidos en general
    if (claseOrigen == CONTENEDOR &&
        claseDestino != CONTENEDOR &&
        claseDestino != VEHICULO &&
        claseDestino != MAQUINA &&
        claseDestino != MONTACARGA) {
      return 'Destino no válido para contenedores';
    }

    return null; // Sin errores - combinación válida
  }
}
