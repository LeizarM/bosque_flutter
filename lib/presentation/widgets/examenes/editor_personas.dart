/// Grilla editable del modo "Lista de personas": tabla en escritorio y
/// tarjetas en el teléfono, con "Pegar desde Excel". Las reglas están en
/// `pegado_personas_examen.dart`.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/pegado_personas_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_persona_examen_entity.dart';

/// Debajo de este ancho de contenedor la grilla pasa a tarjetas.
const double _anchoTabla = 560;

class _FilaPersona {
  _FilaPersona(this.id, [TcpePersonaExamenEntity? p])
    : ci = TextEditingController(text: p?.ci ?? ''),
      nombres = TextEditingController(text: p?.nombres ?? ''),
      paterno = TextEditingController(text: p?.apellidoPaterno ?? ''),
      materno = TextEditingController(text: p?.apellidoMaterno ?? '');

  final int id;
  final TextEditingController ci;
  final TextEditingController nombres;
  final TextEditingController paterno;
  final TextEditingController materno;

  List<TextEditingController> get todos => [ci, nombres, paterno, materno];

  TcpePersonaExamenEntity get persona {
    final m = materno.text.trim();
    return TcpePersonaExamenEntity(
      ci: ci.text.trim(),
      nombres: nombres.text.trim(),
      apellidoPaterno: paterno.text.trim(),
      apellidoMaterno: m.isEmpty ? null : m,
    );
  }

  void dispose() {
    for (final c in todos) {
      c.dispose();
    }
  }
}

/// Filas de la grilla con sus controladores. Los errores se muestran recién
/// después del primer intento de enviar ([validar]).
class ControladorPersonas extends ChangeNotifier {
  ControladorPersonas() {
    _nueva();
  }

  final List<_FilaPersona> _filas = [];
  int _siguienteId = 0;
  bool _mostrarErrores = false;

  /// Tope de personas por pedido: `maxExamenesPorLote` de la configuración.
  int maximo = kMaxPersonasPorVez;

  bool get mostrarErrores => _mostrarErrores;
  int get cantidadFilas => _filas.length;

  /// Todas las filas, también las vacías (numeran los errores).
  List<TcpePersonaExamenEntity> get filas => [for (final f in _filas) f.persona];

  /// Las que se envían: sin las filas vacías.
  List<TcpePersonaExamenEntity> get personas => [
    for (final p in filas)
      if (!personaVacia(p)) p,
  ];

  void _nueva([TcpePersonaExamenEntity? p]) {
    final f = _FilaPersona(_siguienteId++, p);
    for (final c in f.todos) {
      c.addListener(notifyListeners);
    }
    _filas.add(f);
  }

  /// El TextField todavía usa el controlador en este cuadro: se libera después.
  void _soltar(_FilaPersona f) {
    for (final c in f.todos) {
      c.removeListener(notifyListeners);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => f.dispose());
  }

  void agregar() {
    if (_filas.length >= maximo) return;
    _nueva();
    notifyListeners();
  }

  void quitar(int i) {
    _soltar(_filas.removeAt(i));
    if (_filas.isEmpty) _nueva();
    notifyListeners();
  }

  /// Agrega lo pegado en lugar de las filas vacías del final, hasta el tope.
  /// Devuelve cuántas agregó y cuántas omitió por el tope.
  (int, int) pegar(String texto) {
    final nuevas = parsearPersonasPegadas(texto);
    while (_filas.isNotEmpty && personaVacia(_filas.last.persona)) {
      _soltar(_filas.removeLast());
    }
    final lugar = math.max(0, maximo - _filas.length);
    final tomadas = nuevas.take(lugar).toList();
    for (final p in tomadas) {
      _nueva(p);
    }
    if (_filas.isEmpty) _nueva();
    notifyListeners();
    return (tomadas.length, nuevas.length - tomadas.length);
  }

  /// El primer error de la lista (null si se puede enviar); desde aquí los
  /// campos muestran sus errores.
  String? validar() {
    _mostrarErrores = true;
    notifyListeners();
    return validarPersonasExamen(filas, maximo: maximo);
  }

