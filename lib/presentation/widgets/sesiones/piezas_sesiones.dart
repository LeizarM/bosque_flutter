import 'package:bosque_flutter/core/state/sesiones_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/sesion_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final DateFormat _hora = DateFormat('HH:mm');
final DateFormat _diaHora = DateFormat('dd/MM HH:mm');

/// «hace 3 min», «hace 2 h», «ayer 18:30»: lo que se lee de un vistazo en una lista de presencia.
String haceCuanto(DateTime? f, {DateTime? ahora}) {
  if (f == null) return '--';
  final ya = ahora ?? DateTime.now();
  final d = ya.difference(f);
  if (d.inMinutes < 1) return 'hace un momento';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 12) return 'hace ${d.inHours} h';
  return momento(f, ahora: ya);
}

/// La hora sola si fue hoy; si no, el día y la hora.
String momento(DateTime? f, {DateTime? ahora}) {
  if (f == null) return '--';
  final ya = ahora ?? DateTime.now();
  final mismoDia = f.year == ya.year && f.month == ya.month && f.day == ya.day;
  return mismoDia ? _hora.format(f) : _diaHora.format(f);
}

IconData iconoPlataforma(String plataforma) => switch (plataforma) {
  'web' => Icons.language,
  'android' => Icons.phone_android,
  'ios' => Icons.phone_iphone,
  'windows' || 'macos' || 'linux' => Icons.desktop_windows_outlined,
  _ => Icons.devices_other_outlined,
};

/// Cierra una sesión ajena tras confirmarlo y relee la lista. El backend no deja cerrar la propia.
Future<void> cerrarSesion(BuildContext context, SesionEntity s) async {
  // El contenedor se toma antes de esperar: si la tarjeta se desmonta mientras tanto, su ref ya no sirve.
  final contenedor = ProviderScope.containerOf(context, listen: false);
  final quien = s.nombreCompleto.isEmpty ? s.login : s.nombreCompleto;
  final ok = await confirmar(
    context,
    titulo: '¿Cerrar la sesión de $quien?',
    detalle:
        'Su app (${s.textoPlataforma}) vuelve al inicio de sesión en su próxima acción o en 2 minutos como '
        'máximo. Lo que no haya guardado se pierde. Puede volver a entrar con su contraseña.',
    textoConfirmar: 'Cerrar sesión',
    destructiva: true,
  );
  if (!ok || !context.mounted) return;
  try {
    final mensaje = await contenedor.read(sesionesRepositoryProvider).cerrar(s.idSesion);
    if (context.mounted) avisar(context, mensaje);
  } catch (e) {
    if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
  }
  contenedor.invalidate(sesionesAbiertasProvider);
  contenedor.invalidate(historialSesionesProvider);
}

/// El punto de presencia de una sesión. Ver [PuntoPresencia].
class Presencia extends StatelessWidget {
  const Presencia({super.key, required this.sesion});

  final SesionEntity sesion;

  @override
  Widget build(BuildContext context) => Semantics(
    label: sesion.textoEstado,
    child: PuntoPresencia(conectada: sesion.conectada, abierta: sesion.abierta),
  );
}

/// Lleno si la app mandó señal hace poco, hueco si no: la forma distingue, no solo el color.
/// También es la leyenda del resumen de la pestaña Abiertas.
class PuntoPresencia extends StatelessWidget {
  const PuntoPresencia({super.key, required this.conectada, required this.abierta});

  final bool conectada;
  final bool abierta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = conectada ? cs.primary : (abierta ? cs.tertiary : cs.outline);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: conectada ? color : null,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

/// El estado como etiqueta; «Sin señal» explica qué significa al pasar el puntero.
class EstadoSesion extends StatelessWidget {
  const EstadoSesion({super.key, required this.sesion});

  final SesionEntity sesion;

  @override
  Widget build(BuildContext context) {
    final etiqueta = Etiqueta(
      texto: sesion.textoEstado,
      tono: switch (sesion.estado) {
        'C' => TonoEtiqueta.exito,
        'N' => TonoEtiqueta.aviso,
        _ => sesion.motivoCierre == 'A' || sesion.motivoCierre == 'B' || sesion.motivoCierre == 'I'
            ? TonoEtiqueta.error
            : TonoEtiqueta.neutro,
      },
    );
    if (sesion.estado != 'N') return etiqueta;
    return Tooltip(
      message:
          'La app está oculta o se cerró sin «Cerrar sesión». Vuelve a «Conectada» en cuanto la abra; '
          'si no, la sesión vence ${momento(sesion.fechaVence)}.',
      child: etiqueta,
    );
  }
}

/// Persona: el nombre arriba y el usuario abajo, recortados si no entran.
class PersonaSesion extends StatelessWidget {
  const PersonaSesion({super.key, required this.sesion});

  final SesionEntity sesion;

  @override
  Widget build(BuildContext context) {
    final nombre = sesion.nombreCompleto.isEmpty ? sesion.login : sesion.nombreCompleto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: Peso.titulo)),
        Text(sesion.login, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.apagado()),
      ],
    );
  }
}

