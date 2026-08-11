import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/rol_sabados_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El combo que elige qué rol se está mirando, con su resumen al lado.
///
/// Vive arriba de las cuatro pestañas y no dentro de una: todas hablan del mismo
/// rol, y tenerlo repetido sería cuatro lugares donde desincronizarse.
class SelectorDeRol extends ConsumerWidget {
  const SelectorDeRol({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(rolesSabadosProvider);
    final seleccionado = ref.watch(rolSeleccionadoProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.m),
      child: roles.when(
        loading:
            () => const SizedBox(
              height: 48,
              child: Center(child: LinearProgressIndicator()),
            ),
        error:
            (e, _) => Text(
              'No se pudieron cargar los roles: ${textoParaUsuario(e)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        data: (lista) {
          if (lista.isEmpty) {
            // Esto se va a leer entero cada 1 de enero, hasta que alguien cree
            // el rol del año. Señalar «arriba a la derecha» a quien no tiene la
            // varita es mandarlo a mirar un lugar vacío.
            return Text(
              ref.watch(administraRolProvider)
                  ? 'Todavía no hay ningún rol generado. Crea uno con la varita '
                      'de arriba a la derecha.'
                  : 'Todavía no hay ningún rol generado. RR.HH. tiene que crear '
                      'el del año.',
              style: Theme.of(context).textTheme.bodySmall,
            );
          }

          final rol = lista.firstWhere(
            (r) => r.idRol == seleccionado,
            orElse: () => lista.first,
          );

          final combo = DropdownButtonFormField<int>(
            value:
                lista.any((r) => r.idRol == seleccionado) ? seleccionado : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Rol',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            hint: const Text('Elige un rol'),
            items: [
              for (final r in lista)
                DropdownMenuItem(
                  value: r.idRol,
                  child: Text(
                    r.sucursal.isEmpty
                        ? r.nombre
                        : '${r.nombre} · ${r.sucursal}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged:
                (v) => ref.read(rolSeleccionadoProvider.notifier).state = v,
          );

          // En pantalla chica el combo de 260 px más los chips no entran en una
          // fila: 260 + 32 de padding ya son 292 de los 360 que hay.
          if (Aire.de(MediaQuery.sizeOf(context).width).esChico) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                combo,
                if (seleccionado != null) ...[
                  const SizedBox(height: Esp.s),
                  ResumenDelRol(rol: rol, apilado: true),
                ],
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 260, child: combo),
              const SizedBox(width: Esp.l),
              if (seleccionado != null) ResumenDelRol(rol: rol),
            ],
          );
        },
      ),
    );
  }
}

/// Estado del rol y sus números: personas, sábados, celdas y metas.
class ResumenDelRol extends StatelessWidget {
  const ResumenDelRol({super.key, required this.rol, this.apilado = false});

  final RolSabadosEntity rol;

  /// Apilado bajo el combo: no hay una Row de la que ocupar el resto, así que
  /// el `Expanded` sobra — y adentro de una Column tira excepción.
  final bool apilado;

  @override
  Widget build(BuildContext context) {
    final contenido = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        EstadoDelRol(rol: rol),
        AlcanceDelRol(idRol: rol.idRol),
        Dato('${rol.participantes} personas'),
        Dato('${rol.sabados} sábados'),
        Dato('${rol.celdas} celdas'),
        Dato('meta A ${rol.turnosObjetivoA} · B ${rol.turnosObjetivoB}'),
      ],
    );

    return apilado ? contenido : Expanded(child: contenido);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EL ALCANCE: QUÉ EMPRESA Y CUÁNTAS SUCURSALES HAY ADENTRO
// ═══════════════════════════════════════════════════════════════════════════

