// Destino final: lib/presentation/widgets/tareas-rutinarias/apertura_flujo.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Consigue el `idBitTarea` con el que trabaja un submódulo a requerimiento.
///
/// Caja Fuerte, Coches, Caja Chica y Cierre de Operaciones dejaron de ser
/// tareas rutinarias (archivo SQL 40): el Job ya no las genera todas las noches
/// para todo el mundo. Ahora se entra por el menú, cuando hace falta.
///
/// Pero todo lo que cuelga de ellas —`tac_llegada`, `tac_cocheLlegadas`,
/// `tac_cajaChica`— sigue identificando el trabajo por la ocurrencia. Así que la
/// ocurrencia se sigue creando: recién ahora, en el momento en que alguien entra.
/// Eso deja los procs, los reportes y el historial funcionando sin cambios.
///
/// Cuando la pantalla se abre desde un `idBitTarea` que ya existe (por ejemplo
/// desde "Verificar cierre", que apunta a una ocurrencia concreta de otra
/// persona), no se abre nada: se usa ese.
class AperturaFlujoRepo extends BaseApiRepository {
  Future<int> abrir(int idTarRuti) async {
    final id = await postAndReturnId(
      endpoint: AppConstants.tarAbrirFlujo,
      data: {'idTarRuti': idTarRuti},
    );
    return id.toInt();
  }
}

final aperturaFlujoRepoProvider = Provider((ref) => AperturaFlujoRepo());

/// Una apertura por (flujo, sesión de pantalla). `family` sobre el idTarRuti
/// para que Caja Chica y Caja Fuerte no compartan resultado, y `autoDispose`
/// para que al salir y volver a entrar se vuelva a preguntar — el día pudo
/// cambiar mientras la app estaba abierta.
final aperturaFlujoProvider = FutureProvider.autoDispose.family<int, int>((
  ref,
  idTarRuti,
) {
  return ref.watch(aperturaFlujoRepoProvider).abrir(idTarRuti);
});

/// Envuelve la pantalla de un flujo y le entrega el `idBitTarea` ya resuelto.
///
/// Se hizo como envoltorio y no tocando las cuatro pantallas por dentro porque
/// las cuatro ya funcionan y están probadas: lo único que cambió es de dónde
/// sale el id.
/// El tipo de tarea (idATR) de cada flujo a requerimiento, para la insignia
/// de la espera y del error: la misma que tendrá la pantalla al abrir.
const _idATRPorTarea = {40: 4, 41: 6, 42: 7, 2: 3};

class AperturaFlujo extends ConsumerWidget {
  /// La tarea del flujo: 40 Caja Fuerte, 41 Coches, 42 Caja Chica,
  /// 2 Cierre de Operaciones.
  final int idTarRuti;

  /// Si ya viene uno (llegaste desde otra pantalla que apunta a una ocurrencia
  /// puntual), se usa tal cual y no se abre nada.
  final int? idBitTareaExistente;

  /// Para el título de la pantalla de error, y nada más.
  final String nombreFlujo;

  final Widget Function(int idBitTarea) construir;

  const AperturaFlujo({
    super.key,
    required this.idTarRuti,
    required this.nombreFlujo,
    required this.construir,
    this.idBitTareaExistente,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existente = idBitTareaExistente ?? 0;
    if (existente > 0) return construir(existente);

    return ref
        .watch(aperturaFlujoProvider(idTarRuti))
        .when(
          loading:
              () => _Cargando(
                idATR: _idATRPorTarea[idTarRuti],
                nombreFlujo: nombreFlujo,
              ),
          error:
              (e, _) => _NoSePudoAbrir(
                idATR: _idATRPorTarea[idTarRuti],
                nombreFlujo: nombreFlujo,
                mensaje: _mensajeDe(e),
                reintentar:
                    () => ref.invalidate(aperturaFlujoProvider(idTarRuti)),
              ),
          data: (id) {
            // El backend nunca devuelve 0 con éxito, pero si algún día lo
            // hiciera, la pantalla trabajaría contra una ocurrencia inexistente
            // y guardaría en el vacío. Mejor decirlo.
            if (id <= 0) {
              return _NoSePudoAbrir(
                idATR: _idATRPorTarea[idTarRuti],
                nombreFlujo: nombreFlujo,
                mensaje:
                    'El servidor no devolvió una ocurrencia válida para este flujo.',
                reintentar:
                    () => ref.invalidate(aperturaFlujoProvider(idTarRuti)),
              );
            }
            return construir(id);
          },
        );
  }

  /// Las excepciones del repo llegan como `Exception: <mensaje del backend>`.
  /// Se le saca el prefijo para no mostrarle "Exception:" a un cajero.
  static String _mensajeDe(Object e) {
    final texto = e.toString();
    const prefijo = 'Exception: ';
    return texto.startsWith(prefijo) ? texto.substring(prefijo.length) : texto;
  }
}

class _Cargando extends StatelessWidget {
  final int? idATR;
  final String nombreFlujo;

  const _Cargando({required this.idATR, required this.nombreFlujo});

  @override
  Widget build(BuildContext context) {
    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: nombreFlujo,
          subtitulo: 'Abriendo la tarea de hoy…',
          insignia: InsigniaTarea.deTipo(context, idATR),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _NoSePudoAbrir extends StatelessWidget {
  final int? idATR;
  final String nombreFlujo;
  final String mensaje;
  final VoidCallback reintentar;

  const _NoSePudoAbrir({
    required this.idATR,
    required this.nombreFlujo,
    required this.mensaje,
    required this.reintentar,
  });

  @override
  Widget build(BuildContext context) {
    // Antes con un candado: se leía como "no tienes permiso" cuando lo que
    // pasaba casi siempre era la red.
    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: nombreFlujo,
          insignia: InsigniaTarea.deTipo(context, idATR),
        ),
        body: EstadoTareas.error(
          titulo: 'No se pudo abrir $nombreFlujo',
          detalle: mensaje,
          onReintentar: reintentar,
        ),
      ),
    );
  }
}
