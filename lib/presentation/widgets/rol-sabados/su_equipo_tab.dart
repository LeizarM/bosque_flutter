import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/mi_equipo_entity.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
// Sólo por `filtrarSabados` (función pura; ya la importan así matriz, personal
// y cambios): no se depende del provider de mes de la grilla.
import 'package:bosque_flutter/presentation/widgets/rol-sabados/filtros_grilla.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/su_equipo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// «Su equipo»: el sábado visto desde el lado del jefe.
///
/// Misma grilla, otra pregunta («¿quién de los míos viene este sábado?»):
/// arranca en el **próximo** sábado y muestra a la gente que el organigrama da a
/// quien mira (`dbo.fn_trs_ProgramadorDependiente`, puede llegar vacío y tiene su
/// mensaje). El jefe sólo pone '1' o 'L'; lo que carga RR.HH. (vacaciones, bajas,
/// feriados, permisos) se muestra bloqueado **con el motivo al lado**.
class SuEquipoTab extends ConsumerWidget {
  const SuEquipoTab({super.key, required this.idRol});

  final int idRol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miEquipo = ref.watch(miEquipoProvider);
    final grilla = ref.watch(grillaRolProvider(idRol));

    return miEquipo.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => MensajeVacio(
            icono: Icons.error_outline,
            titulo: 'No se pudo saber a quién programas',
            detalle: textoParaUsuario(e),
          ),
      data:
          (equipo) => grilla.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (e, _) => MensajeVacio(
                  icono: Icons.error_outline,
                  titulo: 'No se pudo cargar la grilla',
                  detalle: textoParaUsuario(e),
                ),
            data: (g) => _Vista(idRol: idRol, equipo: equipo, grilla: g),
          ),
    );
  }
}

// La vista

class _Vista extends ConsumerStatefulWidget {
  const _Vista({
    required this.idRol,
    required this.equipo,
    required this.grilla,
  });

  final int idRol;
  final MiEquipoEntity equipo;
  final GrillaRol grilla;

  @override
  ConsumerState<_Vista> createState() => _VistaState();
}

class _VistaState extends ConsumerState<_Vista> {
  /// Los sábados que ya pasaron no se ofrecen: no se programa hacia atrás. Se
  /// pueden mostrar igual, en sólo lectura, para revisar qué se decidió.
  bool _verPasados = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.grilla;
    final equipo = widget.equipo;

    if (equipo.sinEquipo) {
      return const MensajeVacio(
        icono: Icons.groups_outlined,
        titulo: 'No tienes a nadie a cargo',
        detalle:
            'Tienes el permiso pero el organigrama no te da ninguna persona a '
            'cargo. Avisa a RR.HH. para que revisen de quién dependes y quién '
            'depende de ti.',
      );
    }

    final hoy = _soloFecha(DateTime.now());
    final futuros = g.sabados.where((s) => !_yaPaso(s, hoy)).toList();
    // Si el año se terminó entero, se muestran todos igual: la pestaña sin nada
    // adentro no explicaría por qué está vacía.
    final visibles = (_verPasados || futuros.isEmpty) ? g.sabados : futuros;

    if (visibles.isEmpty) {
      // Sin condicional: esta pestaña sólo la ve el jefe programador, que es justo
      // quien no tiene la varita; mandarlo a un botón que no está lo deja sin salida.
      return const MensajeVacio(
        icono: Icons.event_busy,
        titulo: 'El rol no tiene sábados',
        detalle:
            'Este rol se creó sin fechas. Avisa a RR.HH. para que lo '
            'regenere.',
      );
    }

    // El próximo sábado es el default; el elegido vive en el provider para que
    // sobreviva a un cambio de pestaña.
    final porDefecto = futuros.isNotEmpty ? futuros.first : g.sabados.last;
    final pedido = ref.watch(sabadoElegidoProvider);
    // Ojo: contra `visibles` y NUNCA contra los del mes; si no, el filtro se
    // mordería la cola y no habría forma de salir de octubre.
    final sabado = visibles.firstWhere(
      (s) => s.idSabado == pedido,
      orElse: () => porDefecto,
    );

    // **El mes no es un estado: se deriva del sábado elegido.** Un provider aparte
    // admitiría «mes = octubre, sábado = 07/11» (el choque que tapa el `orElse`).
    // Sin fecha, mes 0 y `filtrarSabados` devuelve todo: degrada a la tira larga.
    final mes = sabado.fecha?.month ?? 0;
    final delMes = filtrarSabados(visibles, mes);

    final filas = _armarFilas(sabado, hoy);
    final cuenta = _Cuenta.de(g, sabado, filas);

    // Las flechas navegan sobre `visibles` y NUNCA sobre los del mes: plegada, la
    // barra es la única forma de moverse y no se llegaría del 29/08 al 05/09.
    // Cruzar de mes sale gratis porque el mes se deriva del sábado.
    final i = visibles.indexOf(sabado);
    final anterior = i > 0 ? visibles[i - 1] : null;
    final siguiente =
        i >= 0 && i < visibles.length - 1 ? visibles[i + 1] : null;

    void elegir(int idSabado) =>
        ref.read(sabadoElegidoProvider.notifier).state = idSabado;

    // Se lee aquí y no adentro del LayoutBuilder porque `ref.watch` va en el
    // build; el ancho se le aplica después.
    final plegadoElegido = ref.watch(cabeceraEquipoPlegadaProvider);

