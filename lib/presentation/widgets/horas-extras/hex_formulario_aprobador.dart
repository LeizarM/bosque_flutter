/// Formularios de Aprobadores: asignar el rol de encargado (nivel 1, su rama
/// del organigrama, D34), de jefe de área (nivel 2, sobre los encargados que
/// se elijan, D35) o de observador (nivel 3, D45), cerrar y eliminar. Las reglas son del SP (D21). Antes de
/// asignar se ve la rama de la persona o la de cada encargado elegido.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/agenda_provider.dart';
import 'package:bosque_flutter/core/state/hex_configuracion_provider.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/nombres_parecidos.dart';
import 'package:bosque_flutter/domain/entities/agenda_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_encargado_opcion_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_configuracion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_rama_aprobador.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AGENDA Y TEXTOS
// ═══════════════════════════════════════════════════════════════════════════

/// Las personas de la agenda sin repetir y por nombre; el apoyo (cargo y
/// sucursal) distingue homónimos y también se busca.
List<OpcionHex<BigInt>> personasDeAgendaHex(List<AgendaEmpleadoEntity> agenda) {
  final porCodigo = <BigInt, AgendaEmpleadoEntity>{};
  for (final e in agenda) {
    porCodigo.putIfAbsent(e.codEmpleado, () => e);
  }
  final unicas =
      porCodigo.values.toList()..sort(
        (a, b) => a.nombreCompleto.toLowerCase().compareTo(
          b.nombreCompleto.toLowerCase(),
        ),
      );
  return [
    for (final e in unicas)
      (
        valor: e.codEmpleado,
        texto: oGuionHex(e.nombreCompleto),
        apoyo: _apoyo([e.cargo, e.sucursal]),
      ),
  ];
}

String? _apoyo(List<String> partes) {
  final t = partes.where((p) => p.trim().isNotEmpty).join(' · ');
  return t.isEmpty ? null : t;
}

/// Un campo que elige de la agenda con el buscador del kit (usable en el
/// teléfono con el teclado abierto). Mientras carga lo dice; si falla, se
/// toca para reintentar. Sin [habilitado] (escritura en curso) no se toca.
class CampoAgendaHex<T extends Object> extends ConsumerWidget {
  const CampoAgendaHex({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.alElegir,
    this.alQuitar,
    this.textoQuitar = 'Quitar',
    this.pista = 'Elige',
    this.ayuda,
    this.habilitado = true,
  });

  final String etiqueta;
  final T? valor;
  final List<OpcionHex<T>> Function(List<AgendaEmpleadoEntity>) opciones;
  final ValueChanged<T> alElegir;
  final VoidCallback? alQuitar;
  final String textoQuitar;
  final String pista;
  final String? ayuda;
  final bool habilitado;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(agendaEmpleadosProvider)
      .when(
        skipLoadingOnReload: true,
        loading:
            () => CampoSelectorHex(
              etiqueta: etiqueta,
              valor: null,
              pista: 'Cargando la agenda…',
              icono: Icons.hourglass_empty,
              alTocar: null,
            ),
        error:
            (_, __) => CampoSelectorHex(
              etiqueta: etiqueta,
              valor: null,
              pista: 'No se pudo cargar la agenda',
              ayuda: 'Toca para reintentar.',
              icono: Icons.refresh,
              alTocar:
                  habilitado
                      ? () => ref.invalidate(agendaEmpleadosProvider)
                      : null,
            ),
        data: (agenda) {
          final lista = opciones(agenda);
          final elegida = lista.where((o) => o.valor == valor).firstOrNull;
          return CampoSelectorHex(
            etiqueta: etiqueta,
            valor: elegida?.texto,
            pista: pista,
            ayuda: ayuda,
            icono: Icons.search,
            alQuitar: habilitado ? alQuitar : null,
            textoQuitar: textoQuitar,
            alTocar:
                habilitado
                    ? () async {
                      final v = await pedirOpcionHex<T>(
                        context,
                        titulo: etiqueta,
                        opciones: lista,
                        actual: valor,
                      );
                      if (v != null && context.mounted) alElegir(v);
                    }
                    : null,
          );
        },
      );
}

