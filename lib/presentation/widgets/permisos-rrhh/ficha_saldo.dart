import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/ficha_saldo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// La respuesta a *«¿cuántos días tengo?»*, que es lo que RR.HH. contesta todo
/// el día. Es la pestaña «Saldo».
///
/// **Origen:** `p_list_Permiso 'C'`, una llamada, una fila. Los números vienen
/// formateados del backend (`*Txt`); acá sólo se decide dónde van y de qué color.
class SaldoTab extends ConsumerWidget {
  const SaldoTab({super.key, required this.codEmpleado});

  final int codEmpleado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ficha = ref.watch(fichaSaldoProvider(codEmpleado));

    return ficha.when(
      loading: () => const Cargando(),
      error:
          (e, _) => ErrorDelDato(
            error: e,
            onReintentar: () => ref.invalidate(fichaSaldoProvider(codEmpleado)),
          ),
      data: (f) {
        if (f == null) {
          return const MensajeVacio(
            icono: Icons.badge_outlined,
            titulo: 'Sin ficha de saldo',
            // 204: la consulta salió bien y no devolvió filas. Los casos que sí
            // tienen explicación —no existe, sin relación activa, sin cargo—
            // llegan como error con el texto del backend, no por acá.
            detalle:
                'La consulta no devolvió datos para este empleado. Verifique en '
                'el sistema anterior que tenga cargo y relación laboral activa.',
          );
        }

        return LayoutBuilder(
          builder: (context, cajon) {
            final aire = Aire.de(cajon.maxWidth);
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(fichaSaldoProvider(codEmpleado));
                await ref.read(fichaSaldoProvider(codEmpleado).future);
              },
              child: ListView(
                padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.l),
                children: [
                  Center(
                    child: ConstrainedBox(
                      // La ficha no crece con el monitor: son cuatro líneas y
                      // tres números, y a 1900 px de ancho el ojo pierde de qué
                      // fila es cada cosa.
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Tarjeta(ficha: f, aire: aire),
                          const SizedBox(height: Esp.l),
                          _EstadoDeCuenta(codEmpleado: codEmpleado),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.ficha, required this.aire});

  final FichaSaldoEntity ficha;
  final Aire aire;

  @override
  Widget build(BuildContext context) {
    final relleno = aire.esChico ? Esp.m : Esp.l;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(relleno),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ficha.datoEmpleado,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: Peso.titulo),
            ),
            const SizedBox(height: 2),
            Text(
              '${ficha.datoEmpresa} · ${ficha.datoCargo}',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.m),

            // Antigüedad y fecha de beneficio: contexto del número, no el
            // número. Van como etiquetas y no como métricas a propósito.
            Wrap(
              spacing: Esp.s,
              runSpacing: Esp.s,
              children: [
                Etiqueta(texto: 'Antigüedad: ${ficha.datoAntiguedad}'),
                Etiqueta(
                  texto: 'Beneficio desde: ${ficha.datoFechaBeneficio}',
                  tono:
                      ficha.tieneFechaBeneficio
                          ? TonoEtiqueta.neutro
                          : TonoEtiqueta.aviso,
                ),
              ],
            ),

            if (!ficha.tieneFechaBeneficio) ...[
              const SizedBox(height: Esp.m),
              const AvisoDelDato(
                icono: Icons.warning_amber_rounded,
                // El literal 'Sin Asignar' lo escribe el propio SP. Sin fecha de
                // beneficio los tramos 1 y 4 del desglose dan 0 y el 2 muestra
                // toda la historia: no son cinco ceros, es un desglose corrido.
                texto:
                    'Este empleado no tiene fecha de inicio de beneficio '
                    'cargada. El saldo se calcula igual, pero el desglose por '
                    'año laboral no va a ser confiable hasta que se cargue en '
                    'el sistema anterior.',
              ),
            ],

            // ── SUPUESTO D0 — pendiente de confirmación de RR.HH. (plan §5) ──
            //
            // El SP suma SÓLO la relación laboral activa. El 58 % de los
            // permisos y el 49 % de las asignaciones de los empleados activos
            // vive en relaciones anteriores y no entra en estos números. Se
            // tomó la opción (c): no se cambia el cálculo, se rotula el alcance
            // — pero se rotula en la pantalla, no en un manual. Si RR.HH.
            // confirma que el saldo debe abarcar todas las relaciones, cambia
            // el backend y este bloque se borra; nada más de acá se rehace.
            if (ficha.tieneRelacionesAnteriores) ...[
              const SizedBox(height: Esp.m),
              AvisoDelDato(
                icono: Icons.history,
                texto: _rotuloDeAlcance(ficha),
              ),
            ],

            const Divider(height: Esp.xl),

            // `Wrap` y no `Row`: en 360 px las tres métricas no entran en una
            // fila, y un `Row` que no entra no se acomoda — pinta la franja
            // amarilla y negra.
            Wrap(
              spacing: Esp.xl,
              runSpacing: Esp.m,
              children: [
                Metrica(
                  rotulo: 'Días no usados',
                  texto: ficha.diasNoUsadosTxt,
                  valor: ficha.diasNoUsados,
                ),
                Metrica(
                  rotulo: 'Días abonados',
                  texto: ficha.diasAbonadosTxt,
                  valor: ficha.diasAbonados,
                ),
                Metrica(
                  rotulo: 'Total',
                  texto: ficha.totalDiasTxt,
                  valor: ficha.totalDias,
                  destacada: true,
                ),
              ],
            ),

            // ── SUPUESTO D1 — pendiente de confirmación de RR.HH. (plan §5) ──
            //
            // Se tomó la opción (c): los dos números se muestran desglosados y
            // rotulados. Este total es el de la consola ('C'); el que el
            // empleado ve en su propia app sale de otra acción ('H1') y no
            // siempre coincide — 45 negativos contra 10, y 35 cambios de signo.
            // Decirlo acá es más barato que explicarlo por teléfono.
            const SizedBox(height: Esp.m),
            Text(
              'Total = días no usados + días abonados, de la relación laboral '
              'vigente. Es la cifra de la consola de RR.HH.; la que el empleado '
              've en su app se calcula distinto y puede no coincidir.',
              style: context.apagado(),
            ),
          ],
        ),
      ),
    );
  }

  /// «Saldo de la relación laboral actual, desde dd/mm/aaaa · N movimientos
  /// anteriores no incluidos».
  ///
  /// El «desde» se omite si el backend no pudo resolver la fecha: una frase sin
  /// fecha es incompleta, pero «desde --» es peor.
  static String _rotuloDeAlcance(FichaSaldoEntity f) {
    final desde =
        f.relacionVigenteDesde == null
            ? ''
            : ', desde ${fechaCorta(f.relacionVigenteDesde)}';
    final cuantos = f.movimientosFueraDeRelacionVigente;
    final movimientos =
        cuantos == 1
            ? '1 movimiento anterior no incluido'
            : '$cuantos movimientos anteriores no incluidos';
    return 'Saldo de la relación laboral actual$desde · $movimientos.';
  }
}