    return LayoutBuilder(
      builder: (context, cajon) {
        // El ancho REAL del panel y no el de la pantalla (el dashboard tiene sidebar):
        // lo usan el panorama, el default del plegado y la forma del rótulo.
        final aire = Aire.de(cajon.maxWidth);

        // **El teléfono arranca plegado; tablet y escritorio, desplegados.** Medido en
        // un 360×740: a la pestaña le quedan 475 px y la cabecera desplegada se lleva
        // 433 (sobran 42, media fila); una lista cortada a una fila se lee como «esto
        // está roto» (ver `isThreeLine`). Plegada son ~72 px (~96 con el rol corto; 125
        // en el banco de pruebas, de letra más ancha) y entran cinco personas. Se
        // esconde NAVEGACIÓN, que se usa después de leer. En pantalla ancha el
        // panorama está al lado: esconder los chips de mes cobraría taps por aire que sobra.
        final plegada = plegadoElegido ?? aire.esChico;

        final vista = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // La barra queda ARRIBA de lo que pliega (no negociable): con el asa abajo, al
            // plegar se correría ~370 px y se iría de abajo del dedo en el mismo gesto.
            _BarraDelSabado(
              sabado: sabado,
              cuenta: cuenta,
              plegada: plegada,
              rotuloLargo: !aire.esChico,
              yaPaso: _yaPaso(sabado, hoy),
              reemplazo: equipo.actuaComoReemplazo ? equipo.jefe : null,
              anterior: anterior,
              siguiente: siguiente,
              onElegir: elegir,
              // Deshabilitado desde afuera, como todo el módulo.
              onEsteSabado:
                  sabado.idSabado == porDefecto.idSabado
                      ? null
                      : () => elegir(porDefecto.idSabado),
              onPlegar:
                  () =>
                      ref.read(cabeceraEquipoPlegadaProvider.notifier).state =
                          !plegada,
            ),
            // Separa lo que queda clavado (la barra) de lo que scrollea.
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                // Cambiar de sábado es cambiar de pregunta: la key rehace la lista y descarta
                // el offset. Plegar y desplegar NO la toca.
                key: ValueKey(sabado.idSabado),
                padding: const EdgeInsets.only(top: Esp.xs, bottom: Esp.xxl),
                // La cabecera plegable es el primer ítem de la lista y no un hermano de alto
                // fijo: en 360×740 el panel mide 475 px y la desplegada pide 433 (532 con la
                // letra al 130%, y desborda). Como hermana de un `Expanded` lo que no entra es
                // inalcanzable; dentro del scroll no hay alto que respetar.
                itemCount: filas.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    // Son ~370 px que aparecen y desaparecen: sin transición la lista pega un
                    // salto. El ClipRect no es adorno: `RenderAnimatedSize` no recorta a su hijo y
                    // en los fotogramas intermedios la Column desborda (franja amarilla).
                    return ClipRect(
                      child: AnimatedSize(
                        duration: Durations.short4,
                        curve: Easing.standard,
                        // Crece hacia abajo: así el texto no se desplaza en el
                        // medio de la animación.
                        alignment: Alignment.topCenter,
                        child:
                            plegada
                                ? const SizedBox(width: double.infinity)
                                : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Sin divisores entre identidad, tira y resumen (una sola cabecera); el de
                                    // abajo separa la cabecera de la gente.
                                    _Identidad(
                                      equipo: equipo,
                                      personas: filas.length,
                                    ),
                                    _TiraSabados(
                                      delMes: delMes,
                                      visibles: visibles,
                                      mes: mes,
                                      seleccionado: sabado.idSabado,
                                      idPorDefecto: porDefecto.idSabado,
                                      verPasados: _verPasados,
                                      hayPasados:
                                          futuros.length != g.sabados.length,
                                      onVerPasados:
                                          (v) =>
                                              setState(() => _verPasados = v),
                                    ),
                                    _Resumen(cuenta: cuenta),
                                    const Divider(height: 1),
                                  ],
                                ),
                      ),
                    );
                  }

                  final f = filas[i - 1];
                  return _FilaDependiente(
                    grilla: g,
                    fila: f,
                    // El bloqueo se decide aquí y se baja como onTap nulo: el
                    // widget de la fila no tiene por qué conocer las reglas.
                    onTap:
                        f.bloqueo != null
                            ? null
                            : () => mostrarDecisionDelJefe(
                              context: context,
                              idRol: widget.idRol,
                              grilla: g,
                              dependiente: f.dependiente,
                              sabado: sabado,
                              celda: f.celda,
                            ),
                  );
                },
              ),
            ),
          ],
        );

        if (aire != Aire.amplio) return vista;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: vista),
            const VerticalDivider(width: 1),
            SizedBox(
              width: 380,
              child: _Panorama(
                grilla: g,
                columnas: delMes,
                mes: mes,
                filas: filas,
                hoy: hoy,
                seleccionado: sabado.idSabado,
                onElegir: (s, d, celda) {
                  ref.read(sabadoElegidoProvider.notifier).state = s.idSabado;
                  mostrarDecisionDelJefe(
                    context: context,
                    idRol: widget.idRol,
                    grilla: g,
                    dependiente: d,
                    sabado: s,
                    celda: celda,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // El cruce

  /// Mi gente, cruzada contra el rol para un sábado.
  ///
  /// Organigrama y rol son listas distintas (alguien puede depender de mí y no
  /// estar en el rol de este año): ese desfase es información, así que la persona
  /// aparece igual pero bloqueada y con el motivo.
  List<_Fila> _armarFilas(SabadoEntity sabado, DateTime hoy) {
    final g = widget.grilla;
    final porEmpleado = {for (final p in g.participantes) p.codEmpleado: p};

    final gente = [...widget.equipo.equipo]..sort((a, b) {
      // Primero los directos: son los que uno reconoce como «su» gente. Los del
      // sub-árbol vienen después y con etiqueta.
      final porNivel = a.profundidad.compareTo(b.profundidad);
      if (porNivel != 0) return porNivel;
      return a.nombreDependiente.toLowerCase().compareTo(
        b.nombreDependiente.toLowerCase(),
      );
    });

    final filas = <_Fila>[];
    for (final d in gente) {
      final p = porEmpleado[d.codDependiente];
      final celda =
          p == null ? null : g.celda(p.idParticipante, sabado.idSabado);
      filas.add(
        _Fila(
          dependiente: d,
          participante: p,
          celda: celda,
          bloqueo: _bloqueoDelCruce(
            grilla: g,
            participante: p,
            sabado: sabado,
            celda: celda,
            hoy: hoy,
          ),
        ),
      );
    }
    return filas;
  }
}

/// Por qué no se puede decidir sobre ese cruce persona × sábado, o null si sí.
///
/// **Gana el motivo más de fondo** (rol cerrado antes que «de vacaciones»).
/// Vive suelta porque la usan lista y panorama y son las mismas reglas de
/// `trs_sp_programar`; si dijeran otra cosa, el rechazo se sabría al guardar.
String? _bloqueoDelCruce({
  required GrillaRol grilla,
  required ParticipanteTurnoEntity? participante,
  required SabadoEntity sabado,
  required CeldaTurnoEntity? celda,
  required DateTime hoy,
}) {
  if (participante == null || participante.activo != 1) {
    return 'no está en el rol de este año';
  }
  if (grilla.rol.estaCerrado) return 'rol cerrado';
  if (sabado.activo != 1) return 'sábado desactivado';
  if (_yaPaso(sabado, hoy)) return 'ese sábado ya pasó';

  // Ojo con la 'P': aquí es el CÓDIGO de la celda —un permiso de RR.HH.— y no el
  // ORIGEN 'P', que es justamente lo que escribe un jefe.
  return switch (celda?.codigoExcel) {
    'V' => 'está de vacaciones según RR.HH.',
    'B' => 'está de baja según RR.HH.',
    'X' => 'feriado en su sucursal',
    'P' => 'tiene un permiso de RR.HH.',
    _ => null,
  };
}

/// Una persona del equipo en un sábado, ya cruzada con el rol.
class _Fila {
  const _Fila({
    required this.dependiente,
    required this.participante,
    required this.celda,
    required this.bloqueo,
  });

  final ProgramadorDependienteEntity dependiente;

  /// null = el organigrama la da a cargo, pero no está en el rol de este año.
  final ParticipanteTurnoEntity? participante;

  /// null = LIBRE. En este modelo el libre es la ausencia de la fila.
  final CeldaTurnoEntity? celda;

  /// Por qué no se puede decidir sobre esta persona ese día, o null.
  final String? bloqueo;

  bool get viene => celda?.codigoExcel == '1';
  bool get libre => celda == null || celda!.codigoExcel == 'L';

  /// La escribió un jefe: origen 'P'. Dentro de mi propio equipo, la escribí yo
  /// (o el titular, si estoy actuando de reemplazo).
  bool get laDecidiUnJefe => celda?.origen == 'P';
}

/// Cómo quedó ese sábado: mi equipo y el rol entero, contados una sola vez.
///
/// Los muestran la barra y el resumen; con un bucle cada uno, un cambio de regla
/// («quien no está en el rol no es libre») los haría decir cosas distintas
/// (misma razón que [_bloqueoDelCruce]). Es una pasada sobre ≤20 filas.
class _Cuenta {
  const _Cuenta({
    required this.total,
    required this.vienen,
    required this.libres,
    required this.vacaciones,
    required this.mias,
    required this.otros,
    required this.cobertura,
    required this.objetivo,
  });

  factory _Cuenta.de(GrillaRol grilla, SabadoEntity sabado, List<_Fila> filas) {
    var vienen = 0;
    var libres = 0;
    var vacaciones = 0;
    var mias = 0;
    var otros = 0;
    for (final f in filas) {
      // Quien no está en el rol no es «libre»: no figura. Contarlo como libre haría
      // creer que hay gente disponible que no existe este año.
      if (f.participante == null) {
        otros++;
      } else if (f.viene) {
        vienen++;
      } else if (f.libre) {
        libres++;
      } else if (f.celda!.codigoExcel == 'V') {
        vacaciones++;
      } else {
        otros++;
      }
      if (f.laDecidiUnJefe) mias++;
    }

    return _Cuenta(
      total: filas.length,
      vienen: vienen,
      libres: libres,
      vacaciones: vacaciones,
      mias: mias,
      otros: otros,
      cobertura: grilla.coberturaDe(sabado.idSabado),
      objetivo: grilla.rol.coberturaObjetivo,
    );
  }

  /// Mi equipo.
  final int total;
  final int vienen;
  final int libres;
  final int vacaciones;
  final int mias;
  final int otros;

  /// El día entero, todo el rol.
  final int cobertura;
  final int objetivo;

  bool get corta => objetivo > 0 && cobertura < objetivo;
  int get faltan => objetivo - cobertura;
}

DateTime _soloFecha(DateTime f) => DateTime(f.year, f.month, f.day);

bool _yaPaso(SabadoEntity s, DateTime hoy) =>
    s.fecha != null && _soloFecha(s.fecha!).isBefore(hoy);

// La barra del sábado

/// De qué sábado es la lista, y el asa que abre y cierra el resto.
///
/// Es lo único que sobrevive al plegado: sin la fecha, «Trabaja / Libre» es un
/// estado sin día. Lleva el mes escrito (`01 ago`, de [mesCorto]) porque las
/// flechas cruzan de mes sin avisar. **Cada cifra nombra su universo** (`tu
/// equipo:` / `todo el rol:`), como pieza suelta del [Wrap]: pegadas, «falta 1»
/// del rol se leería «de los tuyos». El asa es el chevron junto a la fecha.
class _BarraDelSabado extends StatelessWidget {
  const _BarraDelSabado({
    required this.sabado,
    required this.cuenta,
    required this.plegada,
    required this.rotuloLargo,
    required this.yaPaso,
    required this.reemplazo,
    required this.anterior,
    required this.siguiente,
    required this.onElegir,
    required this.onEsteSabado,
    required this.onPlegar,
  });

  final SabadoEntity sabado;
  final _Cuenta cuenta;
  final bool plegada;

  /// La fecha entera (`Sábado 01/08/2026`) en vez de `01 ago`. Es la única
  /// diferencia entre anchos, y sólo porque a partir de 600 px sobra lugar.
  final bool rotuloLargo;

  final bool yaPaso;

  /// El titular al que se está cubriendo, o null si es el equipo propio.
  final String? reemplazo;

  /// A dónde llevan las flechas. **null = no hay a dónde ir**, decidido afuera:
  /// la barra no sabe qué es «el último sábado» ni qué universo se está
  /// mirando.
  final SabadoEntity? anterior;
  final SabadoEntity? siguiente;

  final ValueChanged<int> onElegir;

  /// Vuelve al próximo sábado. null cuando ya estás parado ahí.
  final VoidCallback? onEsteSabado;

  final VoidCallback onPlegar;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final f = sabado.fecha;
    final rotulo =
        rotuloLargo
            ? 'Sábado ${fechaCorta(f)}'
            : f == null
            ? '--'
            : '${f.day.toString().padLeft(2, '0')} ${mesCorto(f.month)}';

    return Padding(
      // Esp.xs y no Esp.l: el chevron ya trae su aire dentro del objetivo táctil de
      // 48 px y cae en la misma columna que los textos de identidad y resumen.
      padding: const EdgeInsets.symmetric(horizontal: Esp.xs),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip:
                anterior == null
                    ? null
                    : 'Sábado ${fechaCorta(anterior!.fecha)}',
            onPressed:
                anterior == null ? null : () => onElegir(anterior!.idSabado),
          ),
          // Wrap y no Row: en 360 px al medio le quedan ~208-256 px y ni la cuenta del
          // equipo ni el aviso del rol entran junto al rótulo. Bajan de renglón (la barra
          // pasa de 48 a ~72, ~96 con el aviso) en vez de cortarse con «…», que vuelve
          // ambigua la cifra.
          Expanded(
            child: Wrap(
              spacing: Esp.s,
              runSpacing: Esp.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Tooltip(
                  message:
                      plegada
                          ? 'Elegir otro sábado'
                          : 'Ocultar los meses y los sábados',
                  child: TextButton(
                    onPressed: onPlegar,
                    style: TextButton.styleFrom(
                      // El rótulo es el título de la pantalla: con el color del botón se leería como
                      // un estado, y aquí el color codifica estado y nada más.
                      foregroundColor: cs.onSurface,
                      padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            rotulo,
                            style: context.tituloSeccion(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Esp.xs),
                        // Apunta a lo que va a pasar, no a lo que hay.
                        Icon(
                          plegada ? Icons.expand_more : Icons.expand_less,
                          size: 18,
                          color: cs.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                // La respuesta de la pestaña, con la población delante: `de 14` se verifica de
                // un vistazo contra las filas y la identidad. Rótulo apagado y dato en peso de
                // título: lo que se compara es el número.
                Text.rich(
                  TextSpan(
                    style: context.apagado(),
                    children: [
                      const TextSpan(text: 'tu equipo: '),
                      TextSpan(
                        text: 'vienen ${cuenta.vienen} de ${cuenta.total}',
                        // El color se repite a mano: el hijo hereda el del
                        // padre, y el del padre es el apagado del rótulo.
                        style: context.tituloSeccion()?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // La cobertura del día es lo único que avisa a un jefe que el sábado se queda
                // corto: la ALARMA no depende de desplegar (el detalle sí) y con el día cubierto
                // no se escribe nada. Lleva `todo el rol:` y «persona»: sin ellos, «falta 1»
                // junto a «vienen 7 de 14» se lee como faltante DE LOS TUYOS. Se pinta el
                // faltante, no el rótulo (el color codifica el estado).
                if (plegada && cuenta.corta)
                  Text.rich(
                    TextSpan(
                      style: context.apagado(),
                      children: [
                        const TextSpan(text: 'todo el rol: '),
                        TextSpan(
                          text:
                              cuenta.faltan == 1
                                  ? 'falta 1 persona'
                                  : 'faltan ${cuenta.faltan} personas',
                          style: context.numero(fuerte: true, color: cs.error),
                        ),
                      ],
                    ),
                  ),
                // Lo único de la identidad que no se puede esconder: cambia el significado de
                // CADA fila (estás moviendo gente que no es tuya).
                if (plegada && reemplazo != null)
                  Etiqueta(
                    texto: 'reemplazo de $reemplazo',
                    tono: TonoEtiqueta.aviso,
                  ),
                // Con el switch de «ver los que ya pasaron» escondido, quien está en un sábado
                // viejo vería filas bloqueadas sin pista de por qué.
                if (plegada && yaPaso)
                  const Etiqueta(texto: 'ya pasó', tono: TonoEtiqueta.aviso),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip:
                siguiente == null
                    ? null
                    : 'Sábado ${fechaCorta(siguiente!.fecha)}',
            onPressed:
                siguiente == null ? null : () => onElegir(siguiente!.idSabado),
          ),
          // «Este sábado» no sube a la barra (vive en la tira, junto a los chips que
          // gobierna): sube su versión de emergencia, sólo plegada y cuando hace falta,
          // para no dejar escondida la salida de diciembre. Moverse uno o dos sábados lo
          // resuelven las flechas.
          if (plegada && onEsteSabado != null)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: 'Volver al próximo sábado',
              onPressed: onEsteSabado,
            ),
        ],
      ),
    );
  }
}

// Tarjeta de identidad

/// Dos renglones que contestan «¿por qué veo a esta gente?». El segundo es para
/// el reemplazo: sin él, quien cubre a su jefe ve veinte personas que no son suyas.
class _Identidad extends StatelessWidget {
  const _Identidad({required this.equipo, required this.personas});

  final MiEquipoEntity equipo;
  final int personas;

  @override
  Widget build(BuildContext context) {
    // «todo TU árbol» y no «todo el árbol»: el resumen dice «todo el rol» (otra
    // población). La sucursal se nombra porque el filtro corre igual para DIRECTOS y
    // SUBARBOL, pero se dice lo que el permiso ES: con `codSucursal` en 0 la fila no
    // tiene sucursal y sí cruza (darlo por limitado dejó a un jefe sin ver a su
    // responsable de producción, colgado directo desde otra planta).
    final donde =
        equipo.codSucursal == 0
            ? 'en todas las sucursales'
            : 'en ${equipo.sucursal.isEmpty ? 'tu sucursal' : equipo.sucursal}';
    final alcance =
        equipo.alcance == 'SUBARBOL'
            ? 'todo tu árbol $donde'
            : 'tus directos $donde';

    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, Esp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Programas para tu equipo · $personas personas · alcance $alcance',
            style: context.tituloSeccion(),
          ),
          const SizedBox(height: 2),
          // Sólo lo que evita el ticket a soporte (por qué hay celdas que no se dejan
          // tocar); «puedes decidir…» ya lo dice la hoja. En 360 px, dos renglones en
          // vez de tres.
          Text(
            equipo.actuaComoReemplazo
                ? 'Estás programando como reemplazo de ${equipo.jefe}.'
                : 'Las vacaciones, las bajas y los feriados los carga RR.HH.: '
                    'se ven, pero no se tocan desde aquí.',
            style: context.apagado(),
          ),
        ],
      ),
    );
  }
}

// La tira de sábados

/// Dos niveles de fichas: el mes arriba, los sábados de ese mes abajo.
///
/// Un rol son ~52 sábados: en una sola tira llegar a diciembre eran 3 o 4
/// arrastres sin saber en qué mes se estaba; así la de abajo no pasa de cinco
/// fichas. Chips y no un combo: un tap en vez de dos y el mes queda a la vista.
class _TiraSabados extends ConsumerWidget {
  const _TiraSabados({
    required this.delMes,
    required this.visibles,
    required this.mes,
    required this.seleccionado,
    required this.idPorDefecto,
    required this.verPasados,
    required this.hayPasados,
    required this.onVerPasados,
  });

  /// Los sábados del mes que se está mirando: lo que se dibuja abajo.
  final List<SabadoEntity> delMes;

  /// El universo de los chips de mes: sale de `visibles` y no de `g.sabados` para
  /// que el switch de «ver los que ya pasaron» gobierne los dos niveles.
  final List<SabadoEntity> visibles;

  final int mes;
  final int seleccionado;

  /// El próximo sábado. `sabadoElegidoProvider` no es autoDispose a propósito
  /// (quien se fue mirando diciembre entra en diciembre): este botón lo trae de
  /// vuelta.
  final int idPorDefecto;

  final bool verPasados;
  final bool hayPasados;
  final ValueChanged<bool> onVerPasados;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El literal de Set en Dart conserva el orden de inserción, así que los
    // meses salen en el orden del rol y nunca aparece un mes vacío.
    final meses = {for (final s in visibles) s.fecha?.month ?? 0}..remove(0);

    void elegir(int idSabado) =>
        ref.read(sabadoElegidoProvider.notifier).state = idSabado;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.l, Esp.s, Esp.l, Esp.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap y no Row: en 360 px quedan 328 útiles y 12 chips de ~52 px bajan a dos
          // renglones (peor caso, mucho menos que 52 chips de sábado).
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final m in meses)
                ChoiceChip(
                  selected: m == mes,
                  label: Text(mesCorto(m)),
                  // Al cambiar de mes se elige su primer sábado: el mes es
                  // derivado, así que moverlo es mover el sábado.
                  onSelected:
                      (_) => elegir(filtrarSabados(visibles, m).first.idSabado),
                ),
              TextButton.icon(
                icon: const Icon(Icons.today, size: 18),
                label: const Text('Este sábado'),
                // Deshabilitado desde afuera, como todo el módulo: si ya estás
                // parado ahí, el botón no tiene nada que hacer.
                onPressed:
                    seleccionado == idPorDefecto
                        ? null
                        : () => elegir(idPorDefecto),
              ),
            ],
          ),
          const SizedBox(height: Esp.xs),
          // Sin alto fijo: el chip de Material reserva su objetivo táctil de 48 px y una
          // caja menor lo desborda. Wrap y no scroll: en 360 px, 5 chips de ~44 px más
          // separación son ~260 px sobre 328 útiles.
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.s,
            children: [
              for (final s in delMes)
                _ChipSabado(
                  sabado: s,
                  activo: s.idSabado == seleccionado,
                  onElegir: () => elegir(s.idSabado),
                ),
            ],
          ),
          if (hayPasados)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: verPasados,
                  onChanged: onVerPasados,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: Esp.s),
                // Flexible y no Text suelto: el switch se lleva 60 px de los 328 útiles y el
                // rótulo mide ~140, pero al 130% de letra se pasa y la Row lo cortaba. Que baje
                // de renglón; el switch no se mueve.
                Flexible(
                  child: Text(
                    'Ver los que ya pasaron',
                    style: context.apagado(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChipSabado extends StatelessWidget {
  const _ChipSabado({
    required this.sabado,
    required this.activo,
    required this.onElegir,
  });

  final SabadoEntity sabado;
  final bool activo;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Un puntito y no un fondo de color: el fondo ya lo usa la selección, y dos
    // señales en el mismo canal se pisan.
    final Color? marca =
        sabado.esFeriadoBool
            ? cs.error
            : sabado.tieneEvento
            ? cs.tertiary
            : null;

    return Tooltip(
      message: [
        fechaCorta(sabado.fecha),
        'rota el grupo ${sabado.grupoQueRota}',
        if (sabado.esFeriadoBool) 'FERIADO',
        if (sabado.tieneEvento) 'evento ${sabado.alcanceEvento}',
        if (sabado.motivoEspecial.isNotEmpty) sabado.motivoEspecial,
      ].join(' · '),
      child: ChoiceChip(
        selected: activo,
        onSelected: (_) => onElegir(),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (marca != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: marca, shape: BoxShape.circle),
              ),
              const SizedBox(width: Esp.xs),
            ],
            // El día solo: el mes ya está en la fila de arriba. Igual que la cabecera del
            // panorama y la matriz; la fecha completa sigue en el tooltip.
            Text(
              sabado.fecha == null
                  ? '--'
                  : sabado.fecha!.day.toString().padLeft(2, '0'),
              style: context.numero(fuerte: activo),
            ),
          ],
        ),
      ),
    );
  }
}