/// El rol y el cargo que definen la rama: «Encargado · Jefe de producción».
String alcanceAprobadorHex(HexAprobadorEntity a) {
  final cargo = textoUsableHex(a.cargo);
  final rol = oGuionHex(a.nivelTexto);
  return cargo == null ? rol : '$rol · $cargo';
}

/// La ayuda bajo el rol elegido en «Asignar aprobador».
const String ayudaEncargadoHex =
    'Da el visto bueno a los reportes de los empleados de su rama: todos los '
    'cargos debajo del suyo en el organigrama, en todas las sucursales.';
const String ayudaJefeHex =
    'Aprueba los vistos buenos de los encargados que elijas, y las horas '
    'extra de esos encargados. No depende del organigrama.';
const String ayudaObservadorHex =
    'El observador ve los reportes y su historial de los encargados que se le '
    'asignan; no firma ni aprueba.';

/// La etiqueta del campo de encargados de un jefe de área (D35).
const String etiquetaEncargadosHex = 'Encargados que aprueba';

/// La del campo de encargados de un observador (D45).
const String etiquetaEncargadosObservadorHex = 'Encargados que observa';

/// Los niveles de aprobador de «Asignar aprobador» (D34, D35, D45).
const int nivelEncargadoHex = 1;
const int nivelJefeHex = 2;
const int nivelObservadorHex = 3;

/// «Cargo · N empleados» de un encargado para elegir.
String apoyoEncargadoHex(HexEncargadoOpcionEntity e) => [
  if (textoUsableHex(e.cargo) case final cargo?) cargo,
  cuentaHex(e.cantidadRama, 'empleado', 'empleados'),
].join(' · ');

/// «Ya lo aprueba: …» con los jefes del SP, o nulo si no tiene ninguno.
String? jefesActualesHex(HexEncargadoOpcionEntity e) =>
    textoUsableHex(e.jefesActuales) == null
        ? null
        : 'Ya lo aprueba: ${e.jefesActuales!.trim()}';

// ═══════════════════════════════════════════════════════════════════════════
// ENTRADAS PÚBLICAS
// ═══════════════════════════════════════════════════════════════════════════

/// Asigna un aprobador elegido de la agenda. Quién asigna lo pone el backend
/// desde el token; si es la misma persona o su jefe, el SP responde (D21).
Future<void> asignarAprobadorHex(
  BuildContext context,
  WidgetRef ref, {
  required VoidCallback refrescar,
}) {
  final repo = ref.read(hexConfiguracionRepositoryProvider);
  return abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) =>
            _AsignarAprobadorHex(repo: repo, refrescarLista: recargar),
  );
}

/// Cierra la asignación [a]: sin fecha deja de regir hoy (lo decide el SP).
Future<void> cerrarAprobadorHex(
  BuildContext context,
  WidgetRef ref,
  HexAprobadorEntity a, {
  required VoidCallback refrescar,
}) async {
  final id = a.idAprobador;
  if (id == null) return;
  final repo = ref.read(hexConfiguracionRepositoryProvider);
  await abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) => _CerrarAprobadorHex(
          aprobador: a,
          cerrar: (hasta) => repo.cerrarAprobador(id, vigenteHasta: hasta),
          refrescarLista: recargar,
        ),
  );
}

