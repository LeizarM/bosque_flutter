/// Lista de personas del modo "Lista de personas" de los exámenes: el texto
/// pegado desde Excel y las reglas que el backend exige (CI obligatorio y
/// único salvo el CI sin documento, nombres y al menos un apellido, 200 como máximo).
library;

import 'package:bosque_flutter/domain/entities/tcpe_persona_examen_entity.dart';

/// Tope por pedido (`@Size(max = 200)` de `personas` en el backend).
const int kMaxPersonasPorVez = 200;

/// Largos de `tcpe_usuario`: ci varchar(20); nombres y apellidos varchar(50).
const int kLargoCi = 20;
const int kLargoNombre = 50;

enum CampoPersona { ci, nombres, apellidoPaterno, apellidoMaterno }

final _saltoDeLinea = RegExp(r'\r\n|\r|\n');

/// Una persona por línea, en el orden ci, nombres, apellidoPaterno,
/// apellidoMaterno. Separa por tabulación (copiar de Excel), y si la línea
/// no tiene, por punto y coma o por coma. Salta líneas vacías y encabezados.
List<TcpePersonaExamenEntity> parsearPersonasPegadas(String texto) {
  final personas = <TcpePersonaExamenEntity>[];
  for (final linea in texto.split(_saltoDeLinea)) {
    if (linea.trim().isEmpty) continue;
    // Sin trim previo: una celda inicial vacía (falta el CI) no debe correr las columnas.
    final sep = linea.contains('\t') ? '\t' : (linea.contains(';') ? ';' : ',');
    final c = linea.split(sep).map(_celda).toList();
    String en(int i) => i < c.length ? c[i] : '';
    if (c.every((x) => x.isEmpty) || _esEncabezado(en(0))) continue;
    personas.add(
      TcpePersonaExamenEntity(
        ci: en(0),
        nombres: en(1),
        apellidoPaterno: en(2),
        apellidoMaterno: en(3).isEmpty ? null : en(3),
      ),
    );
  }
  return personas;
}

/// Excel entrecomilla las celdas con separadores o saltos de línea.
String _celda(String s) {
  var t = s.trim();
  if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
    t = t.substring(1, t.length - 1).replaceAll('""', '"').trim();
  }
  return t;
}

bool _esEncabezado(String primera) {
  final t = primera.toLowerCase().replaceAll('.', '').replaceAll(' ', '');
  return t == 'ci' || t.contains('carnet') || t.contains('cedula') || t.contains('cédula') || t == 'documento';
}

/// La fila no tiene nada escrito: no cuenta ni se valida.
bool personaVacia(TcpePersonaExamenEntity p) =>
    p.ci.trim().isEmpty &&
    p.nombres.trim().isEmpty &&
    p.apellidoPaterno.trim().isEmpty &&
    (p.apellidoMaterno ?? '').trim().isEmpty;

/// CI normalizado para comparar (sin espacios a los lados ni mayúsculas).
String claveCi(String ci) => ci.trim().toUpperCase();

/// Los CI que aparecen más de una vez entre las filas con datos. El
/// [ciSinDocumento] (`ciSinDocumento` de la configuración, hoy 0) no se repite:
/// cada uno es una persona distinta.
Set<String> cisRepetidos(List<TcpePersonaExamenEntity> filas, {String? ciSinDocumento}) {
  final sinDocumento = ciSinDocumento == null ? null : claveCi(ciSinDocumento);
  final vistos = <String>{};
  final repetidos = <String>{};
  for (final p in filas) {
    final k = claveCi(p.ci);
    if (k.isEmpty || k == sinDocumento) continue;
    if (!vistos.add(k)) repetidos.add(k);
  }
  return repetidos;
}

/// El error de cada campo de una fila (vacío si está bien).
Map<CampoPersona, String> erroresDePersona(
  TcpePersonaExamenEntity p, {
  bool ciRepetido = false,
}) {
  final e = <CampoPersona, String>{};
  final ci = p.ci.trim();
  if (ci.isEmpty) {
    e[CampoPersona.ci] = 'Falta el CI';
  } else if (ci.length > kLargoCi) {
    e[CampoPersona.ci] = 'Máximo $kLargoCi caracteres';
  } else if (ciRepetido) {
    e[CampoPersona.ci] = 'CI repetido';
  }
  if (p.nombres.trim().isEmpty) {
    e[CampoPersona.nombres] = 'Faltan los nombres';
  } else if (p.nombres.trim().length > kLargoNombre) {
    e[CampoPersona.nombres] = 'Máximo $kLargoNombre caracteres';
  }
  // Basta un apellido, paterno o materno; si no hay ninguno, el error va en el paterno.
  if (p.apellidoPaterno.trim().isEmpty && (p.apellidoMaterno ?? '').trim().isEmpty) {
    e[CampoPersona.apellidoPaterno] = 'Falta un apellido';
  } else if (p.apellidoPaterno.trim().length > kLargoNombre) {
    e[CampoPersona.apellidoPaterno] = 'Máximo $kLargoNombre caracteres';
  }
  if ((p.apellidoMaterno ?? '').trim().length > kLargoNombre) {
    e[CampoPersona.apellidoMaterno] = 'Máximo $kLargoNombre caracteres';
  }
  return e;
}

/// El primer problema de la lista, con su número de fila, o null si se puede
/// enviar. Las filas vacías se ignoran.
String? validarPersonasExamen(
  List<TcpePersonaExamenEntity> filas, {
  int maximo = kMaxPersonasPorVez,
  String? ciSinDocumento,
}) {
  final conDatos = filas.where((p) => !personaVacia(p)).length;
  if (conDatos == 0) return 'Agrega al menos una persona.';
  if (conDatos > maximo) {
    return 'Como máximo $maximo personas por vez (hay $conDatos).';
  }
  final repetidos = cisRepetidos(filas, ciSinDocumento: ciSinDocumento);
  for (var i = 0; i < filas.length; i++) {
    final p = filas[i];
    if (personaVacia(p)) continue;
    final errores = erroresDePersona(p, ciRepetido: repetidos.contains(claveCi(p.ci)));
    if (errores.isEmpty) continue;
    return 'Fila ${i + 1}: ${_resumen(errores.keys.first, p)}.';
  }
  return null;
}

String _resumen(CampoPersona campo, TcpePersonaExamenEntity p) => switch (campo) {
  CampoPersona.ci =>
    p.ci.trim().isEmpty
        ? 'falta el CI'
        : p.ci.trim().length > kLargoCi
        ? 'el CI admite hasta $kLargoCi caracteres'
        : 'el CI ${p.ci.trim()} está repetido',
  CampoPersona.nombres =>
    p.nombres.trim().isEmpty ? 'faltan los nombres' : 'los nombres admiten hasta $kLargoNombre caracteres',
  CampoPersona.apellidoPaterno =>
    p.apellidoPaterno.trim().isEmpty
        ? 'falta un apellido (paterno o materno)'
        : 'el apellido paterno admite hasta $kLargoNombre caracteres',
  CampoPersona.apellidoMaterno => 'el apellido materno admite hasta $kLargoNombre caracteres',
};
