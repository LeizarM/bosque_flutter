/// Tokens visuales del Rol de Turnos de Sábado.
///
/// Viven en `lib/core/ui/tokens_bosque.dart` (`Esp`, `Peso`, `cifrasTabulares`,
/// `EstiloModulo`, `ColorDeEstado`, `colorDeEstado`); este archivo es un
/// re-export para no tocar los 15 widgets de `rol-sabados/` que lo importan.
library;

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:flutter/material.dart';

export 'package:bosque_flutter/core/ui/tokens_bosque.dart';

/// El color de una celda de la grilla, o null si está libre.
///
/// **null es un dato**: el libre es la ausencia de la fila, así que el cuadrito
/// sin pintar significa «ese día no le tocaba». No vive en `core/ui/` porque
/// depende de `CeldaTurnoEntity`, entidad de este módulo.
ColorDeEstado? colorDeCelda(ColorScheme cs, CeldaTurnoEntity? celda) =>
    celda == null ? null : colorDeEstado(cs, celda.codigoExcel);
