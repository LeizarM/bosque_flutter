import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/tigo_ejecutado_entity.dart';

/// Configuración centralizada para el árbol de Tigo (ejecutado y preview).
/// Ambos árboles (Acción N y K) comparten la misma estructura de columnas
/// y decoración, por lo que se centraliza aquí para evitar duplicación.
class TigoTreeConfig {
  TigoTreeConfig._(); // No instanciable

  /// Verifica si una entidad corresponde a "SIN ASIGNAR"
  static bool esSinAsignar(TigoEjecutadoEntity e) =>
      e.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR';

  /// Nombre limpio sin prefijo ZZZ (prefijo de ordenación SQL)
  static String nombreLimpio(TigoEjecutadoEntity e) =>
      e.nombreCompleto.startsWith('ZZZ')
          ? e.nombreCompleto.replaceFirst(RegExp(r'^ZZZ\s*'), '').trim()
          : e.nombreCompleto;

  // ═══════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN PARA DESKTOP (BosqueTreeTable)
  // ═══════════════════════════════════════════════════════════════════

  /// Decoración estándar de filas del árbol Tigo
  static BoxDecoration getRowDecoration(
    TigoEjecutadoEntity e,
    int index,
    int nivel,
  ) {
    final sinAsignar = esSinAsignar(e);
    final esHijo = nivel > 0;
    return BoxDecoration(
      color: sinAsignar
          ? Colors.red[100]
          : esHijo
              ? Colors.blue[50]
              : (index % 2 == 0 ? Colors.white : Colors.grey[200]),
      border: Border(
        left: (esHijo && !sinAsignar)
            ? BorderSide(color: Colors.blue[300]!, width: 4)
            : BorderSide.none,
        bottom: const BorderSide(color: Colors.grey, width: 0.5),
      ),
    );
  }

  /// Columnas estándar del árbol Tigo para Desktop
  static List<BosqueTreeColumn<TigoEjecutadoEntity>> getColumns({
    required bool mostrarEstado,
  }) {
    return [
      BosqueTreeColumn(
        label: 'TELÉFONO',
        flex: 2,
        cellBuilder: (e, nivel) => Text(
          e.corporativo ?? '',
          style: TextStyle(
            color: esSinAsignar(e) ? Colors.red[700] : null,
          ),
        ),
      ),
      BosqueTreeColumn(
        label: 'NOMBRE',
        flex: 4,
        cellBuilder: (e, nivel) {
          final nombre = nombreLimpio(e);
          final sinAsignar = esSinAsignar(e);
          return Row(
            children: [
              if (sinAsignar)
                const Icon(Icons.warning, color: Colors.red, size: 16),
              if (sinAsignar) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  nombre,
                  style: TextStyle(
                    fontWeight:
                        nivel == 0 ? FontWeight.bold : FontWeight.normal,
                    color: sinAsignar ? Colors.red[700] : Colors.black,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      BosqueTreeColumn(
        label: 'DESCRIPCIÓN',
        flex: 3,
        cellBuilder: (e, nivel) => Text(
          e.descripcion,
          style: TextStyle(
            fontWeight: nivel == 0 ? FontWeight.bold : FontWeight.normal,
            color: esSinAsignar(e) ? Colors.red[700] : Colors.black,
          ),
        ),
      ),
      BosqueTreeColumn(
        label: 'EMPRESA',
        flex: 2,
        cellBuilder: (e, nivel) => Text(
          e.empresa ?? '',
          style: TextStyle(
            color: esSinAsignar(e) ? Colors.red[700] : Colors.black,
          ),
        ),
      ),
      if (mostrarEstado)
        BosqueTreeColumn(
          label: 'ESTADO',
          flex: 2,
          cellBuilder: (e, nivel) => Text(
            e.estado,
            style: TextStyle(
              color: esSinAsignar(e) ? Colors.red[700] : Colors.black,
            ),
          ),
        ),
      BosqueTreeColumn(
        label: 'TOTAL',
        flex: 2,
        alignment: Alignment.centerRight,
        cellBuilder: (e, nivel) => Text(
          e.totalCobradoXCuenta.toStringAsFixed(2),
          style: TextStyle(
            color: esSinAsignar(e) ? Colors.red[700] : Colors.black,
          ),
        ),
      ),
      BosqueTreeColumn(
        label: 'MONTO EMPRESA',
        flex: 2,
        alignment: Alignment.centerRight,
        cellBuilder: (e, nivel) => Text(
          e.montoCubiertoXEmpresa.toStringAsFixed(2),
          style: TextStyle(
            color: esSinAsignar(e) ? Colors.red[700] : Colors.black,
          ),
        ),
      ),
      BosqueTreeColumn(
        label: 'MONTO EMPLEADO',
        flex: 2,
        alignment: Alignment.centerRight,
        cellBuilder: (e, nivel) => Text(
          e.montoEmpleado.toStringAsFixed(2),
          style: TextStyle(
            color: esSinAsignar(e) ? Colors.red[700] : Colors.black,
          ),
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN PARA MOBILE (TreeNode con ExpansionTile)
  // ═══════════════════════════════════════════════════════════════════

  /// Construye la fila de montos para mobile (usada en hojas y padres)
  static Widget buildMontosRow(TigoEjecutadoEntity nodo) {
    return Text(
      'Total: Bs ${nodo.totalCobradoXCuenta.toStringAsFixed(2)}  |  '
      'Empresa: Bs ${nodo.montoCubiertoXEmpresa.toStringAsFixed(2)}  |  '
      'Empleado: Bs ${nodo.montoEmpleado.toStringAsFixed(2)}',
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: Colors.indigo,
      ),
    );
  }

  /// Widget de estado para mobile (solo se muestra si el estado no está vacío)
  static Widget? buildEstadoWidget(TigoEjecutadoEntity nodo) {
    if (nodo.estado.isEmpty) return null;
    return Text(
      'Estado: ${nodo.estado}',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: nodo.estado.toUpperCase() == 'EJECUTADO'
            ? Colors.green[700]
            : Colors.orange[800],
      ),
    );
  }
}
