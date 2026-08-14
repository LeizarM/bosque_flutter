import 'dart:async';

import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La puerta de entrada del módulo: encontrar a la persona.
///
/// Hasta 1000 px ocupa todo y al tocar una tarjeta se **empuja** el detalle; de
/// ahí para arriba es el panel maestro de 400 px y el detalle vive al lado.
/// Quien decide eso es la pantalla contenedora, que pasa [onElegir]: acá no se
/// navega, se avisa quién fue elegido.
class BuscadorDeEmpleados extends ConsumerStatefulWidget {
  const BuscadorDeEmpleados({super.key, required this.onElegir});

  /// Qué hacer con el empleado elegido. El provider global ya quedó escrito
  /// cuando esto se llama.
  final void Function(EmpleadoEntity empleado) onElegir;

  @override
  ConsumerState<BuscadorDeEmpleados> createState() =>
      _BuscadorDeEmpleadosState();
}

class _BuscadorDeEmpleadosState extends ConsumerState<BuscadorDeEmpleados> {
  final _texto = TextEditingController();

  /// El rebote: la consulta sale cuando la persona deja de tipear.
  ///
  /// Sin esto, «MARTINEZ» son ocho viajes al servidor y ocho listas que se
  /// pisan entre sí; la última en llegar no tiene por qué ser la de la última
  /// letra.
  Timer? _rebote;

  /// Qué tiene de malo lo que se escribió, o null si está bien.
  String? _reclamo;

  @override
  void initState() {
    super.initState();
    // Al volver al módulo el filtro sigue puesto: el campo tiene que mostrarlo,
    // o se vería una lista filtrada con el buscador en blanco.
    _texto.text = ref.read(busquedaEmpleadoProvider);
  }

  @override
  void dispose() {
    _rebote?.cancel();
    _texto.dispose();
    super.dispose();
  }

  /// Sólo letras y espacios, hasta 20 caracteres.
  ///
  /// **Es la regla del sistema viejo, pero al revés.** Allá el `<p:inputText>`
  /// tenía este mismo patrón y, cuando no validaba, **borraba lo tipeado sin
  /// decir nada**: quien escribía «PEREZ-GOMEZ» veía desaparecer el texto y
  /// volvía a escribirlo igual. Acá el texto se queda y la pantalla dice qué
  /// tiene de malo.
  static String? _queTieneDeMalo(String t) {
    if (t.length > 20) return 'Hasta 20 caracteres.';
    if (!RegExp(r'^[a-zA-ZñÑáÁéÉíÍóÓúÚ ]*$').hasMatch(t)) {
      return 'Sólo letras y espacios: buscá por nombre o apellido.';
    }
    return null;
  }

  void _alTipear(String t) {
    // El `setState` va siempre y no sólo cuando cambia el reclamo: también
    // refresca el botón de limpiar, que aparece con la primera letra.
    setState(() => _reclamo = _queTieneDeMalo(t));
    if (_reclamo != null) return;

    _rebote?.cancel();
    _rebote = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(busquedaEmpleadoProvider.notifier).state = t.trim();
    });
  }

  void _elegir(EmpleadoEntity e) {
    ref.read(empleadoSeleccionadoProvider.notifier).state = e;
    widget.onElegir(e);
  }

  @override
  Widget build(BuildContext context) {
    final elegido = ref.watch(empleadoSeleccionadoProvider);

    return LayoutBuilder(
      builder: (context, cajon) {
        // El ancho del CAJÓN, no el de la ventana: en el panel maestro este
        // widget mide 400 px aunque el monitor tenga 1920.
        final aire = Aire.de(cajon.maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(Esp.m),
              child: _filtros(aire),
            ),
            const Divider(height: 1),
            Expanded(child: _resultados(elegido)),
          ],
        );
      },
    );
  }

  /// Apilados cuando el panel es angosto; en una fila cuando entra.
  Widget _filtros(Aire aire) {
    final campo = TextField(
      controller: _texto,
      onChanged: _alTipear,
      // El rebote es para no consultar por letra; si alguien da Enter, ya
      // terminó de escribir y esperar 350 ms más sería sólo lentitud.
      onSubmitted: (t) {
        _rebote?.cancel();
        if (_queTieneDeMalo(t) == null) {
          ref.read(busquedaEmpleadoProvider.notifier).state = t.trim();
        }
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: 'Buscar empleado',
        hintText: 'Nombre o apellido',
        errorText: _reclamo,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon:
            _texto.text.isEmpty
                ? null
                : IconButton(
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _texto.clear();
                    _alTipear('');
                  },
                ),
      ),
    );

    final soloActivos = ref.watch(filtroSoloActivosProvider);
    final interruptor = SwitchListTile(
      value: soloActivos,
      onChanged: (v) => ref.read(filtroSoloActivosProvider.notifier).state = v,
      title: const Text('Sólo activos'),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );

    if (aire.esChico) {
      return Column(children: [campo, interruptor]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: campo),
        const SizedBox(width: Esp.m),
        // Ancho fijo: el interruptor con su rótulo no encoge más que esto sin
        // partir «Sólo activos» en dos renglones.
        SizedBox(width: 160, child: interruptor),
      ],
    );
  }

  Widget _resultados(EmpleadoEntity? elegido) {
    final lista = ref.watch(empleadosBuscadosProvider);

    return lista.when(
      loading: () => const Cargando(),
      error:
          (e, _) => ErrorDelDato(
            error: e,
            onReintentar: () => ref.invalidate(empleadosBuscadosProvider),
          ),
      data: (empleados) {
        if (empleados.isEmpty) {
          final buscando = ref.read(busquedaEmpleadoProvider).isNotEmpty;
          return MensajeVacio(
            icono: Icons.person_search_outlined,
            titulo:
                buscando ? 'Nadie con ese nombre' : 'No hay empleados que ver',
            detalle:
                buscando
                    ? 'Pruebe con el apellido, o apague «Sólo activos» si la '
                        'persona ya no trabaja acá.'
                    : 'Si esperaba ver la nómina, avise a Sistemas: puede ser '
                        'un permiso que falta y no una lista vacía.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(Esp.s, Esp.s, Esp.s, Esp.xl),
          itemCount: empleados.length,
          itemBuilder: (context, i) {
            final e = empleados[i];
            return _TarjetaEmpleado(
              empleado: e,
              elegida: e.codEmpleado == elegido?.codEmpleado,
              onTap: () => _elegir(e),
            );
          },
        );
      },
    );
  }
}

