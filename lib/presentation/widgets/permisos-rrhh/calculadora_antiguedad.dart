import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cuántos días le corresponderían a alguien que entró tal día, mirado a tal
/// fecha. Es la pestaña «Calculadora», la de antigüedad.
///
/// **Es una herramienta de tanteo, no el saldo de nadie.** Lo dice la pantalla y
/// hay motivo: `f_calcDiasLaborablesExt` cuenta años enteros con un `WHILE`,
/// mientras el saldo real usa `f_calcVacacionesAnioLaboral`, que trabaja con
/// fracción de año. Cerca de un aniversario las dos caen en tramos distintos de
/// la escala (0–4 años → 15 días, 5–9 → 20, 10+ → 30) y dan números distintos.
///
/// **La frase se muestra tal cual y no se parsea.** Viene en prosa del propio
/// SP; sacarle los números a mano sería inventar un contrato que no existe. Si
/// alguna vez hace falta el desglose numérico se pide una ACCION nueva que
/// devuelva columnas.
class CalculadoraTab extends ConsumerStatefulWidget {
  const CalculadoraTab({super.key});

  @override
  ConsumerState<CalculadoraTab> createState() => _CalculadoraTabState();
}

class _CalculadoraTabState extends ConsumerState<CalculadoraTab> {
  DateTime? _desde;
  DateTime? _hasta;

  /// El rango que se está calculando, o null si todavía no se pidió nada.
  ///
  /// **Es un record y se setea recién al apretar el botón**, no en cada cambio
  /// de fecha: es la clave de un `family`, y elegir una fecha en el calendario
  /// dispararía una consulta por cada toque en el selector.
  RangoDeCalculo? _rango;

  Future<void> _elegirFecha({required bool esDesde}) async {
    final hoy = DateTime.now();
    final inicial = (esDesde ? _desde : _hasta) ?? hoy;

    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      // Desde 1950: hay relaciones laborales de los años 60 en la base. Hasta
      // diez años adelante, que es lo que sirve para proyectar.
      firstDate: DateTime(1950),
      lastDate: DateTime(hoy.year + 10, 12, 31),
      helpText: esDesde ? 'Inicio de beneficio' : 'Calcular hasta',
    );

    // `use_build_context_synchronously` está apagado en `analysis_options.yaml`:
    // el analizador no avisa, así que el guardia va a mano.
    if (!mounted || elegida == null) return;
    setState(() {
      if (esDesde) {
        _desde = elegida;
      } else {
        _hasta = elegida;
      }
    });
  }

  void _calcular() {
    final desde = _desde;
    final hasta = _hasta;
    if (desde == null || hasta == null) return;

    // El backend también lo valida —es el que manda—, pero rebotar acá evita un
    // viaje y da el mensaje en el acto. 60 años es el tope del plan.
    final anios = hasta.difference(desde).inDays.abs() / 365.25;
    if (anios > 60) {
      avisarError(
        context,
        'El rango no puede pasar de 60 años. Revise las dos fechas.',
      );
      return;
    }

    setState(() => _rango = (desde: desde, hasta: hasta));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cajon) {
        final aire = Aire.de(cajon.maxWidth);

        return ListView(
          padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.l),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _formulario(aire),
                    const SizedBox(height: Esp.l),
                    if (_rango != null) _resultado(_rango!),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _formulario(Aire aire) {
    // `CampoElegido` vive en las piezas del módulo desde que las hojas de
    // escritura necesitaron el mismo campo: acá había una copia privada.
    final desde = CampoElegido(
      etiqueta: 'Inicio de beneficio',
      texto: _desde == null ? null : fechaCorta(_desde),
      onTap: () => _elegirFecha(esDesde: true),
    );
    final hasta = CampoElegido(
      etiqueta: 'Calcular hasta',
      texto: _hasta == null ? null : fechaCorta(_hasta),
      onTap: () => _elegirFecha(esDesde: false),
    );

    return Bloque(
      icono: Icons.calculate_outlined,
      titulo: 'Calculadora de antigüedad',
      explicacion:
          'Orientativa: sirve para tantear un caso, no para responder cuántos '
          'días tiene alguien. Ese número está en «Saldo».',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Apilados en pantalla angosta: dos campos de fecha en una fila de
          // 360 px dejan cada uno con 160 px y el rótulo se parte.
          if (aire.esChico) ...[
            desde,
            const SizedBox(height: Esp.m),
            hasta,
          ] else
            Row(
              children: [
                Expanded(child: desde),
                const SizedBox(width: Esp.m),
                Expanded(child: hasta),
              ],
            ),
          const SizedBox(height: Esp.l),
          // A ancho completo en el celular; del tamaño de su texto cuando hay
          // lugar, para que no quede una barra de 680 px que dice «Calcular».
          Align(
            alignment: aire.esChico ? Alignment.center : Alignment.centerLeft,
            child: SizedBox(
              width: aire.esChico ? double.infinity : null,
              child: FilledButton.icon(
                // Deshabilitado y no un error después: pedir las dos fechas es
                // más claro que dejar apretar y contestar que faltan.
                onPressed:
                    (_desde != null && _hasta != null) ? _calcular : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Calcular'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultado(RangoDeCalculo rango) {
    final calculo = ref.watch(calculoAntiguedadProvider(rango));

    return calculo.when(
      loading: () => const Cargando(),
      error:
          (e, _) => ErrorDelDato(
            error: e,
            onReintentar:
                () => ref.invalidate(calculoAntiguedadProvider(rango)),
          ),
      data: (texto) {
        if (texto.trim().isEmpty) {
          return const MensajeVacio(
            icono: Icons.calculate_outlined,
            titulo: 'El cálculo no devolvió nada',
            detalle: 'Pruebe con otras fechas o avise a Sistemas.',
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fechaCorta(rango.desde)} → ${fechaCorta(rango.hasta)}',
                  style: context.apagado(),
                ),
                const SizedBox(height: Esp.s),
                SelectableText(
                  texto,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.4),
                ),
                if (_esCasoLimite(texto)) ...[
                  const SizedBox(height: Esp.m),
                  const AvisoDelDato(
                    icono: Icons.warning_amber_rounded,
                    texto:
                        'El cálculo cae en un caso límite (aniversario exacto o '
                        'las dos fechas en el mismo mes) y por eso dice 0 días. '
                        'Verifique con otra fecha.',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// El día exacto del aniversario —y cuando las dos fechas caen en el mismo
  /// mes— la función del sistema anterior saltea el bloque que calcula los
  /// meses y devuelve **0 días por antigüedad**, justo en el caso más
  /// simbólico: el día en que se devenga la nueva dotación.
  ///
  /// No se arregla acá ni se parsea la frase: se detecta la subcadena y se
  /// avisa. El arreglo es un ticket para el DBA.
  static bool _esCasoLimite(String texto) =>
      texto.contains('= 0 dias por antiguedad');
}
