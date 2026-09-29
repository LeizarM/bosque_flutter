/// La grilla "Porcentaje por familia" de la ficha, como en el dialogo
/// "Registro de familias" del sistema anterior: una fila por lista de precio
/// activa, agrupadas por sucursal, con el margen de la familia en cada una.
///
/// * **Alta:** las listas activas en 0 %. Si la familia nace "a partir de"
///   otra, con los porcentajes de esa otra: es casi siempre lo que corresponde.
///   Se graban todas, como en el sistema anterior.
/// * **Edicion:** los porcentajes que ya tiene la familia; las listas que
///   todavia no tiene aparecen en 0 %. Se graban solo las que cambiaron.
///
/// La regla de porcentajes ascendentes por sucursal no se exige: en el sistema
/// anterior `validaPorcentaje()` armaba el mensaje pero siempre devolvia 0, asi
/// que nunca bloqueo nada (ver `PrecioController`). La pantalla Porcentajes la
/// muestra como aviso.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/porcentaje_precio_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/porcentajes_datos.dart';

/// Los valores de la grilla. Lo tiene la ficha, que decide cuando cargarlo y
/// que mandar al guardar; el widget solo lo dibuja.
class PorcentajesFicha extends ChangeNotifier {
  List<FilaPorcentaje> _filas = const [];
  final Map<BigInt, TextEditingController> _campos = {};
  final Map<BigInt, double> _iniciales = {};
  bool _cargada = false;

  List<FilaPorcentaje> get filas => _filas;

  /// Ya llegaron las listas. Sin esto no hay nada que guardar.
  bool get cargada => _cargada;

  /// Se llama una sola vez, cuando llegan los datos, y puede ser durante un
  /// build: por eso no avisa a nadie. [valores] pisa el porcentaje de cada
  /// fila por idClasificacion (los de la familia plantilla).
  void cargar(List<FilaPorcentaje> filas, {Map<BigInt, double>? valores}) {
    if (_cargada) return;
    _cargada = true;
    _filas = [...filas]..sort((a, b) {
      final s = a.codSucursal.compareTo(b.codSucursal);
      return s != 0 ? s : a.vpp.compareTo(b.vpp);
    });
    for (final f in _filas) {
      final v = valores?[f.idClasificacion] ?? f.porcen;
      _iniciales[f.idClasificacion] = v;
      _campos[f.idClasificacion] = TextEditingController(
        text: porcenEditable(v),
      )..addListener(notifyListeners);
    }
  }

  TextEditingController campo(BigInt idClasificacion) =>
      _campos[idClasificacion]!;

  /// Lo escrito, en puntos porcentuales. Null si no es un numero.
  double? valor(BigInt idClasificacion) =>
      porcenDesdeTexto(_campos[idClasificacion]?.text ?? '');

  bool invalido(BigInt idClasificacion) {
    final v = valor(idClasificacion);
    return v == null || v < 0;
  }

  bool get hayInvalidos => _filas.any((f) => invalido(f.idClasificacion));

  bool cambio(BigInt idClasificacion) {
    final v = valor(idClasificacion);
    return v == null || !mismoPorcentaje(v, _iniciales[idClasificacion] ?? 0);
  }

  bool get hayCambios => _filas.any((f) => cambio(f.idClasificacion));

  /// Lo que viaja al guardar: en el alta todas las filas, en la edicion solo
  /// las que cambiaron. El idPorcen lo resuelve el backend.
  List<PorcentajePrecioEntity> aGuardar({
    required bool alta,
    required int codigoFamilia,
  }) => [
    for (final f in _filas)
      if (alta || cambio(f.idClasificacion))
        PorcentajePrecioEntity(
          idPorcen: f.idPorcen,
          codigoFamilia: codigoFamilia,
          idClasificacion: f.idClasificacion,
          porcen: valor(f.idClasificacion)!,
          audUsuario: BigInt.zero,
        ),
  ];

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }
}

/// Las listas agrupadas por sucursal, con un campo por lista. En escritorio
/// entran cuatro por renglon; en un telefono, dos.
class GrillaPorcentajesFicha extends StatelessWidget {
  const GrillaPorcentajesFicha({
    super.key,
    required this.porcentajes,
    required this.mostrarErrores,
  });

  final PorcentajesFicha porcentajes;

  /// Despues del primer intento de guardar, los campos invalidos se marcan.
  final bool mostrarErrores;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: porcentajes,
      builder: (context, _) {
        final grupos = <int, List<FilaPorcentaje>>{};
        for (final f in porcentajes.filas) {
          grupos.putIfAbsent(f.codSucursal, () => []).add(f);
        }
        return LayoutBuilder(
          builder: (context, cajon) {
            final columnas = cajon.maxWidth >= 520 ? 4 : 2;
            final ancho = (cajon.maxWidth - Esp.m * (columnas - 1)) / columnas;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final filas in grupos.values) ...[
                  _CabezaSucursal(
                    sucursal: filas.first.sucursal,
                    listas: filas.length,
                  ),
                  Wrap(
                    spacing: Esp.m,
                    runSpacing: Esp.m,
                    children: [
                      for (final f in filas)
                        SizedBox(
                          width: ancho,
                          child: _CampoPorcentaje(
                            fila: f,
                            porcentajes: porcentajes,
                            mostrarError: mostrarErrores,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Esp.l),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _CabezaSucursal extends StatelessWidget {
  const _CabezaSucursal({required this.sucursal, required this.listas});

  final String sucursal;
  final int listas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Esp.s),
      child: Row(
        children: [
          Icon(Icons.storefront_outlined, size: 16, color: cs.primary),
          const SizedBox(width: Esp.s),
          Flexible(
            child: Text(
              sucursal,
              overflow: TextOverflow.ellipsis,
              style: tt.labelLarge?.copyWith(fontWeight: Peso.titulo),
            ),
          ),
          const SizedBox(width: Esp.s),
          Text(
            listas == 1 ? '1 lista' : '$listas listas',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CampoPorcentaje extends StatelessWidget {
  const _CampoPorcentaje({
    required this.fila,
    required this.porcentajes,
    required this.mostrarError,
  });

  final FilaPorcentaje fila;
  final PorcentajesFicha porcentajes;
  final bool mostrarError;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = fila.idClasificacion;
    final invalido = porcentajes.invalido(id);
    final cambiado = porcentajes.cambio(id) && !invalido;

    return TextField(
      controller: porcentajes.campo(id),
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // La coma se admite a proposito -en Bolivia se escribe 12,5- y se
      // traduce al leer, igual que en la pantalla Porcentajes.
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: context.numero(
        fuerte: true,
        color: cambiado ? cs.onTertiaryContainer : null,
      ),
      decoration: InputDecoration(
        isDense: true,
        border: const OutlineInputBorder(),
        labelText: fila.etiquetaLista,
        suffixText: '%',
        filled: cambiado,
        fillColor: cs.tertiaryContainer,
        errorText: mostrarError && invalido ? 'No es un número' : null,
      ),
    );
  }
}