/// Confirma y elimina la asignación [a]. Si ya tiene firmas o empezó a regir,
/// el SP no lo deja y su mensaje se muestra; [ocupado] evita repetirla.
Future<void> eliminarAprobadorHex(
  BuildContext context,
  WidgetRef ref,
  HexAprobadorEntity a, {
  required OcupadoHex ocupado,
  required VoidCallback refrescar,
}) async {
  final id = a.idAprobador;
  if (id == null || ocupado.value) return;
  final repo = ref.read(hexConfiguracionRepositoryProvider);
  FocusManager.instance.primaryFocus?.unfocus();
  final alcance = [
    alcanceAprobadorHex(a),
    if (a.nivel >= nivelJefeHex) textoAlcanceHex(a),
  ].join(' · ');
  final si = await confirmar(
    context,
    titulo: 'Eliminar asignación',
    detalle:
        'Se elimina la asignación de «${oGuionHex(a.nombreAprobador)}» '
        '($alcance) que rige desde el '
        '${fechaHex(a.vigenteDesde)}. Queda registrada en el historial de '
        'cambios.',
    textoConfirmar: 'Eliminar',
    destructiva: true,
  );
  if (!si || !context.mounted) return;
  await ejecutarHex(
    context,
    ocupado: ocupado,
    accion: (_) => repo.eliminarAprobador(id),
    refrescar: refrescar,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS
// ═══════════════════════════════════════════════════════════════════════════

const SizedBox _entre = SizedBox(height: Esp.l);

/// El título de la vista previa de la rama en «Asignar aprobador».
const String tituloVistaPreviaRamaHex = 'Vista previa de su rama';

/// La vista previa en la columna derecha del diálogo ancho: sin persona,
/// una pista; con ella, la rama con su propio desplazamiento.
class _PreviaLateralHex extends StatelessWidget {
  const _PreviaLateralHex({required this.codEmpleado});

  final BigInt? codEmpleado;

  @override
  Widget build(BuildContext context) {
    final cod = codEmpleado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Esp.s, bottom: Esp.s),
          child: Text(
            tituloVistaPreviaRamaHex,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
          ),
        ),
        Expanded(
          child:
              cod == null
                  ? Text(
                    'Elige una persona para ver toda su rama y quién firma '
                    'hoy a cada empleado.',
                    style: context.apagado(),
                  )
                  : VistaPreviaRamaHex(codEmpleado: cod, desplazable: true),
        ),
      ],
    );
  }
}

/// La vista previa bajo el formulario en el teléfono: una sección plegable,
/// abierta al empezar, que crece con su contenido.
class _PreviaPlegableHex extends StatelessWidget {
  const _PreviaPlegableHex({required this.codEmpleado});

  final BigInt codEmpleado;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: Esp.s),
    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
    shape: const Border(),
    collapsedShape: const Border(),
    leading: const Icon(Icons.account_tree_outlined),
    title: Text(
      tituloVistaPreviaRamaHex,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
    ),
    children: [
      VistaPreviaRamaHex(codEmpleado: codEmpleado, desplazable: false),
    ],
  );
}

/// «Rige hasta», que se puede dejar vacía: el campo abre el calendario y,
/// con una fecha, la «x» la quita. Sin [alCambiar] (escritura en curso) no
/// se toca.
class _RigeHastaHex extends StatelessWidget {
  const _RigeHastaHex({
    required this.fecha,
    required this.pista,
    required this.ayuda,
    required this.alCambiar,
  });

  final DateTime? fecha;
  final String pista;
  final String ayuda;
  final ValueChanged<DateTime?>? alCambiar;

  Future<void> _elegir(BuildContext context) async {
    final f = await pedirDiaHex(context, inicial: fecha, ayuda: 'Rige hasta');
    if (f != null && context.mounted) alCambiar?.call(f);
  }