// El resumen del día

/// Cómo quedó mi equipo ese sábado, y cómo quedó el día en total.
///
/// **La cobertura del rol va aquí**: es el único dato que avisa a un jefe que el
/// sábado se queda corto (sin él, treinta jefes liberan a dos personas cada
/// uno). **Dos renglones y cada uno nombra su población** (`Tu equipo:` / `Todo
/// el rol ese sábado:`): leídos de corrido, los libres parecían del rol o el
/// faltante del equipo. La respuesta principal vive en la barra.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.cuenta});

  final _Cuenta cuenta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Los ceros no se escriben («0 de vacaciones» hay que leerlo para descartarlo);
    // `libres` va siempre porque su cero sí dice algo (vienen todos).
    final partes = [
      '${cuenta.libres} libres',
      if (cuenta.vacaciones > 0) '${cuenta.vacaciones} de vacaciones',
      // Las otras letras (cubierto, excusado, feriado, baja) son pocas: se agrupan
      // para que la cuenta cierre con el total.
      if (cuenta.otros > 0) '${cuenta.otros} en otra situación',
      if (cuenta.mias > 0) '${cuenta.mias} lo decidiste tú',
    ];

    final cobertura = cuenta.cobertura;
    final objetivo = cuenta.objetivo;
    final corta = cuenta.corta;
    final faltan = cuenta.faltan;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, Esp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cifras de las personas que programas; el rótulo lo dice porque el renglón de
          // abajo habla de otra población.
          Text('Tu equipo: ${partes.join(' · ')}', style: context.apagado()),
          const SizedBox(height: Esp.xs),
          // **Se pinta el número, no la frase:** la matriz pinta una cifra dentro de 42 px
          // y un renglón a todo el ancho era diez veces más rojo. **`vienen 42 · objetivo
          // 43` y no `42 de 43`:** arriba `vienen 7 de 14` el segundo número es CUÁNTOS
          // SON; aquí es CUÁNTOS HACEN FALTA (el rol tiene 87). «Todo el rol» evita que un
          // jefe de 14 lea el número como déficit suyo, «ese sábado» que lo lea como
          // acumulado del año, y la resta escrita evita hacerla de memoria.
          Text.rich(
            TextSpan(
              style: context.apagado(),
              children: [
                const TextSpan(text: 'Todo el rol ese sábado: vienen '),
                TextSpan(
                  text: '$cobertura',
                  style: context.numero(
                    fuerte: corta,
                    color: corta ? cs.error : Theme.of(context).hintColor,
                  ),
                ),
                if (objetivo > 0) TextSpan(text: ' · objetivo $objetivo'),
                if (corta)
                  TextSpan(
                    text:
                        faltan == 1
                            ? ' · falta 1 persona'
                            : ' · faltan $faltan personas',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// La lista de mi gente

/// Una persona del equipo en el sábado elegido. La letra y la esquinita son las
/// de la matriz y la agenda (una señal que cambia de forma se aprende tres veces).
class _FilaDependiente extends StatelessWidget {
  const _FilaDependiente({
    required this.grilla,
    required this.fila,
    required this.onTap,
  });

  final GrillaRol grilla;
  final _Fila fila;

  /// null = bloqueada. La razón está en [_Fila.bloqueo] y se muestra al lado.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = fila.dependiente;
    final celda = fila.celda;

    // **Sale del participante cruzado, NO de `d.sucDependiente`:** el organigrama
    // trae el CÓDIGO (y el suyo, no el del rol), no el nombre. Si la persona no
    // está en el rol (cruce null) no se dibuja nada: la etiqueta de bloqueo ya
    // explica su situación.
    final sucursal = fila.participante?.sucursal ?? '';

    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: fondoDeCelda(context, celda),
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Center(
                child: LetraDeCelda(
                  celda: celda,
                  estiloTexto: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: Peso.dato),
                ),
              ),
            ),
            if (celda?.esIntervencion == true)
              Positioned(
                top: 0,
                right: 0,
                child: MarcaDeIntervencion(color: cs.primary, lado: 9),
              ),
            // La misma esquina que en matriz y agenda; aquí importa más: el jefe que
            // aprueba un cambio en «Cambios» es quien mira este tab, y sin la marca la
            // celda le cuenta la mitad de lo que decidió.
            if (celda?.hayCambio == true)
              Positioned(
                bottom: 0,
                left: 0,
                child: MarcaDeCambio(color: cs.tertiary, lado: 9),
              ),
          ],
        ),
      ),
      title: Text(d.nombreDependiente, overflow: TextOverflow.ellipsis),
      // La condición es «¿el Wrap de abajo tendrá más de un elemento?». Normalmente
      // uno solo («Trabaja»), y reservar tres líneas costaba 88 px por persona donde
      // alcanzan 64: con 14 personas, ~340 px de scroll regalado y una lista cortada
      // a la séptima fila que se lee como error.
      isThreeLine: fila.bloqueo != null || fila.laDecidiUnJefe || !d.esDirecto,
      // Wrap y no Row: en 360 px el estado más dos etiquetas no entran en una
      // línea, y una Row las cortaría en vez de bajarlas.
      subtitle: Padding(
        padding: const EdgeInsets.only(top: Esp.xs),
        child: Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Dato(_estado()),
            if (!d.esDirecto) const Etiqueta(texto: 'indirecto'),
            if (fila.laDecidiUnJefe)
              const Etiqueta(
                texto: 'lo decidiste tú',
                tono: TonoEtiqueta.exito,
              ),
            if (fila.bloqueo != null)
              Etiqueta(texto: fila.bloqueo!, tono: TonoEtiqueta.aviso),
            // **Dónde está esa persona:** con alcance SUBARBOL el equipo cruza sucursales (a
            // un gerente le cuelga gente de CENTRAL y de SANTA CRUZ) y sin esto un jefe le
            // pone un sábado a alguien a 900 km del galpón que quería cubrir. **Última y en
            // `Dato`, no en `Etiqueta`:** es contexto, no estado, y en 360 px debe bajar el
            // dato menos urgente. **Sin el cargo** (a diferencia de «Grupos» y la agenda): un
            // jefe conoce a sus ≤20; lo que no ve es dónde están, y este es el Wrap más
            // apretado del módulo.
            if (sucursal.isNotEmpty) Dato(sucursal),
          ],
        ),
      ),
      // Lápiz y no chevron: el chevron es «te llevo a otra pantalla» y lo que se abre
      // es una hoja de dos botones. Sin icono sigue significando «no se toca».
      trailing:
          onTap == null
              ? null
              : const Tooltip(
                message: 'Decidir si viene',
                child: Icon(Icons.edit_outlined),
              ),
    );
  }

  /// Qué le pasa a esa persona ese sábado, en el idioma del catálogo.
  ///
  /// El cambio va antes que la observación (el motivo copiado por
  /// `trs_sp_corregirCelda`): si algo se corta al final, es lo ya deducido.
  String _estado() {
    final c = fila.celda;
    if (c == null) return 'Libre';
    final nombre = grilla.estados[c.codigoExcel]?.nombre ?? c.codigoExcel;
    return '$nombre'
        '${c.hayCambio ? ' · ${c.cambioTexto}' : ''}'
        '${c.observacion.isEmpty ? '' : ' · ${c.observacion}'}';
  }
}