  @override
  void dispose() {
    for (final f in _filas) {
      f.dispose();
    }
    _filas.clear();
    super.dispose();
  }
}

/// La grilla. Tabla con columnas en escritorio; tarjetas compactas en el
/// teléfono, sin scroll horizontal. La lista tiene alto propio y es perezosa:
/// 200 filas no arman 800 campos de una vez.
class EditorPersonasExamen extends StatelessWidget {
  const EditorPersonasExamen({super.key, required this.controlador});

  final ControladorPersonas controlador;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controlador,
    builder:
        (context, _) => LayoutBuilder(
          builder: (context, r) {
            final tabla = r.maxWidth >= _anchoTabla;
            final filas = controlador.filas;
            final repetidos = cisRepetidos(filas);
            final altoFila = tabla ? 56.0 : 172.0;
            final altoMax = tabla ? 336.0 : MediaQuery.sizeOf(context).height * 0.55;
            final alto = math.min(math.max(filas.length, 1) * altoFila, altoMax);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _barra(context),
                const SizedBox(height: Esp.s),
                if (tabla) const _Encabezado(),
                SizedBox(
                  height: alto,
                  child: ListView.builder(
                    itemCount: filas.length,
                    itemBuilder: (context, i) {
                      final f = controlador._filas[i];
                      final p = filas[i];
                      final errores =
                          controlador.mostrarErrores && !personaVacia(p)
                              ? erroresDePersona(p, ciRepetido: repetidos.contains(claveCi(p.ci)))
                              : const <CampoPersona, String>{};
                      return KeyedSubtree(
                        key: ValueKey(f.id),
                        child:
                            tabla
                                ? _FilaTabla(numero: i + 1, fila: f, errores: errores, onQuitar: () => controlador.quitar(i))
                                : _Tarjeta(numero: i + 1, fila: f, errores: errores, onQuitar: () => controlador.quitar(i)),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
  );

  Widget _barra(BuildContext context) {
    final n = controlador.personas.length;
    final lleno = controlador.cantidadFilas >= controlador.maximo;
    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: lleno ? null : controlador.agregar,
          icon: const Icon(Icons.person_add_alt_outlined, size: 18),
          label: const Text('Agregar persona'),
        ),
        OutlinedButton.icon(
          onPressed: lleno ? null : () => _pegar(context),
          icon: const Icon(Icons.content_paste_outlined, size: 18),
          label: const Text('Pegar desde Excel'),
        ),
        Text('$n de ${controlador.maximo}', style: context.apagado()),
      ],
    );
  }

  Future<void> _pegar(BuildContext context) async {
    final texto = await _pedirTextoPegado(context);
    if (texto == null || !context.mounted) return;
    final (agregadas, omitidas) = controlador.pegar(texto);
    if (agregadas == 0) {
      avisar(context, 'No se reconoció ninguna persona en el texto pegado.', esError: true);
      return;
    }
    avisar(
      context,
      '$agregadas ${agregadas == 1 ? 'persona agregada' : 'personas agregadas'}.'
      '${omitidas > 0 ? ' Se omitieron $omitidas: el máximo es ${controlador.maximo} por vez.' : ''}',
    );
  }
}

Future<String?> _pedirTextoPegado(BuildContext context) {
  final texto = TextEditingController();
  return showDialog<String>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Pegar desde Excel'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Una persona por línea, en este orden: CI, nombres, apellido paterno y apellido materno. '
                  'Con un solo apellido, deja vacía la otra columna. '
                  'Copia las columnas de Excel, o separa con punto y coma o con coma.',
                  style: ctx.apagado(),
                ),
                const SizedBox(height: Esp.m),
                TextField(
                  controller: texto,
                  autofocus: true,
                  minLines: 6,
                  maxLines: 10,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '4567890\tAna María\tPérez\tGómez\n5678901;Luis;Rojas;',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, texto.text), child: const Text('Agregar')),
          ],
        ),
  ).whenComplete(() => WidgetsBinding.instance.addPostFrameCallback((_) => texto.dispose()));
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    final estilo = context.apagado()?.copyWith(fontWeight: Peso.titulo);
    return Padding(
      padding: const EdgeInsets.only(bottom: Esp.xs),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: estilo)),
          Expanded(flex: 2, child: Text('CI', style: estilo)),
          const SizedBox(width: Esp.s),
          Expanded(flex: 3, child: Text('Nombres', style: estilo)),
          const SizedBox(width: Esp.s),
          Expanded(flex: 3, child: Text('Apellido paterno', style: estilo)),
          const SizedBox(width: Esp.s),
          Expanded(flex: 3, child: Text('Apellido materno', style: estilo)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

Widget _campo(
  TextEditingController c, {
  required String rotulo,
  String? error,
  bool conEtiqueta = false,
  int largo = kLargoNombre,
  TextInputAction accion = TextInputAction.next,
}) => TextField(
  controller: c,
  textInputAction: accion,
  inputFormatters: [LengthLimitingTextInputFormatter(largo)],
  decoration: InputDecoration(
    isDense: true,
    border: const OutlineInputBorder(),
    labelText: conEtiqueta ? rotulo : null,
    hintText: conEtiqueta ? null : rotulo,
    errorText: error,
    errorMaxLines: 2,
  ),
);

class _FilaTabla extends StatelessWidget {
  const _FilaTabla({required this.numero, required this.fila, required this.errores, required this.onQuitar});

  final int numero;
  final _FilaPersona fila;
  final Map<CampoPersona, String> errores;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.s),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Padding(
            padding: const EdgeInsets.only(top: Esp.m),
            child: Text('$numero', style: context.numero()),
          ),
        ),
        Expanded(flex: 2, child: _campo(fila.ci, rotulo: 'CI', error: errores[CampoPersona.ci], largo: kLargoCi)),
        const SizedBox(width: Esp.s),
        Expanded(flex: 3, child: _campo(fila.nombres, rotulo: 'Nombres', error: errores[CampoPersona.nombres])),
        const SizedBox(width: Esp.s),
        Expanded(
          flex: 3,
          child: _campo(fila.paterno, rotulo: 'Paterno', error: errores[CampoPersona.apellidoPaterno]),
        ),
        const SizedBox(width: Esp.s),
        Expanded(
          flex: 3,
          child: _campo(
            fila.materno,
            rotulo: 'Materno (opcional)',
            error: errores[CampoPersona.apellidoMaterno],
            accion: TextInputAction.done,
          ),
        ),
        SizedBox(
          width: 40,
          child: IconButton(
            tooltip: 'Quitar fila $numero',
            icon: const Icon(Icons.close, size: 18),
            onPressed: onQuitar,
          ),
        ),
      ],
    ),
  );
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.numero, required this.fila, required this.errores, required this.onQuitar});

  final int numero;
  final _FilaPersona fila;
  final Map<CampoPersona, String> errores;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: Esp.s),
      elevation: 0,
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Esp.m, Esp.xs, Esp.xs, Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Persona $numero', style: context.tituloSeccion())),
                IconButton(
                  tooltip: 'Quitar persona $numero',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onQuitar,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _campo(fila.ci, rotulo: 'CI', conEtiqueta: true, error: errores[CampoPersona.ci], largo: kLargoCi),
                ),
                const SizedBox(width: Esp.s),
                Expanded(
                  flex: 3,
                  child: _campo(fila.nombres, rotulo: 'Nombres', conEtiqueta: true, error: errores[CampoPersona.nombres]),
                ),
              ],
            ),
            const SizedBox(height: Esp.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _campo(
                    fila.paterno,
                    rotulo: 'Ap. paterno',
                    conEtiqueta: true,
                    error: errores[CampoPersona.apellidoPaterno],
                  ),
                ),
                const SizedBox(width: Esp.s),
                Expanded(
                  child: _campo(
                    fila.materno,
                    rotulo: 'Ap. materno',
                    conEtiqueta: true,
                    error: errores[CampoPersona.apellidoMaterno],
                    accion: TextInputAction.done,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