  @override
  Widget build(BuildContext context) {
    final cambiar = alCambiar;
    return CampoSelectorHex(
      etiqueta: 'Rige hasta',
      valor: fecha == null ? null : fechaHex(fecha),
      pista: pista,
      icono: Icons.event_outlined,
      ayuda: ayuda,
      textoQuitar: 'Quitar la fecha',
      alQuitar: cambiar == null ? null : () => cambiar(null),
      alTocar: cambiar == null ? null : () => _elegir(context),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENCARGADOS DE UN JEFE DE ÁREA (D35)
// ═══════════════════════════════════════════════════════════════════════════

/// El título de la vista previa de las ramas de los encargados elegidos.
const String tituloVistaPreviaRamasJefeHex = 'Vista previa de sus ramas';

/// «Ya lo aprueba: …» en el tono terciario, con su ícono.
class _JefesActualesHex extends StatelessWidget {
  const _JefesActualesHex(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.supervisor_account_outlined,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: Esp.xs),
        Expanded(
          child: Text(
            texto,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Elige varios encargados con buscador, en su propio diálogo. Devuelve los
/// elegidos en el orden del SP, o nulo si se cancela.
Future<List<HexEncargadoOpcionEntity>?> _pedirEncargadosHex(
  BuildContext context, {
  required List<HexEncargadoOpcionEntity> opciones,
  required Set<BigInt> elegidos,
  required String etiqueta,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<List<HexEncargadoOpcionEntity>>(
    context: context,
    builder:
        (_) => _ElegirEncargadosHex(
          opciones: opciones,
          iniciales: elegidos,
          etiqueta: etiqueta,
        ),
  );
}

class _ElegirEncargadosHex extends StatefulWidget {
  const _ElegirEncargadosHex({
    required this.opciones,
    required this.iniciales,
    required this.etiqueta,
  });

  final List<HexEncargadoOpcionEntity> opciones;
  final Set<BigInt> iniciales;
  final String etiqueta;

  @override
  State<_ElegirEncargadosHex> createState() => _ElegirEncargadosHexState();
}

class _ElegirEncargadosHexState extends State<_ElegirEncargadosHex> {
  static final RegExp _espacios = RegExp(r'\s+');

  final TextEditingController _buscar = TextEditingController();
  final ScrollController _lista = ScrollController();
  late final Set<BigInt> _elegidos = {...widget.iniciales};

  /// Nombre, cargo y jefes de cada opción sin mayúsculas ni tildes.
  late final List<String> _claves = [
    for (final o in widget.opciones)
      sinTildes(
        '${o.nombreEmpleado}\n${o.cargo ?? ''}\n${o.jefesActuales ?? ''}',
      ),
  ];

  @override
  void dispose() {
    _buscar.dispose();
    _lista.dispose();
    super.dispose();
  }

  List<HexEncargadoOpcionEntity> _visibles() {
    final palabras = [
      for (final p in sinTildes(_buscar.text).split(_espacios))
        if (p.isNotEmpty) p,
    ];
    return [
      for (var i = 0; i < widget.opciones.length; i++)
        if (widget.opciones[i].codEmpleado != null &&
            palabras.every(_claves[i].contains))
          widget.opciones[i],
    ];
  }

  void _alternar(BigInt cod) => setState(() {
    if (!_elegidos.remove(cod)) _elegidos.add(cod);
  });

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles();
    final vacio =
        widget.opciones.isEmpty
            ? 'Nadie tiene rol de encargado: asígnalo primero.'
            : 'Nada coincide con «${_buscar.text.trim()}».';
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.xl, Esp.l, Esp.xl, 2),
              child: Text(
                widget.etiqueta,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.xl, 0, Esp.xl, Esp.s),
              child: Text(
                cuentaHex(_elegidos.length, 'elegido', 'elegidos'),
                style: context.apagado(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.l),
              child: TextField(
                controller: _buscar,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Escribe para buscar…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: Esp.xs),
            Expanded(
              child:
                  visibles.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Esp.l),
                          child: Text(
                            vacio,
                            textAlign: TextAlign.center,
                            style: context.apagado(),
                          ),
                        ),
                      )
                      : Scrollbar(
                        controller: _lista,
                        child: ListView.builder(
                          controller: _lista,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: visibles.length,
                          itemBuilder: (_, i) {
                            final o = visibles[i];
                            final cod = o.codEmpleado!;
                            final jefes = jefesActualesHex(o);
                            return CheckboxListTile(
                              value: _elegidos.contains(cod),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (_) => _alternar(cod),
                              title: Text(oGuionHex(o.nombreEmpleado)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(apoyoEncargadoHex(o)),
                                  if (jefes != null) _JefesActualesHex(jefes),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.s, 0, Esp.m, Esp.s),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: Esp.s,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed:
                        () => Navigator.of(context).pop([
                          for (final o in widget.opciones)
                            if (_elegidos.contains(o.codEmpleado)) o,
                        ]),
                    child: const Text('Listo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Encargados que aprueba» (o «que observa»): el campo abre el buscador de
/// varios y, debajo, los elegidos con su «x». Mientras carga lo dice; si
/// falla, se toca para reintentar. Sin [habilitado] (escritura en curso) no
/// se toca.
class _CampoEncargadosHex extends ConsumerWidget {
  const _CampoEncargadosHex({
    required this.elegidos,
    required this.alCambiar,
    required this.habilitado,
    this.etiqueta = etiquetaEncargadosHex,
  });

  final List<HexEncargadoOpcionEntity> elegidos;
  final ValueChanged<List<HexEncargadoOpcionEntity>> alCambiar;
  final bool habilitado;
  final String etiqueta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campo = ref
        .watch(hexEncargadosParaJefeProvider)
        .when(
          skipLoadingOnReload: true,
          loading:
              () => CampoSelectorHex(
                etiqueta: etiqueta,
                valor: null,
                pista: 'Cargando los encargados…',
                icono: Icons.hourglass_empty,
                alTocar: null,
              ),
          error:
              (e, _) => CampoSelectorHex(
                etiqueta: etiqueta,
                valor: null,
                pista:
                    e is SinPermisoHex
                        ? 'No tienes permiso'
                        : 'No se pudieron cargar los encargados',
                ayuda: e is SinPermisoHex ? null : 'Toca para reintentar.',
                icono: Icons.refresh,
                alTocar:
                    habilitado && e is! SinPermisoHex
                        ? () => ref.invalidate(hexEncargadosParaJefeProvider)
                        : null,
              ),
          data:
              (opciones) => CampoSelectorHex(
                etiqueta: etiqueta,
                valor:
                    elegidos.isEmpty
                        ? null
                        : cuentaHex(
                          elegidos.length,
                          'encargado elegido',
                          'encargados elegidos',
                        ),
                pista: 'Elige uno o más',
                icono: Icons.checklist,
                textoQuitar: 'Quitar todos',
                alQuitar: habilitado ? () => alCambiar(const []) : null,
                alTocar:
                    habilitado
                        ? () async {
                          final v = await _pedirEncargadosHex(
                            context,
                            opciones: opciones,
                            elegidos: {
                              for (final e in elegidos)
                                if (e.codEmpleado case final c?) c,
                            },
                            etiqueta: etiqueta,
                          );
                          if (v != null && context.mounted) alCambiar(v);
                        }
                        : null,
              ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        campo,
        for (final e in elegidos)
          _EncargadoElegidoHex(
            e,
            alQuitar:
                habilitado
                    ? () => alCambiar([
                      for (final o in elegidos)
                        if (o.codEmpleado != e.codEmpleado) o,
                    ])
                    : null,
          ),
      ],
    );
  }
}

/// Un encargado elegido: nombre, «cargo · N empleados», si ya tiene jefe, y
/// la «x» que lo quita.
class _EncargadoElegidoHex extends StatelessWidget {
  const _EncargadoElegidoHex(this.e, {required this.alQuitar});

  final HexEncargadoOpcionEntity e;
  final VoidCallback? alQuitar;

  @override
  Widget build(BuildContext context) {
    final jefes = jefesActualesHex(e);
    final nombre = oGuionHex(e.nombreEmpleado);
    return Padding(
      padding: const EdgeInsets.only(top: Esp.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: Esp.s),
            child: Icon(
              Icons.task_alt,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: Esp.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                  ),
                  Text(apoyoEncargadoHex(e), style: context.apagado()),
                  if (jefes != null) _JefesActualesHex(jefes),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Quitar a $nombre',
            onPressed: alQuitar,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

/// La rama de un encargado elegido, plegable y abierta al empezar: reutiliza
/// [VistaPreviaRamaHex] con el encargado, que crece con su contenido.
class _RamaEncargadoPlegableHex extends StatelessWidget {
  const _RamaEncargadoPlegableHex(this.e, {super.key});

  final HexEncargadoOpcionEntity e;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: Esp.s),
    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
    shape: const Border(),
    collapsedShape: const Border(),
    leading: const Icon(Icons.account_tree_outlined),
    title: Text(
      'Rama de ${oGuionHex(e.nombreEmpleado)}',
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
    ),
    subtitle: Text(apoyoEncargadoHex(e), style: context.apagado()),
    children: [
      VistaPreviaRamaHex(codEmpleado: e.codEmpleado!, desplazable: false),
    ],
  );
}

/// Las ramas de los encargados elegidos, una sección plegable por cada uno.
List<Widget> _ramasEncargadosHex(List<HexEncargadoOpcionEntity> elegidos) => [
  for (final e in elegidos)
    if (e.codEmpleado != null)
      _RamaEncargadoPlegableHex(e, key: ValueKey(e.codEmpleado)),
];

/// La columna derecha del diálogo ancho para un jefe: sin encargados, una
/// pista; con ellos, sus ramas en una lista con su propio desplazamiento.
class _PreviasLateralesJefeHex extends StatefulWidget {
  const _PreviasLateralesJefeHex({required this.elegidos});

  final List<HexEncargadoOpcionEntity> elegidos;

  @override
  State<_PreviasLateralesJefeHex> createState() =>
      _PreviasLateralesJefeHexState();
}

class _PreviasLateralesJefeHexState extends State<_PreviasLateralesJefeHex> {
  final ScrollController _control = ScrollController();

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ramas = _ramasEncargadosHex(widget.elegidos);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Esp.s, bottom: Esp.s),
          child: Text(
            tituloVistaPreviaRamasJefeHex,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
          ),
        ),
        Expanded(
          child:
              ramas.isEmpty
                  ? Text(
                    'Elige uno o más encargados para ver su rama y quién '
                    'firma hoy a cada empleado.',
                    style: context.apagado(),
                  )
                  : Scrollbar(
                    controller: _control,
                    child: ListView(
                      controller: _control,
                      padding: const EdgeInsets.only(
                        right: Esp.m,
                        bottom: Esp.m,
                      ),
                      children: ramas,
                    ),
                  ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ASIGNAR
// ═══════════════════════════════════════════════════════════════════════════

class _AsignarAprobadorHex extends StatefulWidget {
  const _AsignarAprobadorHex({
    required this.repo,
    required this.refrescarLista,
  });

  final HexConfiguracionRepository repo;
  final VoidCallback refrescarLista;

  @override
  State<_AsignarAprobadorHex> createState() => _AsignarAprobadorHexState();
}

class _AsignarAprobadorHexState extends State<_AsignarAprobadorHex>
    with EscrituraEnDialogoHex {
  int _nivel = nivelEncargadoHex;
  BigInt? _aprobador;
  List<HexEncargadoOpcionEntity> _encargados = const [];
  DateTime _desde = DateUtils.dateOnly(DateTime.now());
  DateTime? _hasta;

  @override
  VoidCallback get refrescarLista => widget.refrescarLista;

  String get _ayudaDelNivel => switch (_nivel) {
    nivelObservadorHex => ayudaObservadorHex,
    nivelJefeHex => ayudaJefeHex,
    _ => ayudaEncargadoHex,
  };

  bool get _esEncargado => _nivel == nivelEncargadoHex;

  bool get _esObservador => _nivel == nivelObservadorHex;

  // Encargado: persona, rol y vigencia (su rama la calcula el SP). Jefe y
  // observador: además los encargados; si falta alguno, responde el backend.
  void _guardar() {
    final a = HexAprobadorEntity(
      codEmpleadoAprobador: _aprobador,
      nivel: _nivel,
      codEmpleadosAprobados: [
        if (!_esEncargado)
          for (final e in _encargados)
            if (e.codEmpleado case final cod?) cod,
      ],
      vigenteDesde: _desde,
      vigenteHasta: _hasta,
    );
    escribir((_) => widget.repo.asignarAprobador(a));
  }

  Future<void> _elegirDesde() async {
    final f = await pedirDiaHex(context, inicial: _desde, ayuda: 'Rige desde');
    if (f != null && mounted) setState(() => _desde = f);
  }

  @override
  Widget build(BuildContext context) {
    final persona = _aprobador;
    final doble = dialogoDobleHex(context);
    return DialogoHex(
      titulo: 'Asignar aprobador',
      icono: Icons.person_add_alt_1_outlined,
      ocupado: ocupado,
      accion: 'Asignar',
      alAceptar: _guardar,
      lateral:
          (_) =>
              _esEncargado
                  ? _PreviaLateralHex(codEmpleado: persona)
                  : _PreviasLateralesJefeHex(elegidos: _encargados),
      contenido:
          (enCurso) => [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: nivelEncargadoHex,
                  label: Text('Encargado'),
                ),
                ButtonSegment(value: nivelJefeHex, label: Text('Jefe de área')),
                ButtonSegment(
                  value: nivelObservadorHex,
                  label: Text('Observador'),
                ),
              ],
              selected: {_nivel},
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.standard,
                minimumSize: const Size(0, 48),
              ),
              onSelectionChanged:
                  enCurso
                      ? null
                      : (s) {
                        HapticaHex.seleccion();
                        setState(() => _nivel = s.first);
                      },
            ),
            const SizedBox(height: Esp.xs),
            Text(_ayudaDelNivel, style: context.apagado()),
            _entre,
            CampoAgendaHex<BigInt>(
              etiqueta: 'Persona',
              valor: _aprobador,
              opciones: personasDeAgendaHex,
              habilitado: !enCurso,
              alElegir: (v) => setState(() => _aprobador = v),
            ),
            if (!_esEncargado) ...[
              _entre,
              _CampoEncargadosHex(
                elegidos: _encargados,
                habilitado: !enCurso,
                alCambiar: (v) => setState(() => _encargados = v),
                etiqueta:
                    _esObservador
                        ? etiquetaEncargadosObservadorHex
                        : etiquetaEncargadosHex,
              ),
            ],
            _entre,
            CampoSelectorHex(
              etiqueta: 'Rige desde',
              valor: fechaHex(_desde),
              icono: Icons.event_outlined,
              alTocar: enCurso ? null : _elegirDesde,
            ),
            _entre,
            _RigeHastaHex(
              fecha: _hasta,
              pista: 'Sin fecha de fin',
              ayuda: 'Opcional: sin fecha, rige hasta que la cierres.',
              alCambiar: enCurso ? null : (f) => setState(() => _hasta = f),
            ),
            if (!doble && _esEncargado && persona != null) ...[
              const SizedBox(height: Esp.s),
              _PreviaPlegableHex(codEmpleado: persona),
            ],
            if (!doble && !_esEncargado && _encargados.isNotEmpty) ...[
              const SizedBox(height: Esp.m),
              Text(
                tituloVistaPreviaRamasJefeHex,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
              ),
              ..._ramasEncargadosHex(_encargados),
            ],
          ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CERRAR
// ═══════════════════════════════════════════════════════════════════════════

class _CerrarAprobadorHex extends StatefulWidget {
  const _CerrarAprobadorHex({
    required this.aprobador,
    required this.cerrar,
    required this.refrescarLista,
  });

  final HexAprobadorEntity aprobador;
  final Future<HexRespuesta> Function(DateTime? hasta) cerrar;
  final VoidCallback refrescarLista;

  @override
  State<_CerrarAprobadorHex> createState() => _CerrarAprobadorHexState();
}

class _CerrarAprobadorHexState extends State<_CerrarAprobadorHex>
    with EscrituraEnDialogoHex {
  DateTime? _hasta;

  @override
  VoidCallback get refrescarLista => widget.refrescarLista;

  @override
  Widget build(BuildContext context) {
    final a = widget.aprobador;
    return DialogoHex(
      titulo: 'Fin de la asignación',
      icono: Icons.event_busy_outlined,
      ocupado: ocupado,
      accion: 'Cerrar asignación',
      alAceptar: () => escribir((_) => widget.cerrar(_hasta)),
      contenido:
          (enCurso) => [
            Text(
              oGuionHex(a.nombreAprobador),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
            ),
            Text(alcanceAprobadorHex(a)),
            if (a.nivel >= nivelJefeHex) Text(textoAlcanceHex(a)),
            Text(
              'Rige desde el ${fechaHex(a.vigenteDesde)}.',
              style: context.apagado(),
            ),
            _entre,
            _RigeHastaHex(
              fecha: _hasta,
              pista: 'Hoy',
              ayuda: 'Sin fecha: deja de regir hoy',
              alCambiar: enCurso ? null : (f) => setState(() => _hasta = f),
            ),
          ],
    );
  }
}