// El panorama

/// Mi gente × los sábados del mes, en pantalla ancha.
///
/// La lista contesta «quién viene el 12»; el panorama, «a quién le cargo cuatro
/// sábados seguidos». Es mensual (4 o 5 columnas): con dos meses (8 × 34 px sobre
/// 380) quedaban 92 px de nombre («CARVAJAL RO…»); con el mes, ~194 px. Sin
/// `ScrollController` atados: ≤20 filas y 5 columnas.
class _Panorama extends StatelessWidget {
  const _Panorama({
    required this.grilla,
    required this.columnas,
    required this.mes,
    required this.filas,
    required this.hoy,
    required this.seleccionado,
    required this.onElegir,
  });

  final GrillaRol grilla;

  /// Los sábados del mes que se está mirando. Ya vienen filtrados de afuera.
  final List<SabadoEntity> columnas;

  /// Sólo para el título. Es el mismo mes del que salen [columnas].
  final int mes;

  /// Las mismas personas de la lista. De cada una se usa quién es y con qué
  /// participante del rol se cruzó; **la celda y el bloqueo se recalculan por
  /// columna**, porque dependen del sábado y no de la persona.
  final List<_Fila> filas;

  /// La fecha de hoy, ya sin hora. Viene de afuera para que las dos vistas
  /// bloqueen exactamente los mismos días.
  final DateTime hoy;

