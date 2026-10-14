import 'package:bosque_flutter/core/state/configuracion_recuperacion_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/configuracion_recuperacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/configuracion-recuperacion/dialogos_configuracion_recuperacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parámetros de la recuperación de acceso por correo: SMTP, remitente, dominios y límites.
///
/// Solo administradores (el backend lo exige con ROLE_ADM). Un cambio rige en el
/// siguiente pedido de código, sin compilar ni reiniciar nada.
class ConfiguracionRecuperacionScreen extends ConsumerWidget {
  const ConfiguracionRecuperacionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parametros = ref.watch(configuracionRecuperacionProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, cajon) {
          final aire = Aire.de(cajon.maxWidth);
          final margen = aire.esChico ? Esp.m : Esp.xl;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Encabezado(aire: aire, margen: margen, parametros: parametros.valueOrNull),
              // Dos píxeles siempre reservados: así la página no salta en cada recarga.
              if (parametros.isLoading && parametros.hasValue)
                const LinearProgressIndicator(minHeight: 2)
              else
                const SizedBox(height: 2),
              Expanded(
                child: parametros.when(
                  loading: () => const EsqueletoLista(filas: 8, altoFila: 56),
                  error:
                      (e, _) => MensajeError(
                        error: e,
                        onReintentar: () => ref.invalidate(configuracionRecuperacionProvider),
                      ),
                  data:
                      (lista) =>
                          lista.isEmpty
                              ? const MensajeVacio(
                                icono: Icons.settings_outlined,
                                titulo: 'Todavía no hay parámetros',
                                detalle:
                                    'Se crean al correr el script 02 en la base de datos.',
                              )
                              : _Contenido(lista: lista, aire: aire, margen: margen),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Encabezado extends ConsumerWidget {
  const _Encabezado({required this.aire, required this.margen, required this.parametros});

  final Aire aire;
  final double margen;
  final List<ConfiguracionRecuperacionEntity>? parametros;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    // El remitente es el destino natural de la prueba: comprueba la casilla contra sí misma.
    final remitente =
        parametros?.where((p) => p.clave == 'remitente').map((p) => p.valor).firstOrNull;

    return Padding(
      padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recuperación de acceso',
                  style: tt.titleLarge?.copyWith(fontWeight: Peso.dato, letterSpacing: -0.4),
                ),
                if (!aire.esChico)
                  Text(
                    'Correo y límites de la recuperación de contraseña. '
                    'Los cambios rigen en el siguiente pedido de código.',
                    style: context.apagado(),
                  ),
              ],
            ),
          ),
          if (aire.esChico)
            IconButton(
              tooltip: 'Enviar correo de prueba',
              onPressed: parametros == null ? null : () => probarCorreo(context, remitente),
              icon: const Icon(Icons.send_outlined),
            )
          else
            FilledButton.tonalIcon(
              onPressed: parametros == null ? null : () => probarCorreo(context, remitente),
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('Enviar correo de prueba'),
            ),
          const SizedBox(width: Esp.xs),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(configuracionRecuperacionProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.lista, required this.aire, required this.margen});

  final List<ConfiguracionRecuperacionEntity> lista;
  final Aire aire;
  final double margen;