/// Plataforma y versión con su ícono.
class EquipoSesion extends StatelessWidget {
  const EquipoSesion({super.key, required this.sesion});

  final SesionEntity sesion;

  @override
  Widget build(BuildContext context) {
    final version = sesion.versionApp == null ? '' : ' · ${sesion.versionApp}';
    return Row(
      children: [
        Icon(iconoPlataforma(sesion.plataforma), size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: Esp.s),
        Flexible(
          child: Text('${sesion.textoPlataforma}$version', maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// La acción de la fila: cerrar si está abierta; la propia solo se rotula.
class AccionSesion extends StatelessWidget {
  const AccionSesion({super.key, required this.sesion});

  final SesionEntity sesion;

  @override
  Widget build(BuildContext context) {
    if (sesion.esActual) return const Etiqueta(texto: 'Esta sesión');
    if (!sesion.abierta) return const SizedBox.shrink();
    return TextButton.icon(
      onPressed: () => cerrarSesion(context, sesion),
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Cerrar sesión'),
    );
  }
}

const double anchoEntradaSesion = 110;
const double anchoAccionSesion = 156;

/// Fila de la tabla de escritorio. [historial] cambia «Última señal» por cómo terminó.
class FilaTablaSesion extends StatelessWidget {
  const FilaTablaSesion({
    super.key,
    required this.sesion,
    required this.historial,
    required this.amplio,
  });

  final SesionEntity sesion;
  final bool historial;

  /// Con lugar se agregan la IP y la hora de entrada.
  final bool amplio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      child: Row(
        children: [
          Padding(padding: const EdgeInsets.only(right: Esp.m), child: Presencia(sesion: sesion)),
          Expanded(flex: 4, child: PersonaSesion(sesion: sesion)),
          const SizedBox(width: Esp.m),
          Expanded(flex: 3, child: EquipoSesion(sesion: sesion)),
          if (amplio) ...[
            const SizedBox(width: Esp.m),
            Expanded(flex: 2, child: Text(sesion.ip ?? '--', maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          if (amplio || historial)
            SizedBox(width: anchoEntradaSesion, child: Text(momento(sesion.fechaInicio))),
          const SizedBox(width: Esp.m),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  historial
                      ? _Termino(sesion: sesion)
                      : Text(haceCuanto(sesion.fechaUltimaSenal), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          SizedBox(
            width: anchoAccionSesion,
            child: Align(alignment: Alignment.centerRight, child: AccionSesion(sesion: sesion)),
          ),
        ],
      ),
    );
  }
}

/// En el historial: cómo terminó y cuándo; si sigue abierta, su estado.
class _Termino extends StatelessWidget {
  const _Termino({required this.sesion});

  final SesionEntity sesion;

  @override
  Widget build(BuildContext context) {
    if (sesion.fechaCierre == null) return EstadoSesion(sesion: sesion);
    return Text(
      '${sesion.textoCierre ?? 'Cerrada'} · ${momento(sesion.fechaCierre)}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Tarjeta de teléfono: lo mismo que la fila, apilado, con la acción en un menú.
class TarjetaSesion extends StatelessWidget {
  const TarjetaSesion({super.key, required this.sesion, required this.historial});

  final SesionEntity sesion;
  final bool historial;

  @override
  Widget build(BuildContext context) {
    final detalle =
        historial
            ? 'Entró ${momento(sesion.fechaInicio)} · '
                '${sesion.fechaCierre == null ? sesion.textoEstado : '${sesion.textoCierre ?? 'Cerrada'} ${momento(sesion.fechaCierre)}'}'
            : 'Entró ${momento(sesion.fechaInicio)} · señal ${haceCuanto(sesion.fechaUltimaSenal)}';

    return Card(
      margin: const EdgeInsets.only(bottom: Esp.s),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.xs, Esp.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 5, right: Esp.m), child: Presencia(sesion: sesion)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PersonaSesion(sesion: sesion),
                  const SizedBox(height: Esp.xs),
                  EquipoSesion(sesion: sesion),
                  const SizedBox(height: Esp.xs),
                  Text(detalle, style: context.apagado()),
                  if (sesion.ip != null) Text('IP ${sesion.ip}', style: context.apagado()),
                  if (!historial) ...[
                    const SizedBox(height: Esp.xs),
                    EstadoSesion(sesion: sesion),
                  ],
                ],
              ),
            ),
            if (sesion.esActual)
              const Padding(padding: EdgeInsets.only(right: Esp.s), child: Etiqueta(texto: 'Esta sesión'))
            else if (sesion.abierta)
              PopupMenuButton<String>(
                tooltip: 'Acciones de la sesión',
                onSelected: (_) => cerrarSesion(context, sesion),
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: 'cerrar',
                        child: ListTile(
                          leading: Icon(Icons.logout),
                          title: Text('Cerrar sesión'),
                          contentPadding: EdgeInsets.zero,
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