/// Empresa y sucursales que el rol abarca de verdad, contadas sobre su gente.
///
/// **No sale del rol, y no es un atajo.** `trs_Rol.codEmpresa` y `codSucursal`
/// vienen en NULL porque el rol se genera global: preguntarle al rol por su
/// alcance devolvería vacío siempre. El alcance existe una sola vez, repartido
/// en los participantes, así que se cuenta desde ahí.
///
/// Se lee de `grillaRolProvider`, que es el mismo que ya está cargando la
/// pantalla: no agrega ningún viaje de red. Mientras no haya participantes no
/// dibuja nada — ni un cero ni un esqueleto. Un «0 sucursales» de medio segundo
/// se lee como un dato, y es el más alarmante que este chip puede dar.
class AlcanceDelRol extends ConsumerWidget {
  const AlcanceDelRol({super.key, required this.idRol});

  final int idRol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gente = ref.watch(grillaRolProvider(idRol)).valueOrNull?.participantes;
    if (gente == null || gente.isEmpty) return const SizedBox.shrink();

    final alcance = Alcance.de(gente);
    if (alcance.resumen.isEmpty) return const SizedBox.shrink();

    return Tooltip(
      message: 'Ver el desglose por sucursal',
      child: InkWell(
        onTap: () => _verDesglose(context, alcance),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.xs),
          // Text.rich y no un Row: adentro de un Wrap, un Text envuelve solo
          // cuando no entra, y un Row se pasa del borde. En 360 px apilado el
          // chip queda con ~328 px y «GENERAL · SANTA CRUZ PLANTA INDUSTRIAL»
          // no entra en una línea — así cae a dos, entero, sin recortar el
          // nombre de la sucursal.
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: alcance.resumen),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Icons.expand_more,
                    size: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
            style: context.apagado(),
          ),
        ),
      ),
    );
  }

  Future<void> _verDesglose(BuildContext context, Alcance a) => showDialog<void>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Alcance del rol'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (a.empresas.length == 1)
                  Text(
                    'Empresa ${a.empresas.first}',
                    style: ctx.tituloSeccion(),
                  )
                else if (a.empresas.length > 1)
                  // La anomalía que alguien querría ver: el rol es global, así
                  // que puede juntar sucursales de empresas distintas sin que
                  // nada lo avise. Acá se avisa.
                  Text(
                    'Este rol junta ${a.empresas.length} empresas.',
                    style: ctx.tituloSeccion()?.copyWith(color: ctx.cs.error),
                  ),
                const SizedBox(height: Esp.m),
                for (final s in a.porSucursal)
                  _FilaDeAlcance(
                    titulo: s.key,
                    cantidad: s.value,
                    // La empresa sólo se repite por sucursal cuando hay más de
                    // una: si es una sola, ya se nombró arriba.
                    detalle:
                        a.empresas.length > 1 ? a.empresaDe[s.key] ?? '' : '',
                  ),
                if (a.sinSucursal > 0) ...[
                  const Divider(height: Esp.xl),
                  _FilaDeAlcance(
                    titulo: 'Sin sucursal',
                    cantidad: a.sinSucursal,
                    detalle:
                        'El feriado se resuelve por sucursal: a esta gente no '
                        'le aplica ninguno.',
                    esProblema: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
  );
}

/// Una sucursal del desglose, con su cuenta a la derecha.
class _FilaDeAlcance extends StatelessWidget {
  const _FilaDeAlcance({
    required this.titulo,
    required this.cantidad,
    this.detalle = '',
    this.esProblema = false,
  });

  final String titulo;
  final int cantidad;
  final String detalle;

  /// Pinta el número con el rol de error. Es lo único con color acá: la
  /// sucursal es contexto, pero «nadie le puso sucursal» sí es un estado.
  final bool esProblema;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.s),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // El nombre va en Expanded: en 360 px el diálogo deja ~280 px de
        // contenido y «SANTA CRUZ PLANTA INDUSTRIAL» no entra al lado del
        // número. Así envuelve en vez de empujar la cuenta fuera del borde.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(titulo)),
            const SizedBox(width: Esp.m),
            Text(
              '$cantidad',
              style: context.numero(
                fuerte: true,
                color: esProblema ? context.cs.error : null,
              ),
            ),
          ],
        ),
        if (detalle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Esp.xs),
            child: Text(detalle, style: context.apagado()),
          ),
      ],
    ),
  );
}