/// **El estado de cuenta en PDF** — el «DETALLE COMPLETO» del sistema anterior.
///
/// Dos variantes, y la diferencia importa: la **interna** muestra los días
/// abonados y la **fiscal** no. Ese recorte lo decidió la empresa hace años y
/// vive dentro del `.jrxml`, no acá, así que no hay forma de pedir la fiscal y
/// que salga con abonados. Se rotula cuál es cuál en vez de dejar dos botones
/// que parecen lo mismo.
class _EstadoDeCuenta extends ConsumerStatefulWidget {
  const _EstadoDeCuenta({required this.codEmpleado});

  final int codEmpleado;

  @override
  ConsumerState<_EstadoDeCuenta> createState() => _EstadoDeCuentaState();
}

class _EstadoDeCuentaState extends ConsumerState<_EstadoDeCuenta> {
  String? _bajando;

  @override
  Widget build(BuildContext context) => PermissionWidget(
    buttonName: btnReportes,
    child: Bloque(
      icono: Icons.picture_as_pdf_outlined,
      titulo: 'Estado de cuenta',
      explicacion:
          'El resumen completo del empleado en PDF, con el mismo formato que '
          'imprime el sistema anterior.',
      hijo: Wrap(
        spacing: Esp.m,
        runSpacing: Esp.s,
        children: [
          _boton(
            clave: 'interno',
            texto: 'Interno',
            endpoint: AppConstants.permRrhhEstadoCuenta,
          ),
          _boton(
            clave: 'fiscal',
            texto: 'Fiscal (sin días abonados)',
            endpoint: AppConstants.permRrhhEstadoCuentaFiscal,
          ),
        ],
      ),
    ),
  );

  Widget _boton({
    required String clave,
    required String texto,
    required String endpoint,
  }) => OutlinedButton.icon(
    onPressed: _bajando != null ? null : () => _bajar(clave, texto, endpoint),
    icon:
        _bajando == clave
            ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : const Icon(Icons.download_outlined, size: 18),
    label: Text(texto),
  );

  Future<void> _bajar(String clave, String texto, String endpoint) async {
    setState(() => _bajando = clave);
    try {
      final pdf = await DioClient.descargarReportePdf(
        endpoint: endpoint,
        data: {'codEmpleado': widget.codEmpleado},
      );
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name: 'EstadoCuenta_${clave}_${widget.codEmpleado}',
      );
    } catch (e) {
      if (!mounted) return;
      avisarError(context, e);
    } finally {
      if (mounted) setState(() => _bajando = null);
    }
  }
}
