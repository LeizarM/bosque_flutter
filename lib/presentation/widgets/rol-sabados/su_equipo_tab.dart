import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/mi_equipo_entity.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
// Sólo por `filtrarSabados`: es una función pura y ya la importan así la matriz,
// personal y cambios. Del provider de mes de la grilla acá no se depende.
import 'package:bosque_flutter/presentation/widgets/rol-sabados/filtros_grilla.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/su_equipo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// «Su equipo»: el sábado visto desde el lado del jefe.
///
/// **Es la misma grilla, pero con otra pregunta.** Las otras cuatro pestañas son
/// de RR.HH.: miran el año entero y buscan desequilibrios. Acá la pregunta es
/// una sola y se contesta el jueves a la tarde —«¿quién de los míos viene este
/// sábado?»— así que la vista arranca en el **próximo** sábado y no en enero, y
/// muestra a la gente que el organigrama le da a quien está mirando, no a las 87
/// personas del rol.
///
/// **Lo que esta pantalla no deja hacer, y por qué.** El jefe sólo pone '1' o
/// 'L'. Las vacaciones, las bajas, los feriados y los permisos los carga RR.HH.
/// desde el legajo, y una celda de esas se muestra bloqueada **con el motivo
/// escrito al lado**: sin eso, el jefe se enteraría del rechazo recién al
/// guardar y no sabría si el problema es él, la persona o el día.
///
/// El equipo se deriva del organigrama (`dbo.fn_trs_ProgramadorDependiente`), no
/// lo arma nadie a mano. Por eso puede llegar vacío, y por eso ese caso tiene su
/// propio mensaje en vez de una lista muda.
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
            data:
                (g) => _Vista(idRol: idRol, equipo: equipo, grilla: g),
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LA VISTA
// ═══════════════════════════════════════════════════════════════════════════

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
      // Sin condicional: esta pestaña la ve UN solo público —el jefe
      // programador— y es exactamente el que no tiene la varita. Mandarlo a un
      // botón que no está era dejarlo sin salida ni a quién recurrir.
      return const MensajeVacio(
        icono: Icons.event_busy,
        titulo: 'El rol no tiene sábados',
        detalle: 'Este rol se creó sin fechas. Avisa a RR.HH. para que lo '
            'regenere.',
      );
    }

    // El próximo sábado es el default; el elegido vive en el provider para que
    // sobreviva a un cambio de pestaña.
    final porDefecto = futuros.isNotEmpty ? futuros.first : g.sabados.last;
    final pedido = ref.watch(sabadoElegidoProvider);
    // Ojo: se resuelve contra `visibles` y NUNCA contra los del mes. Si el
    // universo de búsqueda fuera el mes ya filtrado, el filtro se mordería la
    // cola y no habría forma de salir de octubre.
    final sabado = visibles.firstWhere(
      (s) => s.idSabado == pedido,
      orElse: () => porDefecto,
    );

    // **El mes no es un estado: se deriva del sábado elegido.** Un provider
    // aparte admitiría «mes = octubre, sábado = 07/11», que es justo el choque
    // que el `orElse` de arriba tiene que tapar. Derivándolo no puede existir.
    // Si el sábado no tuviera fecha, mes 0 y `filtrarSabados` devuelve todo:
    // degrada a la tira larga de antes en vez de romper.
    final mes = sabado.fecha?.month ?? 0;
    final delMes = filtrarSabados(visibles, mes);

    final filas = _armarFilas(sabado, hoy);
    final cuenta = _Cuenta.de(g, sabado, filas);

    // A dónde llevan las flechas de la barra. Se navega sobre `visibles` y
    // NUNCA sobre los del mes: plegada, la barra es la única forma de moverse,
    // y si sólo caminara el mes desde el 29/08 no habría manera de llegar al
    // 05/09 sin desplegar. Cruzar de mes sale gratis porque el mes es derivado
    // del sábado (arriba): mover el sábado mueve el mes solo.
    final i = visibles.indexOf(sabado);
    final anterior = i > 0 ? visibles[i - 1] : null;
    final siguiente =
        i >= 0 && i < visibles.length - 1 ? visibles[i + 1] : null;

    void elegir(int idSabado) =>
        ref.read(sabadoElegidoProvider.notifier).state = idSabado;

    // Se lee acá y no adentro del LayoutBuilder porque `ref.watch` va en el
    // build; el ancho se le aplica después.
    final plegadoElegido = ref.watch(cabeceraEquipoPlegadaProvider);

    return LayoutBuilder(
      builder: (context, cajon) {
        // El ancho REAL del panel y no el de la pantalla: adentro del dashboard
        // hay un sidebar que se lleva su parte. Lo usan las tres decisiones de
        // acá —panorama, default del plegado y forma del rótulo— y las tres
        // quieren lo mismo: cuánto lugar hay de verdad.
        final aire = Aire.de(cajon.maxWidth);

        // **El teléfono arranca plegado; tablet y escritorio, desplegados.**
        //
        // Medido en un 360×740 real: a la pestaña le quedan 475 px y la
        // cabecera desplegada se lleva 433 —la barra, la identidad, las dos
        // tiras de fichas y el resumen—. Sobran 42: media fila. Se entra a la
        // pantalla de «quién viene el sábado» sin ver a nadie, y una lista
        // cortada a la primera fila se lee como «esto está roto», no como «hay
        // más abajo» (es el mismo modo de falla que ya se arregló una vez acá,
        // ver `isThreeLine`). Plegada la cabecera son ~72 px —~96 si el rol
        // viene corto— y entran cinco personas. Creció un renglón cuando las
        // cifras pasaron a decir de qué universo hablan; sigue costando menos de
        // una fila y media. Medida en el banco de pruebas, cuya letra es bastante
        // más ancha, el peor caso da 125 px: cuatro personas y media, todavía
        // lejos de la lista cortada a una fila.
        //
        // Y lo que se esconde es NAVEGACIÓN, que se usa DESPUÉS de leer la
        // respuesta y no antes: se entra parado en el próximo sábado, que es el
        // que el 90% de las veces se venía a mirar.
        //
        // En pantalla ancha los dos Wrap colapsan a un renglón cada uno y al
        // lado está el panorama, que es una tabla del MES: esconder los chips
        // de mes ahí sería cobrar taps a cambio de aire que sobra.
        final plegada = plegadoElegido ?? aire.esChico;

        final vista = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // La barra queda ARRIBA de lo que pliega, y no es negociable: si el
            // asa estuviera abajo del panel, al plegar se correría ~370 px
            // hacia arriba y se iría de abajo del dedo en el mismo gesto.
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
            // Este divisor es nuevo y separa lo que se queda de lo que se va:
            // arriba la barra, que está clavada; abajo todo lo que scrollea.
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                // Cambiar de sábado es cambiar de pregunta, así que la
                // respuesta empieza arriba: la key rehace la lista y descarta
                // el offset. Con 14 filas no se nota. Plegar y desplegar NO la
                // toca: el scroll se pierde sólo al cambiar de sábado, que es
                // cuando corresponde.
                key: ValueKey(sabado.idSabado),
                padding: const EdgeInsets.only(top: Esp.xs, bottom: Esp.xxl),
                // La cabecera plegable es el primer ítem de la lista, no un
                // hermano de alto fijo arriba de ella.
                //
                // **Por qué, con números.** En 360×740 el panel disponible mide
                // 475 px y la cabecera desplegada pide 433: con la letra del
                // tema entra raspando y le deja media fila a la lista, y con la
                // letra al 130% —o con la del banco de pruebas, que es más
                // ancha— pide 532 y desborda. Como hermana de un `Expanded`, lo
                // que no entra no se puede alcanzar de ninguna manera: la
                // lista se achica hasta cero y recién ahí aparece la franja
                // amarilla. Adentro del scroll no hay alto que respetar y el
                // problema no puede existir a ningún ancho ni con ninguna
                // tipografía. De paso, desplegada la cabecera se va scrolleando
                // en vez de quedar pegada comiéndose la pantalla — que es la
                // queja de la que salió todo esto.
                itemCount: filas.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    // Son ~370 px que aparecen y desaparecen: sin transición la
                    // lista pega un salto y no se entiende de dónde salió. El
                    // ClipRect no es adorno: `RenderAnimatedSize` no recorta a
                    // su hijo, así que en los fotogramas del medio la Column
                    // desborda y salta la franja amarilla.
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
                                    // Sin divisores entre identidad, tira y
                                    // resumen: son tres partes de la misma
                                    // cabecera y se leen juntas. El de abajo
                                    // separa la cabecera de la gente, que sí
                                    // son dos cosas distintas.
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
                    // El bloqueo se decide acá y se baja como onTap nulo: el
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

  // ── el cruce ──────────────────────────────────────────────────────────

  /// Mi gente, cruzada contra el rol para un sábado.
  ///
  /// El organigrama y el rol son dos listas distintas: alguien puede depender de
  /// mí y no estar en el rol de este año —entró en marzo, o se dio de baja—. Ese
  /// desfase no es un error, es información, así que la persona aparece igual
  /// pero bloqueada y con el motivo.
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
/// **El orden importa: gana el motivo más de fondo.** Que el rol esté cerrado
/// explica mejor que «está de vacaciones», porque con el rol cerrado tampoco se
/// podría tocar aunque la persona estuviera disponible.
///
/// Vive suelta porque la usan las dos vistas —la lista y el panorama— y son
/// exactamente las mismas reglas que aplica `trs_sp_programar` del otro lado.
/// Si acá dijeran algo distinto, el jefe se enteraría del rechazo al guardar.
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

  // Ojo con la 'P': acá es el CÓDIGO de la celda —un permiso de RR.HH.— y no el
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
/// **Por qué no lo cuenta cada uno por su lado.** Los mismos números los
/// muestran la barra —que no se puede ocultar— y el resumen —que sí—. Si cada
/// uno hiciera su propio bucle, el día que alguien cambie la regla de «quien no
/// está en el rol no es libre» los dos dirían cosas distintas del mismo sábado.
/// Es la misma razón por la que [_bloqueoDelCruce] vive suelta y la usan la
/// lista y el panorama.
///
/// Es una pasada sobre ≤20 filas, así que se hace en el build de la vista y se
/// baja hecha a los dos.
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

  factory _Cuenta.de(
    GrillaRol grilla,
    SabadoEntity sabado,
    List<_Fila> filas,
  ) {
    var vienen = 0;
    var libres = 0;
    var vacaciones = 0;
    var mias = 0;
    var otros = 0;
    for (final f in filas) {
      // Quien no está en el rol no es «libre»: es que no figura. Contarlo como
      // libre haría creer que hay gente disponible que en realidad no existe
      // para este año.
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

// ═══════════════════════════════════════════════════════════════════════════
// LA BARRA DEL SÁBADO
// ═══════════════════════════════════════════════════════════════════════════

/// De qué sábado es la lista, y el asa que abre y cierra el resto.
///
/// **Es lo único que sobrevive al plegado, y de ahí sale todo lo que lleva.**
/// Sin la fecha arriba, los «Trabaja / Libre» de abajo son un estado sin día y
/// la pantalla pasa a mentir: el sábado elegido sobrevive a un cambio de
/// pestaña, así que quien se fue mirando diciembre vuelve a diciembre.
///
/// **Por qué la fecha lleva el mes escrito** (`01 ago`) y no sólo el número
/// como los chips: las flechas cruzan el límite de mes sin avisar, y del 29/08
/// al 05/09 este rótulo es el único lugar donde se ve que cambiaste de mes. Las
/// tres letras salen de [mesCorto], las mismas que dice el chip que reemplaza.
///
/// **Por qué `vienen X de Y` también.** Es la respuesta a la pregunta de la
/// pestaña. Sin eso, la barra dice de qué día es la lista pero no cómo quedó, y
/// habría que desplegar para saber si terminaste.
///
/// **Cada cifra dice de qué universo habla, y por eso ninguna vive adentro del
/// botón.** Acá conviven dos números de dos poblaciones distintas —las 14
/// personas que programás y las 87 del rol entero— y antes se leían de corrido:
/// «vienen 7 de 14 · falta 1». Ese «falta 1» es el faltante de cobertura de TODO
/// el rol, pero pegado al renglón anterior se lee «falta 1 de los tuyos», que es
/// falso y termina con un jefe mandando a trabajar a alguien que no hacía falta.
/// Ahora cada una arranca con su población escrita —`tu equipo:` / `todo el
/// rol:`— y son piezas sueltas del [Wrap], así que **cada una baja de renglón
/// entera** en vez de cortarse con puntos suspensivos a mitad de frase, que es
/// lo que hacía el `maxLines: 1` cuando la cuenta viajaba adentro del botón. En
/// 360 px eso cuesta un renglón, y un renglón es más barato que una cifra que se
/// puede leer de dos maneras.
///
/// El botón se queda sólo con la fecha, que además es lo único que el botón
/// cambia: lo que tocás y lo que leés dejaron de estar mezclados.
///
/// **El asa es el rótulo, no un chevron suelto al costado.** Fue el desacuerdo
/// entre las dos propuestas: una quería un `IconButton` con tooltip (invisible
/// en un teléfono, que es justo donde el plegado es el default) y la otra un
/// botón que dijera «Cambiar de sábado» con todas las letras (~140 px, que en
/// 360 no conviven con las flechas). Poner el chevron pegado a la fecha resuelve
/// las dos cosas: es el gesto universal de «acá se elige una fecha», cuesta
/// 18 px y ata el control al dato que cambia. No es «el asa entera es tappable»
/// —eso sería un párrafo de datos que despliega 336 px bajo el dedo—: es un
/// botón de un renglón, con su ripple y su tooltip.
///
/// Lo demás aparece **sólo plegada**, y esa es la regla: la barra muestra lo que
/// el panel se llevó. Desplegada, cada una de esas cosas está escrita completa
/// tres renglones más abajo y repetirla sería ruido.
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
      // Esp.xs y no Esp.l: el glifo del chevron ya viene con su propio aire
      // adentro del objetivo táctil de 48 px, así que cae en la misma columna
      // que los textos de la identidad y del resumen.
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
          // Wrap y no Row: en 360 px al medio le quedan ~208-256 px y ni la
          // cuenta del equipo ni el aviso del rol entran al lado del rótulo.
          // Bajan de renglón —la barra pasa de 48 a ~72, y a ~96 con el aviso—
          // en vez de cortarse con puntos suspensivos, que es lo que haría una
          // Row. Media frase con «…» al final es justo el modo de falla que
          // vuelve ambigua a la cifra.
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
                      // El rótulo es el título de la pantalla: si tomara el
                      // color del botón se leería como un estado, y acá el
                      // color codifica estado y nada más.
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
                // La respuesta a la pregunta de la pestaña, con la población
                // adelante: `de 14` es «de las 14 personas que programás», y
                // ese 14 se verifica de un vistazo contra las filas de abajo y
                // contra la identidad. El rótulo va apagado y el dato en peso de
                // título: el que se compara es el número, la palabra sólo dice
                // de quién es.
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
                // La cobertura del día es lo único que le avisa a un jefe que
                // el sábado se está quedando corto, así que la ALARMA no puede
                // depender de que alguien despliegue. El detalle —cuántos
                // vienen, cuál es el objetivo— sí: se lee abriendo. Y cuando el
                // día está cubierto no se escribe nada, que es la misma regla
                // del resumen —los ceros y los no-eventos no ocupan lugar—.
                //
                // Va con `todo el rol:` delante y con la palabra «persona»
                // atrás: sin la población es el faltante de nadie, y sin el
                // sustantivo un «falta 1» suelto al lado de «vienen 7 de 14» se
                // lee como que falta uno DE LOS TUYOS. Se pinta el faltante y no
                // el rótulo, igual que en el resumen: el color codifica el
                // estado, y el estado es la falta, no de quién es.
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
                // Lo único de la identidad que no se puede esconder: no
                // contesta «por qué veo a esta gente» una vez por sesión, sino
                // que cambia el significado de CADA fila — estás moviendo gente
                // que no es tuya.
                if (plegada && reemplazo != null)
                  Etiqueta(
                    texto: 'reemplazo de $reemplazo',
                    tono: TonoEtiqueta.aviso,
                  ),
                // Con el switch de «ver los que ya pasaron» escondido, alguien
                // parado en un sábado viejo vería las filas bloqueadas sin
                // ninguna pista de por qué.
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
          // «Este sábado» no se sube a la barra: vive en la tira, al lado de los
          // chips que gobierna. Lo que sube es su versión de emergencia, y sólo
          // plegada y sólo cuando hace falta — sin esto, quien se fue mirando
          // diciembre vuelve, entra plegado, y la única salida de diciembre está
          // escondida. Moverse uno o dos sábados, que es el caso real, ya lo
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

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA DE IDENTIDAD
// ═══════════════════════════════════════════════════════════════════════════

/// Dos renglones que contestan «¿por qué veo a esta gente?».
///
/// El segundo renglón es para el reemplazo: sin él, quien entra a cubrir a su
/// jefe ve una lista de veinte personas que no son suyas y no entiende nada.
class _Identidad extends StatelessWidget {
  const _Identidad({required this.equipo, required this.personas});

  final MiEquipoEntity equipo;
  final int personas;

  @override
  Widget build(BuildContext context) {
    // «todo TU árbol» y no «todo el árbol»: dos renglones más abajo el resumen
    // dice «todo el rol», que es la otra población de la pantalla. Sin el
    // posesivo, las dos frases largas se parecen lo suficiente como para que
    // «alcance todo el árbol» se lea como «ves el rol entero».
    // La sucursal se nombra porque el filtro corre igual para DIRECTOS y para
    // SUBARBOL, y sin decirlo «todo tu árbol» se lee como si cruzara
    // sucursales. Pero se dice lo que el permiso ES: con `codSucursal` en 0 la
    // fila está guardada sin sucursal y sí las cruza. Dar por sentado que
    // siempre limita fue justo el error que dejó a un jefe sin ver a su
    // responsable de producción, que le cuelga directo desde otra planta.
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
          // «Podés decidir quién viene y quién no» se cayó: lo dice la propia
          // hoja con sus dos botones. Lo que queda es lo que evita el ticket a
          // soporte —por qué hay celdas que no se dejan tocar—, y en 360 px son
          // dos renglones en vez de tres arriba de todo.
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

// ═══════════════════════════════════════════════════════════════════════════
// LA TIRA DE SÁBADOS
// ═══════════════════════════════════════════════════════════════════════════

/// Dos niveles de fichas: el mes arriba, los sábados de ese mes abajo.
///
/// **Por qué dos filas y no una tira de cuarenta.** Un rol entero son ~52
/// sábados: llegar a diciembre eran tres o cuatro arrastres y, peor, en el medio
/// del arrastre no se sabía en qué mes se estaba parado. Con el mes escrito
/// arriba, la tira de abajo nunca pasa de cinco fichas y el día alcanza para
/// identificarlas.
///
/// Chips y no un combo como el de la grilla: cambiar de mes cuesta un tap en vez
/// de dos, y el mes queda **a la vista** sin abrir nada — que era la mitad del
/// problema.
///
/// Que las dos filas se parezcan no confunde porque el contenido las separa:
/// arriba tres letras, abajo un número grande. Y que la selección de abajo sea
/// un subconjunto de la de arriba es exactamente el modelo mental: mes → sábado.
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

  /// El universo del que salen los chips de mes. Sale de `visibles` y no de
  /// `g.sabados` a propósito: así el switch de «ver los que ya pasaron» gobierna
  /// los dos niveles con una sola palanca — apagado no hay meses viejos que
  /// tocar, encendido aparecen solos.
  final List<SabadoEntity> visibles;

  final int mes;
  final int seleccionado;

  /// El próximo sábado. `sabadoElegidoProvider` no es autoDispose a propósito,
  /// así que quien ayer se fue mirando diciembre hoy entra en diciembre: este es
  /// el botón que lo trae de vuelta en un tap.
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
          // Wrap y no Row: en 360 px quedan 328 útiles y un rol de año entero
          // son 12 chips de ~52 px, que bajan a dos renglones. Es el peor caso y
          // sigue siendo mucho menos que 52 chips de sábado.
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
          // Sin alto fijo: el chip de Material reserva su propio objetivo táctil
          // de 48 px y una caja más chica lo desborda.
          //
          // Wrap y no scroll horizontal: en 360 px, 5 chips de ~44 px más la
          // separación son ~260 px sobre 328 útiles. Entran siempre.
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
                // Flexible y no un Text suelto: el switch se lleva 60 px de los
                // 328 útiles en 360 px y el rótulo mide ~140 con la letra del
                // tema, pero al 130% se pasa de largo y la Row lo cortaba. Que
                // baje de renglón; el switch no se mueve.
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
            // El día solo: el mes ya está escrito en la fila de arriba, así que
            // repetirlo en cada ficha era ruido. Queda igual que la cabecera del
            // panorama y que la matriz. La fecha completa sigue en el tooltip.
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

// ═══════════════════════════════════════════════════════════════════════════
// EL RESUMEN DEL DÍA
// ═══════════════════════════════════════════════════════════════════════════

/// Cómo quedó mi equipo ese sábado, y cómo quedó el día en total.
///
/// **La cobertura del rol va acá y no en la pestaña de RR.HH.** El dato ya está
/// en memoria, y es el único que le avisa a un jefe que el sábado se está
/// quedando corto. Sin él, treinta jefes liberan a dos personas cada uno y nadie
/// se entera hasta el sábado a la mañana.
///
/// **Su primer renglón se mudó a la barra**, que es la que no se puede ocultar.
/// «Sábado 01/08/2026 · tu equipo: vienen 7 de 14» era la respuesta a la
/// pregunta de la pantalla y estaba primero y en peso de título; ahora sigue
/// estando primero y además ya no se puede esconder. Si se hubiera quedado
/// también acá, al desplegar aparecería dos veces con tres renglones de
/// distancia.
///
/// **Son dos renglones y cada uno arranca nombrando su población.** Antes el
/// primero empezaba en «7 libres» —sin decir de quién— y el segundo hablaba del
/// rol entero: dos poblaciones distintas, una sola con rótulo. Leídos de corrido
/// los libres parecían del rol o el faltante parecía del equipo, según por dónde
/// se entrara. `Tu equipo:` y `Todo el rol ese sábado:` cuestan doce caracteres
/// y sacan la duda.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.cuenta});

  final _Cuenta cuenta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Los ceros no se escriben: un «0 de vacaciones» ocupa el mismo lugar que un
    // dato y hay que leerlo para descartarlo. `libres` va siempre porque es la
    // otra mitad de la respuesta y su cero sí dice algo (vienen todos).
    final partes = [
      '${cuenta.libres} libres',
      if (cuenta.vacaciones > 0) '${cuenta.vacaciones} de vacaciones',
      // Las otras letras —cubierto, excusado, feriado, baja— existen pero son
      // pocas. Se agrupan para que la cuenta cierre con el total y no queden
      // personas sin figurar en ningún lado.
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
          // Todas estas cifras son de las personas que programás. El rótulo lo
          // dice de entrada porque el renglón de abajo habla de otra población y
          // los dos se leen juntos.
          Text('Tu equipo: ${partes.join(' · ')}', style: context.apagado()),
          const SizedBox(height: Esp.xs),
          // **Se pinta el número, no la frase.** El predicado es el del módulo
          // entero (matriz y hoja de decisión) y no se toca; lo que estaba mal
          // era la superficie: la matriz pinta una cifra dentro de 42 px y acá
          // se pintaba un renglón a todo el ancho. Mismo dato, diez veces más
          // rojo, y «42 de 43» parecía una alarma.
          //
          // **Por qué `vienen 42 · objetivo 43` y no `42 de 43`.** El renglón de
          // arriba usa el molde `vienen 7 de 14`, donde el segundo número es
          // CUÁNTOS SON. Acá el segundo número es CUÁNTOS HACEN FALTA —el rol
          // tiene 87 personas, no 43—, así que el mismo molde para dos
          // significados distintos hacía leer «vienen 42 de las 43 que hay».
          // Cada cifra rotulada aparte no se puede confundir.
          //
          // El «Todo el rol» evita que un jefe de 14 personas lea ese número
          // como un déficit suyo, que casi nunca lo es; el «ese sábado» evita
          // que lo lea como un acumulado del año; la resta escrita evita hacerla
          // de memoria.
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

// ═══════════════════════════════════════════════════════════════════════════
// LA LISTA DE MI GENTE
// ═══════════════════════════════════════════════════════════════════════════

/// Una persona del equipo en el sábado elegido.
///
/// La letra y la esquinita son las mismas de la matriz y de la agenda: si la
/// señal cambiara de forma entre las vistas habría que aprenderla tres veces.
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

    // **Sale del participante cruzado, NO de `d.sucDependiente`.** El
    // organigrama trae el CÓDIGO de la sucursal, no el nombre, y encima es el
    // del organigrama y no el del rol. La sucursal con nombre viene del listado
    // de participantes, que es contra lo que ya se cruza toda esta fila. Si la
    // persona no está en el rol de este año —el cruce da null— no hay sucursal
    // que mostrar y no se dibuja nada: esa fila ya explica su situación con la
    // etiqueta de bloqueo.
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
            // La misma esquina que en la matriz y en la agenda. Acá importa
            // especialmente: el jefe que aprueba un cambio desde «Cambios» es
            // el mismo que después mira este tab, y sin la marca la celda le
            // cuenta la mitad de lo que él mismo decidió.
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
      // La condición es literalmente «¿el Wrap de abajo va a tener más de un
      // elemento?». En el caso normal tiene uno solo —«Trabaja»— y reservar
      // alto de tres líneas costaba 88 px por persona donde alcanzan 64: con 14
      // personas son ~340 px de scroll regalado, y la lista se cortaba a la
      // séptima fila, que se lee como un error y no como «hay más abajo».
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
            // **Dónde está esa persona.** Con alcance SUBARBOL el equipo cruza
            // sucursales —a un gerente le cuelga gente de CENTRAL y de SANTA
            // CRUZ— y esto es lo único de la fila que lo dice. Sin eso, un jefe
            // le pone un sábado a alguien que está a 900 km del galpón que
            // quería cubrir.
            //
            // **Va última y en `Dato`, no en `Etiqueta`.** La sucursal es
            // contexto, no estado: las pastillas de acá al lado codifican por
            // qué la fila no se toca, y una pastilla más las diluiría. Última
            // porque en 360 px el Wrap se parte en dos renglones cuando la
            // observación es larga, y lo que tiene que bajar es el dato menos
            // urgente y no el motivo del bloqueo.
            //
            // **Sin el cargo, a diferencia de «Grupos» y de la agenda.** Un
            // jefe conoce por nombre a sus ≤20 y sabe qué hace cada uno; lo que
            // no ve es dónde están. Este es además el Wrap más apretado del
            // módulo y cada pieza que se agregue compite con las etiquetas, que
            // son las que evitan el ticket a soporte.
            if (sucursal.isNotEmpty) Dato(sucursal),
          ],
        ),
      ),
      // Lápiz y no chevron: el chevron es el gesto Material de «te llevo a otra
      // pantalla», y lo que se abre es una hoja de dos botones. Sin icono sigue
      // significando «no se toca», que ya funcionaba.
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
  /// El cambio va antes que la observación: la observación es el motivo que
  /// `trs_sp_corregirCelda` le copió al aprobar, así que si algo se corta al
  /// final es lo que ya se dedujo, no el dato que faltaba.
  String _estado() {
    final c = fila.celda;
    if (c == null) return 'Libre';
    final nombre = grilla.estados[c.codigoExcel]?.nombre ?? c.codigoExcel;
    return '$nombre'
        '${c.hayCambio ? ' · ${c.cambioTexto}' : ''}'
        '${c.observacion.isEmpty ? '' : ' · ${c.observacion}'}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EL PANORAMA
// ═══════════════════════════════════════════════════════════════════════════

/// Mi gente × los sábados del mes, en pantalla ancha.
///
/// **Qué agrega sobre la vista por sábado.** La lista contesta «quién viene el
/// 12»; el panorama contesta «a quién le estoy cargando cuatro sábados
/// seguidos», que es la pregunta que aparece recién cuando uno ve el mes.
///
/// **Antes eran ocho columnas —dos meses— con una ventana deslizante.** Ocho ×
/// 34 px sobre un panel de 380 dejaban 92 px para el nombre: «CARVAJAL RO…», que
/// no distingue a un Carvajal de otro. Con el mes son cuatro o cinco columnas y
/// quedan ~194 px, o sea el nombre entero en uno o dos renglones. Se pierde ver
/// una racha que cruza el fin de mes; se recupera con un tap en el mes de al
/// lado, y leer de quién es la fila vale más.
///
/// Sin `ScrollController` atados: son veinte filas como mucho y cinco columnas.
/// Lo único que puede no entrar es el alto, y para eso alcanza con un scroll
/// vertical suelto.
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
  final void Function(SabadoEntity, ProgramadorDependienteEntity, CeldaTurnoEntity?)
  onElegir;

  static const double _lado = 34;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cajon) {
        // Lo que sobra después de las columnas del mes es la columna de
        // nombres: con cinco sábados en 380 px quedan ~194, que alcanzan para
        // el nombre entero en uno o dos renglones.
        final sobrante =
            cajon.maxWidth - Esp.s * 2 - columnas.length * _lado;
        final anchoNombre = sobrante < 72 ? 72.0 : sobrante;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.s, Esp.m, Esp.s, Esp.s),
              // El mes va acá y no repetido debajo de cada uno de los cinco
              // números: todas las columnas son del mismo mes desde que la
              // tabla es mensual. Mes 0 es el sábado sin fecha —la tabla vuelve
              // a mostrarlos todos— y ahí el título viejo sigue siendo el
              // correcto.
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
                            // Dos renglones y no un helper que abrevie: con
                            // ~194 px la mayoría entra en uno, y «CARVAJAL R.»
                            // seguiría sin distinguir a dos Carvajal con la
                            // misma inicial. A 1.05 de interlineado, dos
                            // renglones de bodySmall miden ~26 px y la fila ya
                            // mide 34: entra sin mover nada.
                            // La sucursal va al tooltip y no debajo del
                            // nombre: la fila mide 34 px y el nombre ya usa sus
                            // dos renglones. Es la misma respuesta que da la
                            // matriz, y por la misma razón —el panorama es de
                            // escritorio, donde el hover existe—.
                            child: Tooltip(
                              message: [
                                f.dependiente.nombreDependiente,
                                if (f.participante?.sucursal.isNotEmpty ?? false)
                                  f.participante!.sucursal,
                              ].join('\n'),
                              child: Text(
                                f.dependiente.nombreDependiente,
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(height: 1.05),
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
            // Sin párrafo al pie: era un tutorial permanente y su contenido ya
            // está donde se lo busca — el tooltip de cada celda bloqueada dice
            // la fecha y el motivo.
          ],
        );
      },
    );
  }

  /// Un cruce del panorama.
  ///
  /// Las reglas son las mismas que en la lista, pero se evalúan **por columna**:
  /// la misma persona puede ser tocable el 12 y no el 19 porque ese otro sábado
  /// está de vacaciones.
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

    // El cambio se suma al tooltip que ya existía en vez de pedir uno nuevo:
    // acá la celda es todavía más chica que en la matriz y el texto es el único
    // lugar donde entra el nombre del otro.
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