/// Cuánta gente hay por sucursal y de qué empresas, ya ordenado y contado.
///
/// Es una clase y no tres variables sueltas porque las tres respuestas —qué
/// empresa, cuántas sucursales, cuántos quedaron afuera— salen de la misma
/// pasada y tienen que contar lo mismo. Separadas, tarde o temprano una suma 85
/// y otra 84.
class Alcance {
  /// Sucursales de mayor a menor. A igual cantidad, alfabético: sin desempate
  /// la lista se reordenaría sola entre dos cargas y parecería que cambió algo.
  final List<MapEntry<String, int>> porSucursal;

  /// A qué empresa pertenece cada sucursal.
  final Map<String, String> empresaDe;

  /// Las empresas distintas que aparecen. Más de una es una anomalía visible.
  final Set<String> empresas;

  /// Gente que llegó con la sucursal vacía. **Se cuenta aparte y se dice.**
  /// Mezclarla con el resto escondería a quien no tiene ningún feriado.
  final int sinSucursal;

  const Alcance({
    required this.porSucursal,
    required this.empresaDe,
    required this.empresas,
    required this.sinSucursal,
  });

  factory Alcance.de(List<ParticipanteTurnoEntity> gente) {
    final conteo = <String, int>{};
    final empresaDe = <String, String>{};
    var sinSucursal = 0;

    for (final p in gente) {
      if (p.sucursal.isEmpty) {
        sinSucursal++;
        continue;
      }
      conteo[p.sucursal] = (conteo[p.sucursal] ?? 0) + 1;
      if (p.empresa.isNotEmpty) empresaDe[p.sucursal] = p.empresa;
    }

    final orden =
        conteo.entries.toList()..sort(
          (a, b) =>
              a.value == b.value
                  ? a.key.compareTo(b.key)
                  : b.value.compareTo(a.value),
        );

    return Alcance(
      porSucursal: orden,
      empresaDe: empresaDe,
      empresas: empresaDe.values.toSet(),
      sinSucursal: sinSucursal,
    );
  }