/// Una persona en la lista de resultados.
///
/// `Card` + `InkWell` y no un `ListTile` pelado: en el celular esto es el
/// objetivo de un dedo, y la tarjeta le da el área y el borde que un `ListTile`
/// en una lista larga no deja ver.
class _TarjetaEmpleado extends StatelessWidget {
  const _TarjetaEmpleado({
    required this.empleado,
    required this.elegida,
    required this.onTap,
  });

  final EmpleadoEntity empleado;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // **Las rutas que el endpoint SÍ llena.** `/rrhh/obtenerLstEmpleados`
    // (`p_list_Empleado @ACCION='Y'`) devuelve 10 columnas y su row mapper
    // (`EmpleadoDAO.obtenerLstEmpleados`) las escribe TODAS colgando de
    // `persona` y de `empleadoCargo.cargoSucursal.cargo`. El `datoPersona` de
    // nivel raíz existe sólo porque `Empleado extends Persona` y queda en null,
    // y el `empresa` de nivel raíz es un objeto vacío. Leer de ahí no falla:
    // `fromJson` los convierte en '' y la tarjeta sale en blanco. Es la misma
    // ruta que usa `lista_empleados.dart`, el otro consumidor del endpoint.
    final cargoObj = empleado.empleadoCargo.cargoSucursal?.cargo;
    final cargo = (cargoObj?.descripcionPlanilla ?? '').trim();
    // La empresa de PLANILLA, no la del cargo real: es la que hace juego con
    // `descripcionPlanilla` y con el filtro `codEmpresa` de este mismo endpoint
    // (que filtra por `codEmpresaPlanilla`). El detalle usa el cargo real y su
    // empresa, así que los dos nombres pueden diferir — comportamiento legacy,
    // documentado en el plan §6.2.
    final empresa = (cargoObj?.nombreEmpresaPlanilla ?? '').trim();

    // Empresa y cargo son lo único que desambigua homónimos en una nómina, y la
    // pantalla siguiente le atribuye un saldo a la persona elegida: si esta
    // línea sale vacía, elegir al «PEREZ GOMEZ JUAN» equivocado no se nota. 13
    // de 250 empleados no tienen cargo asignado (el join es LEFT en el SP), así
    // que el caso vacío existe y se dice en vez de dejar un renglón en blanco.
    final partes = [empresa, cargo].where((t) => t.isNotEmpty);
    final subtitulo =
        partes.isEmpty ? 'Sin empresa ni cargo asignado' : partes.join(' · ');

    return Card(
      // El elegido se marca con el contenedor primario del tema y no con un
      // celeste a mano: con la semilla verde o la roja, un celeste fijo sería
      // el único azul de la pantalla.
      color: elegida ? cs.primaryContainer : null,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: Esp.xs, vertical: Esp.xs),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Esp.m,
            vertical: Esp.m,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empleado.persona.datoPersona ?? '',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: Peso.titulo,
                        color: elegida ? cs.onPrimaryContainer : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            elegida
                                ? cs.onPrimaryContainer.withValues(alpha: 0.75)
                                : Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Esp.s),
              Icon(
                Icons.chevron_right,
                size: 20,
                color:
                    elegida
                        ? cs.onPrimaryContainer
                        : Theme.of(context).hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
