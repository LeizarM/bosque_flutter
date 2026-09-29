/// Las familias de un grupo de familia SAP en la edicion masiva, con el tilde
/// que dice a cuales se les aplica.
///
/// **El tilde incluye.** En el dialogo dlgPorcGrupo del sistema anterior la
/// casilla marcada significaba "a esta familia no la toques", y la primera
/// version de esta pantalla lo copio. El usuario dijo que no se entendia: una
/// casilla marcada se lee como "si". Ahora la columna se llama "Aplicar", nace
/// todo marcado -igual que antes nacia nada excluido- y la fila desmarcada se
/// apaga y dice "No se toca".
///
/// Por dentro se sigue guardando el conjunto de las EXCLUIDAS ([excluidas]):
/// es el que cambia poco, y lo que se escribe no depende de como se dibuja.
///
/// **El diseno cambia con el ancho, no se escala.** Escritorio: tabla con
/// columnas y el tilde en linea. Movil: una tarjeta por familia con el tilde a
/// la izquierda, sin scroll horizontal.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/porcentajes_datos.dart';

/// Ancho fijo de la casilla. Con flex, la columna del tilde crecia mas que la
/// del codigo.
const double _anchoTilde = 72;

class TablaFamiliasGrupo extends StatelessWidget {
  const TablaFamiliasGrupo({
    super.key,
    required this.familias,
    required this.excluidas,
    required this.aire,
    required this.onAlternar,
    this.habilitado = true,
  });

  final List<FamiliaGrupoVista> familias;

  /// Codigos de familia que NO se van a tocar.
  final Set<int> excluidas;

  final Aire aire;
  final void Function(int codigoFamilia) onAlternar;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    if (familias.isEmpty) return const SizedBox.shrink();

    if (aire.esChico) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final f in familias)
            Padding(
              padding: const EdgeInsets.only(bottom: Esp.s),
              child: _Tarjeta(
                familia: f,
                excluida: excluidas.contains(f.codigoFamilia),
                habilitado: habilitado,
                onAlternar: () => onAlternar(f.codigoFamilia),
              ),
            ),
        ],
      );
    }

    // El proveedor es lo primero que se va cuando el cajon aprieta: ayuda a
    // reconocer la familia, pero la decision se toma con el codigo y con lo que
    // hoy tiene cargado.
    final amplio = aire == Aire.amplio;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Cabecera(amplio: amplio),
        for (var i = 0; i < familias.length; i++)
          Container(
            decoration: BoxDecoration(
              color: i.isEven ? null : cs.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
              ),
            ),
            child: _Fila(
              familia: familias[i],
              excluida: excluidas.contains(familias[i].codigoFamilia),
              amplio: amplio,
              habilitado: habilitado,
              onAlternar: () => onAlternar(familias[i].codigoFamilia),
            ),
          ),
      ],
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.amplio});

  final bool amplio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: Peso.titulo,
      color: cs.onSurfaceVariant,
      letterSpacing: 0.4,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Esquina.chica),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: _anchoTilde, child: Text('APLICAR', style: estilo)),
          SizedBox(width: 80, child: Text('FAMILIA', style: estilo)),
          if (amplio)
            Expanded(flex: 4, child: Text('PROVEEDOR SAP', style: estilo)),
          Expanded(flex: 5, child: Text('PORCENTAJE ACTUAL', style: estilo)),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.familia,
    required this.excluida,
    required this.amplio,
    required this.habilitado,
    required this.onAlternar,
  });

  final FamiliaGrupoVista familia;
  final bool excluida;
  final bool amplio;
  final bool habilitado;
  final VoidCallback onAlternar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // La familia excluida se apaga: sigue en la lista -hay que poder volver a
    // incluirla- pero no compite con las que si se van a escribir.
    final color = excluida ? cs.onSurfaceVariant : cs.onSurface;

    return InkWell(
      onTap: habilitado ? onAlternar : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Esp.m,
          vertical: Esp.xs,
        ),
        child: Row(
          children: [
            SizedBox(
              width: _anchoTilde,
              child: Checkbox(
                value: !excluida,
                onChanged: habilitado ? (_) => onAlternar() : null,
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                familia.codigoLegible,
                style: context.numero(fuerte: !excluida, color: color),
              ),
            ),
            if (amplio)
              Expanded(
                flex: 4,
                child: Text(
                  FamiliaGrupoVista.oGuion(familia.proveedor),
                  style: tt.bodyMedium?.copyWith(color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      familia.resumenActual,
                      style:
                          familia.sinPorcentajes
                              ? context.apagado()
                              : tt.bodyMedium?.copyWith(color: color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (excluida) ...[
                    const SizedBox(width: Esp.s),
                    const Etiqueta(texto: 'No se toca'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.familia,
    required this.excluida,
    required this.habilitado,
    required this.onAlternar,
  });

  final FamiliaGrupoVista familia;
  final bool excluida;
  final bool habilitado;
  final VoidCallback onAlternar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: excluida ? cs.surfaceContainerHighest : null,
      child: InkWell(
        onTap: habilitado ? onAlternar : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Esp.s, Esp.s, Esp.m, Esp.s),
          child: Row(
            children: [
              Checkbox(
                value: !excluida,
                onChanged: habilitado ? (_) => onAlternar() : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Familia ${familia.codigoLegible}',
                          style: tt.bodyLarge?.copyWith(
                            fontWeight: Peso.titulo,
                            color: excluida ? cs.onSurfaceVariant : null,
                          ),
                        ),
                        if (excluida) ...[
                          const SizedBox(width: Esp.s),
                          const Etiqueta(texto: 'No se toca'),
                        ],
                      ],
                    ),
                    Text(
                      FamiliaGrupoVista.oGuion(familia.proveedor),
                      style: context.apagado(),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Esp.xs),
                    Text(familia.resumenActual, style: tt.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