  @override
  Widget build(BuildContext context) {
    // Los grupos en el orden en que llegan (el SP ya ordena por grupo y orden).
    final grupos = <String, List<ConfiguracionRecuperacionEntity>>{};
    for (final p in lista) {
      grupos.putIfAbsent(p.grupo, () => []).add(p);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(margen, Esp.s, margen, Esp.xxl),
      child: Align(
        alignment: Alignment.topCenter,
        // Más ancho que esto, la fila separa tanto el nombre de su valor que ya no se leen juntos.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final grupo in grupos.entries) ...[
                _Seccion(grupo: grupo.key, parametros: grupo.value, aire: aire),
                const SizedBox(height: Esp.l),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Un grupo de parámetros: tabla con columnas cuando hay lugar, filas tocables en teléfono.
class _Seccion extends ConsumerWidget {
  const _Seccion({required this.grupo, required this.parametros, required this.aire});

  final String grupo;
  final List<ConfiguracionRecuperacionEntity> parametros;
  final Aire aire;

  (IconData, String?) get _cabecera => switch (grupo) {
    'Correo' => (
      Icons.mail_outline,
      'Servidor y casilla que envían los códigos, y qué correos cuentan como corporativos.',
    ),
    'Límites' => (Icons.tune, 'Cuánto vale un código y cuántas veces se puede pedir o intentar.'),
    _ => (Icons.settings_outlined, null),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final (icono, explicacion) = _cabecera;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: cs.primary),
                const SizedBox(width: Esp.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(grupo, style: context.tituloSeccion()),
                      if (explicacion != null) ...[
                        const SizedBox(height: Esp.xs),
                        Text(explicacion, style: context.apagado()),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Esp.m),
            if (!aire.esChico) const _CabeceraTabla(),
            for (var i = 0; i < parametros.length; i++) ...[
              if (i > 0 || !aire.esChico) const Divider(height: 1),
              aire.esChico
                  ? _FilaCompacta(parametro: parametros[i], onEditar: () => editarParametro(context, ref, parametros[i]))
                  : _FilaTabla(parametro: parametros[i], onEditar: () => editarParametro(context, ref, parametros[i])),
            ],
          ],
        ),
      ),
    );
  }
}

const double _anchoModificado = 110;
const double _anchoAccion = 104;

class _CabeceraTabla extends StatelessWidget {
  const _CabeceraTabla();

  @override
  Widget build(BuildContext context) {
    final estilo = context.apagado()?.copyWith(fontWeight: Peso.titulo);
    return Padding(
      padding: const EdgeInsets.only(bottom: Esp.s),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('Parámetro', style: estilo)),
          const SizedBox(width: Esp.m),
          Expanded(flex: 4, child: Text('Valor', style: estilo)),
          SizedBox(width: _anchoModificado, child: Text('Modificado', style: estilo)),
          const SizedBox(width: _anchoAccion),
        ],
      ),
    );
  }
}

class _FilaTabla extends StatelessWidget {
  const _FilaTabla({required this.parametro, required this.onEditar});

  final ConfiguracionRecuperacionEntity parametro;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parametro.nombre, style: const TextStyle(fontWeight: Peso.titulo)),
                Text(parametro.descripcion, style: context.apagado()),
              ],
            ),
          ),
          const SizedBox(width: Esp.m),
          Expanded(flex: 4, child: _Valor(parametro: parametro)),
          SizedBox(
            width: _anchoModificado,
            child: Text(fechaCorta(parametro.audFecha), style: context.apagado()),
          ),
          SizedBox(
            width: _anchoAccion,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEditar,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCompacta extends StatelessWidget {
  const _FilaCompacta({required this.parametro, required this.onEditar});

  final ConfiguracionRecuperacionEntity parametro;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEditar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Esp.m),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(parametro.nombre, style: const TextStyle(fontWeight: Peso.titulo)),
                  const SizedBox(height: Esp.xs),
                  _Valor(parametro: parametro),
                  const SizedBox(height: Esp.xs),
                  Text(parametro.descripcion, style: context.apagado()),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar ${parametro.nombre}',
              onPressed: onEditar,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

/// El valor tal como conviene leerlo. De la contraseña solo se dice si está cargada.
class _Valor extends StatelessWidget {
  const _Valor({required this.parametro});

  final ConfiguracionRecuperacionEntity parametro;

  @override
  Widget build(BuildContext context) {
    if (parametro.esSecreto) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Etiqueta(
          texto: parametro.configurado ? 'Configurada' : 'Sin configurar',
          tono: parametro.configurado ? TonoEtiqueta.exito : TonoEtiqueta.aviso,
        ),
      );
    }
    final valor = parametro.valor;
    if (valor == null || valor.isEmpty) return Text('--', style: context.apagado());
    return Text(parametro.tipo == 'dominios' ? valor.replaceAll(',', ', ') : valor);
  }
}