  final int seleccionado;
  final void Function(
    SabadoEntity,
    ProgramadorDependienteEntity,
    CeldaTurnoEntity?,
  )
  onElegir;

  static const double _lado = 34;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cajon) {
        // Lo que sobra tras las columnas del mes es la columna de nombres: con cinco
        // sábados en 380 px quedan ~194, el nombre entero en uno o dos renglones.
        final sobrante = cajon.maxWidth - Esp.s * 2 - columnas.length * _lado;
        final anchoNombre = sobrante < 72 ? 72.0 : sobrante;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.s, Esp.m, Esp.s, Esp.s),
              // El mes va aquí y no repetido bajo cada número (todas las columnas son del
              // mismo mes). Mes 0 es el sábado sin fecha: la tabla vuelve a mostrarlos todos
              // y el título viejo sigue siendo el correcto.
              child: Text(
                mes == 0
                    ? 'Tu gente, sábado a sábado'
                    : 'Tu gente en ${mesLargo(mes)}',
                style: context.tituloSeccion(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.s),
              child: Row(
                children: [
                  SizedBox(width: anchoNombre),
                  for (final s in columnas)
                    SizedBox(
                      width: _lado,
                      child: Center(
                        child: Text(
                          s.fecha == null
                              ? '--'
                              : s.fecha!.day.toString().padLeft(2, '0'),
                          style: context.numero(
                            fuerte: s.idSabado == seleccionado,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: Esp.m),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                child: Column(
                  children: [
                    for (final f in filas)
                      Row(
                        children: [
                          SizedBox(
                            width: anchoNombre,
                            // Dos renglones y no un helper que abrevie: con ~194 px la mayoría entra en uno
                            // y «CARVAJAL R.» no distingue a dos Carvajal. A 1.05 de interlineado dos
                            // renglones de bodySmall miden ~26 px y la fila mide 34: entra. La sucursal va
                            // al tooltip (la fila ya usa sus dos renglones), como en la matriz: el panorama
                            // es de escritorio, donde existe el hover.
                            child: Tooltip(
                              message: [
                                f.dependiente.nombreDependiente,
                                if (f.participante?.sucursal.isNotEmpty ??
                                    false)
                                  f.participante!.sucursal,
                              ].join('\n'),
                              child: Text(
                                f.dependiente.nombreDependiente,
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(height: 1.05),
                              ),
                            ),
                          ),
                          for (final s in columnas) _celdaDe(f, s),
                        ],
                      ),
                    const SizedBox(height: Esp.l),
                  ],
                ),
              ),
            ),
            // Sin párrafo al pie: el tooltip de cada celda bloqueada ya dice la fecha y el
            // motivo.
          ],
        );
      },
    );
  }

  /// Un cruce del panorama. Mismas reglas que la lista pero **por columna**: la
  /// misma persona puede ser tocable el 12 y no el 19 (vacaciones).
  Widget _celdaDe(_Fila f, SabadoEntity s) {
    final p = f.participante;
    final celda = p == null ? null : grilla.celda(p.idParticipante, s.idSabado);
    final bloqueo = _bloqueoDelCruce(
      grilla: grilla,
      participante: p,
      sabado: s,
      celda: celda,
      hoy: hoy,
    );

    return _CeldaPanorama(
      lado: _lado,
      celda: celda,
      bloqueo: bloqueo,
      fecha: fechaCorta(s.fecha),
      enColumnaActiva: s.idSabado == seleccionado,
      onTap: bloqueo != null ? null : () => onElegir(s, f.dependiente, celda),
    );
  }
}

