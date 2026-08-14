/// Los tokens visuales del Rol de Turnos de Sábado.
///
/// **Se mudaron a `lib/core/ui/tokens_bosque.dart`.** `Esp`, `Peso`,
/// `cifrasTabulares`, la extensión `EstiloModulo`, `ColorDeEstado` y
/// `colorDeEstado` viven ahí desde que hubo un segundo módulo que los quería:
/// se venían copiando de módulo en módulo y la cuarta copia iba a ser la cuarta
/// divergencia. **No cambió ni una constante**, sólo el archivo donde están.
///
/// Este archivo queda como re-export a propósito: lo importan 15 widgets de
/// `rol-sabados/` y no hay motivo para tocarlos a todos. Los archivos nuevos
/// importan `core/ui/tokens_bosque.dart` directo.
library;

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:flutter/material.dart';

export 'package:bosque_flutter/core/ui/tokens_bosque.dart';

/// El color de una celda de la grilla, o null si está libre.
///
/// **null es un dato**, no un faltante: en este modelo el libre es la ausencia
/// de la fila, así que el cuadrito sin pintar significa «ese día no le tocaba».
///
/// **Por qué esta función no se mudó a `core/ui/`.** Depende de
/// `CeldaTurnoEntity`, que es del dominio de los sábados: llevarla haría que
/// `core/` conociera una entidad de un módulo, que es justo la dependencia que
/// la capa `core` no debe tener.
ColorDeEstado? colorDeCelda(ColorScheme cs, CeldaTurnoEntity? celda) =>
    celda == null ? null : colorDeEstado(cs, celda.codigoExcel);