  /// La línea del encabezado. Vacía = no hay nada que decir, y ahí no se dibuja.
  ///
  /// Con UNA sucursal se dice su nombre y no «1 sucursal»: el número no informa
  /// nada que el nombre no diga mejor, y de paso deja claro cuál es.
  String get resumen {
    final partes = <String>[
      if (empresas.length == 1)
        empresas.first
      else if (empresas.length > 1)
        '${empresas.length} empresas',
      if (porSucursal.length == 1)
        porSucursal.first.key
      else if (porSucursal.length > 1)
        '${porSucursal.length} sucursales',
      if (sinSucursal > 0) '$sinSucursal sin sucursal',
    ];
    return partes.join(' · ');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EL ESTADO DEL ROL: ETIQUETA PARA TODOS, CONTROL PARA RR.HH.
// ═══════════════════════════════════════════════════════════════════════════

/// Un paso posible del ciclo de vida del rol, con lo que hay que decir antes.
///
/// Están acá como datos y no como tres ramas de un `if` porque el texto es la
/// mitad de la función: quien aprieta tiene que saber QUÉ deja de andar antes
/// de apretar, no después.
enum PasoDelRol {
  publicar(
    destino: 'PUBLICADO',
    verbo: 'Publicar',
    icono: Icons.campaign_outlined,
    titulo: '¿Publicar el rol?',
    detalle:
        'Publicar significa que la rotación del año ya se repartió y que de aquí '
        'en más son excepciones.\n\n'
        'DEJA DE FUNCIONAR una sola cosa:\n'
        '• Regenerar. La varita, en modo «Regenerar», va a rebotar pidiendo que '
        'reabras el rol a borrador.\n\n'
        'SIGUE FUNCIONANDO igual que ahora:\n'
        '• los jefes programando desde «Su equipo»\n'
        '• las correcciones de celda a mano\n'
        '• los eventos, las convocatorias y los cambios\n'
        '• los refrescos de feriados y de vacaciones: esos no reparten nada, '
        'sincronizan con lo que carga RR.HH.\n\n'
        'Se puede volver atrás cuando quieras: reabrir está en el mismo menú.',
    exito: 'Rol publicado. La rotación quedó repartida; las excepciones siguen.',
  ),
  reabrir(
    destino: 'BORRADOR',
    verbo: 'Reabrir',
    icono: Icons.lock_open_outlined,
    titulo: '¿Reabrir a borrador?',
    detalle:
        'Vuelve a habilitarse «Regenerar», que reparte de nuevo la rotación A/B '
        'del año entero.\n\n'
        'Reabrir por sí solo NO toca ninguna celda: sólo destraba la '
        'regeneración. Ten en cuenta lo que va a pisar el día que la ejecutes:\n'
        '• las celdas que puso la rotación se borran y se rehacen\n'
        '• lo que programó un jefe y lo que corrigió RR.HH. a mano se conserva',
    exito: 'Rol reabierto a borrador. Ya se puede regenerar la rotación.',
  ),
  cerrar(
    destino: 'CERRADO',
    verbo: 'Cerrar el año',
    icono: Icons.lock_outline,
    titulo: '¿Cerrar el año?',
    detalle:
        'Cerrar congela el rol entero. Deja de aceptarse TODO: regenerar, '
        'programar desde «Su equipo», corregir celdas, marcar eventos, '
        'convocar, los cambios y los refrescos. Queda de sólo lectura.\n\n'
        'Y esto no se deshace desde la aplicación. El servidor rechaza '
        'cualquier modificación sobre un rol cerrado antes incluso de mirar qué '
        'le estás pidiendo, así que ni siquiera se le puede volver a cambiar el '
        'estado: para reabrirlo hay que ir a la base de datos.\n\n'
        'Si lo que quieres es dejar de repartir la rotación pero seguir '
        'arreglando excepciones, eso es PUBLICADO, no CERRADO.',
    exito: 'Año cerrado. El rol quedó de sólo lectura.',
  );

  const PasoDelRol({
    required this.destino,
    required this.verbo,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.exito,
  });

  final String destino;
  final String verbo;
  final IconData icono;
  final String titulo;
  final String detalle;
  final String exito;

  /// Cerrar es de ida: el botón se pinta como lo que es.
  bool get esDefinitivo => this == PasoDelRol.cerrar;

  /// A dónde se puede ir desde [estado].
  ///
  /// **`CERRADO` no lleva a ningún lado, y no es una omisión.** El SP corta con
  /// «El rol esta CERRADO; no admite modificaciones» en la primera validación
  /// del UPDATE, antes de mirar el `@estado` que se le manda: un menú con
  /// «Reabrir» ahí sería un botón que siempre falla.
  ///
  /// **Desde `BORRADOR` tampoco se ofrece cerrar**, aunque el SP lo aceptaría.
  /// Cerrar es «este año ya está, no se toca más», y un año que nunca se
  /// publicó no llegó a estar. Que el paso definitivo exija pasar por PUBLICADO
  /// obliga a cruzar una confirmación más antes de la puerta sin picaporte.
  static List<PasoDelRol> desde(String estado) => switch (estado) {
    'BORRADOR' => const [PasoDelRol.publicar],
    'PUBLICADO' => const [PasoDelRol.reabrir, PasoDelRol.cerrar],
    _ => const [],
  };
}

/// La etiqueta del estado, que para RR.HH. además es el control.
///
/// Es la misma pieza para los dos porque el estado es UNO: si el control
/// viviera en otro lado —un botón en la barra, una pantalla de ajustes— habría
/// dos lugares que dicen en qué estado está el rol y tarde o temprano dirían
/// cosas distintas.
///
/// **Quién puede: [administraRolProvider]** — Sistemas o RR.HH. Es el mismo
/// portón que los ABM y la varita, y por la misma razón: mover el estado del año
/// decide qué puede hacer todo el resto de la empresa, así que no lo decide
/// alguien que va a usar el permiso. Para los demás la etiqueta sigue siendo una
/// etiqueta y ni siquiera se ve que se pueda apretar.
///
/// **Esto era `ROLE_ADM` estricto y tenía que dejar de serlo el mismo día que
/// RR.HH. ganó la varita.** Reabrir a BORRADOR es el ÚNICO camino para regenerar
/// un rol publicado —`trs_sp_generarRol` lo rechaza y en el mensaje manda acá—,
/// y hoy los dos únicos usuarios del padrón de RR.HH. son `lim`. Dejar la varita
/// de un lado y la palanca del otro es dar un botón cuyo único desenlace posible
/// es un error cuyas instrucciones no se pueden seguir.
class EstadoDelRol extends ConsumerWidget {
  const EstadoDelRol({super.key, required this.rol});

  final RolSabadosEntity rol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pasos = PasoDelRol.desde(rol.estado);
    final administra = ref.watch(administraRolProvider);
    final etiqueta = Etiqueta(texto: rol.estado, tono: _tono(rol.estado));

    if (!administra || pasos.isEmpty) {
      return Tooltip(message: _queSignifica(rol.estado), child: etiqueta);
    }

    return PopupMenuButton<PasoDelRol>(
      tooltip: 'Cambiar el estado del rol',
      position: PopupMenuPosition.under,
      onSelected: (paso) => _confirmar(context, ref, paso),
      itemBuilder:
          (_) => [
            for (final p in pasos)
              PopupMenuItem(
                value: p,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(p.icono, size: 18),
                    const SizedBox(width: Esp.s),
                    // Acotado a mano: el menú se estira hasta el más ancho de
                    // sus items, y en 360 px «Cerrar el año» con el ícono y el
                    // padding del menú se pasaría del borde. Con el tope, el
                    // texto envuelve en vez de empujar.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(p.verbo),
                    ),
                  ],
                ),
              ),
          ],
      // El caret es lo único que distingue la versión que se puede apretar.
      // Va al lado y no adentro de la etiqueta para no cambiarle la forma: el
      // mismo estado se tiene que reconocer igual lo mire quien lo mire.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          etiqueta,
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
  }

  /// El color dice en qué punto del ciclo está, no si algo salió bien.
  ///
  /// `CERRADO` va en la familia de error porque es la única que se lee como
  /// «acá no se toca». No significa que cerrar esté mal.
  TonoEtiqueta _tono(String estado) => switch (estado) {
    'PUBLICADO' => TonoEtiqueta.exito,
    'CERRADO' => TonoEtiqueta.error,
    _ => TonoEtiqueta.neutro,
  };

  String _queSignifica(String estado) => switch (estado) {
    'BORRADOR' =>
      'Se está armando: la rotación se puede regenerar las veces que haga falta.',
    'PUBLICADO' =>
      'La rotación del año ya se repartió y no se vuelve a repartir sola. Las '
          'excepciones —programar, corregir, eventos, cambios— siguen andando.',
    'CERRADO' =>
      'El año está congelado: no se acepta ningún cambio. Reabrirlo no se '
          'puede desde aquí.',
    _ => estado,
  };

  Future<void> _confirmar(
    BuildContext context,
    WidgetRef ref,
    PasoDelRol paso,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(paso.titulo),
            // Scrollable por lo mismo que el diálogo de generar: en un teléfono
            // de 740 px de alto, el detalle de publicar no entra de una.
            content: SingleChildScrollView(
              child: Text(
                '${paso.detalle}\n\n'
                'El rol pasa de ${rol.estado} a ${paso.destino}.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style:
                    paso.esDefinitivo
                        ? FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                        )
                        : null,
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(paso.verbo),
              ),
            ],
          ),
    );
    if (ok != true || !context.mounted) return;

    await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .cambiarEstadoRol(
            idRol: rol.idRol,
            estado: paso.destino,
            // El valor que el rol YA tiene: el endpoint recibe la cabecera
            // entera y este campo no puede viajar vacío. Ver el repositorio.
            aplicaAsuetoCumple: rol.aplicaAsuetoCumple,
          ),
      exito: paso.exito,
    );
  }
}