class _CeldaPanorama extends StatelessWidget {
  const _CeldaPanorama({
    required this.lado,
    required this.celda,
    required this.bloqueo,
    required this.fecha,
    required this.enColumnaActiva,
    required this.onTap,
  });

  final double lado;
  final CeldaTurnoEntity? celda;

  /// Por qué esa celda no se puede tocar, o null. En 34 px no entra el motivo,
  /// así que va al tooltip: es lo único que explica por qué el tap no hace nada.
  final String? bloqueo;

  final String fecha;
  final bool enColumnaActiva;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // El cambio se suma al tooltip existente: aquí la celda es aún más chica que en
    // la matriz y el texto es el único lugar donde entra el nombre del otro.
    final cambio = celda?.hayCambio == true ? ' · ${celda!.cambioTexto}' : '';

    return Tooltip(
      message: '${bloqueo == null ? fecha : '$fecha · $bloqueo'}$cambio',
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: lado,
          height: lado,
          decoration: BoxDecoration(
            color: fondoDeCelda(context, celda),
            border: Border(
              right: BorderSide(
                color: enColumnaActiva ? cs.primary : cs.outlineVariant,
                width: enColumnaActiva ? 1.5 : .5,
              ),
              bottom: BorderSide(color: cs.outlineVariant, width: .5),
              left: BorderSide(
                color: enColumnaActiva ? cs.primary : Colors.transparent,
                width: enColumnaActiva ? 1.5 : 0,
              ),
            ),
          ),
          // Sin `alignment` en el Container: con él el Stack se encoge al
          // tamaño de la letra y la esquinita cae encima del glifo.
          child: Stack(
            children: [
              Center(child: LetraDeCelda(celda: celda)),
              if (celda?.esIntervencion == true)
                Positioned(
                  top: 0,
                  right: 0,
                  child: MarcaDeIntervencion(color: cs.primary),
                ),
              if (celda?.hayCambio == true)
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: MarcaDeCambio(color: cs.tertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
