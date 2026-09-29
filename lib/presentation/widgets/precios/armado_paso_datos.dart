/// Paso 1 del asistente: tipo, titulo, observaciones y fletes por sucursal.
///
/// Reemplaza a `dlgNuevo`. Dos diferencias con aquel:
///
/// - **Los fletes arrancan con los de la ultima propuesta por familia.** El
///   legacy los ponia en cero, y un flete olvidado en cero abarataba toda la
///   sucursal sin ningun aviso. Se dice de donde salieron para que se revisen.
/// - **En una propuesta que ya existe los fletes se pueden cambiar**, y el
///   servidor recalcula en el mismo momento los precios de todas sus familias.
///   Cambiar solo el flete dejaria los precios calculados con el valor viejo.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/armado_propuesta_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/armado_propuesta_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_detalle_dialogos.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_detalle_piezas.dart';

/// El historico de propuestas recorta el titulo a 50 caracteres y la
/// observacion a 150: se avisa, igual que en la edicion de la cabecera.
const int _largoHistoricoTitulo = 50;
const int _largoHistoricoObs = 150;

class ArmadoPasoDatos extends ConsumerStatefulWidget {
  const ArmadoPasoDatos({super.key, required this.aire});

  final Aire aire;

  @override
  ConsumerState<ArmadoPasoDatos> createState() => _ArmadoPasoDatosState();
}

class _ArmadoPasoDatosState extends ConsumerState<ArmadoPasoDatos> {
  late final TextEditingController _titulo;
  late final TextEditingController _obs;

  /// Un campo por sucursal. Se crean a medida que llegan los fletes y se
  /// reescriben solo cuando cambian desde afuera (carga o descarte): pisarlos
  /// en cada dibujo moveria el cursor mientras se escribe.
  final Map<BigInt, TextEditingController> _fletes = {};

  @override
  void initState() {
    super.initState();
    final estado = ref.read(armadoProvider);
    _titulo = TextEditingController(text: estado.titulo);
    _obs = TextEditingController(text: estado.obs);
  }

  @override
  void dispose() {
    _titulo.dispose();
    _obs.dispose();
    for (final c in _fletes.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _campoFlete(FleteArmadoEntity flete) =>
      _fletes.putIfAbsent(
        flete.codSucursal,
        () => TextEditingController(text: fmtMonto.format(flete.valor)),
      );

  /// Pone los campos al dia cuando los fletes cambian desde afuera: llegan del
  /// servidor o se descartan los cambios. Si el campo ya dice lo mismo que el
  /// estado -porque el cambio salio de tipear en el- no se toca, o el cursor
  /// saltaria al final en cada tecla.
  void _sincronizarCampos(List<FleteArmadoEntity> fletes) {
    for (final f in fletes) {
      final campo = _fletes[f.codSucursal];
      if (campo == null) continue; // se crea con su valor al dibujarse
      final escrito =
          campo.text.trim().isEmpty ? 0.0 : importeDesdeTexto(campo.text);
      if (f.valor < 0 && escrito == null) continue; // lo esta escribiendo
      if (escrito != null && (escrito - f.valor).abs() < 0.005) continue;
      campo.text = fmtMonto.format(f.valor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(armadoProvider);
    final notifier = ref.read(armadoProvider.notifier);

    ref.listen<List<FleteArmadoEntity>>(
      armadoProvider.select((e) => e.fletes),
      (_, fletes) => _sincronizarCampos(fletes),
    );

    final margen = widget.aire.esChico ? Esp.m : Esp.xl;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!estado.existe) ...[
                _BloqueTipo(estado: estado, onTipo: notifier.fijarTipo),
                const SizedBox(height: Esp.l),
              ],
              _bloqueDatos(estado, notifier),
              if (estado.esPorFamilia) ...[
                const SizedBox(height: Esp.l),
                _bloqueFletes(estado, notifier),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bloqueDatos(EstadoArmado estado, ArmadoNotifier notifier) {
    if (estado.existe) {
      return BloquePanel(
        titulo: 'Datos de la propuesta',
        icono: Icons.description_outlined,
        subtitulo:
            'El tipo no se puede cambiar: una propuesta por familias y una '
            'por artículos escriben en tablas distintas.',
        hijo: Column(
          children: [
            FilaDeDato(
              rotulo: 'Número',
              valor: 'N.º ${estado.idPropuesta}',
              esNumero: false,
              fuerte: true,
            ),
            FilaDeDato(
              rotulo: 'Tipo',
              valor: estado.tipo.etiqueta,
              esNumero: false,
            ),
            FilaDeDato(
              rotulo: 'Título',
              valor: estado.titulo.isEmpty ? 'Sin título' : estado.titulo,
              esNumero: false,
            ),
          ],
        ),
      );
    }

    final titulo = estado.titulo.trim();
    final obs = estado.obs.trim();

    return BloquePanel(
      titulo: 'Datos de la propuesta',
      icono: Icons.description_outlined,
      subtitulo:
          'Los dos campos son obligatorios, como en el sistema anterior.',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titulo,
            maxLength: largoMaximoTitulo,
            textCapitalization: TextCapitalization.characters,
            onChanged: notifier.fijarTitulo,
            decoration: const InputDecoration(
              labelText: 'Título',
              hintText: 'Por ejemplo: NUEVO PRECIO COUCHE',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (titulo.length > _largoHistoricoTitulo)
            const NotaDelDato(
              texto:
                  'El título supera los 50 caracteres. Si algún día se '
                  'archiva la propuesta, el histórico lo va a recortar.',
              tono: TonoNota.aviso,
            ),
          const SizedBox(height: Esp.m),
          TextField(
            controller: _obs,
            maxLength: largoMaximoObs,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: notifier.fijarObs,
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              hintText: 'Motivo del cambio de precios',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (obs.length > _largoHistoricoObs)
            const NotaDelDato(
              texto:
                  'La observación supera los 150 caracteres y el histórico '
                  'la recorta a ese largo.',
              tono: TonoNota.aviso,
            ),
        ],
      ),
    );
  }

  Widget _bloqueFletes(EstadoArmado estado, ArmadoNotifier notifier) {
    final String subtitulo;
    if (estado.existe) {
      subtitulo =
          'En dólares por tonelada. Cambiar un flete recalcula los precios '
          'de todas las familias de la propuesta.';
    } else if (estado.referenciaFletes != null) {
      subtitulo =
          'En dólares por tonelada. Se copiaron los de la propuesta N.º '
          '${estado.referenciaFletes}: revíselos, porque el flete se suma a '
          'todos los precios de la sucursal.';
    } else {
      subtitulo =
          'En dólares por tonelada. Escriba el de cada sucursal; puede ser 0.';
    }

    final Widget contenido;
    if (estado.cargandoFletes) {
      contenido = const Padding(
        padding: EdgeInsets.symmetric(vertical: Esp.l),
        child: LinearProgressIndicator(),
      );
    } else if (estado.errorFletes != null) {
      contenido = MensajeError(
        error: estado.errorFletes,
        compacto: true,
        onReintentar: notifier.recargarFletes,
      );
    } else if (estado.fletes.isEmpty) {
      contenido = NotaDelDato(
        texto:
            estado.existe
                ? 'Esta propuesta no tiene fletes guardados: sus precios se '
                    'calcularon sin flete.'
                : 'No llegó ninguna sucursal para cargar fletes.',
        tono: TonoNota.aviso,
      );
    } else {
      contenido = Column(
        children: [
          for (final flete in estado.fletes)
            Padding(
              padding: const EdgeInsets.only(bottom: Esp.s),
              child: _FilaFlete(
                flete: flete,
                controlador: _campoFlete(flete),
                habilitado: !estado.ocupado,
                onValor: (v) => notifier.fijarFlete(flete.codSucursal, v ?? -1),
              ),
            ),
        ],
      );
    }

    return BloquePanel(
      titulo: 'Flete por sucursal',
      icono: Icons.local_shipping_outlined,
      subtitulo: subtitulo,
      acciones: [
        if (estado.existe && estado.fletesModificados) ...[
          TextButton(
            onPressed:
                estado.ocupado ? null : notifier.descartarCambiosDeFletes,
            child: const Text('Descartar'),
          ),
          BotonAccion(
            etiqueta: 'Guardar y recalcular',
            etiquetaOcupado: 'Recalculando',
            icono: Icons.calculate_outlined,
            ocupado: estado.ocupado,
            onPressed:
                estado.fletes.any((f) => f.valor < 0) ? null : _guardarFletes,
          ),
        ],
      ],
      hijo: contenido,
    );
  }

  Future<void> _guardarFletes() async {
    final seguir = await confirmar(
      context,
      titulo: 'Recalcular la propuesta',
      detalle:
          'Se guardan los fletes nuevos y se recalculan los precios de todas '
          'las familias de la propuesta con su costo guardado. Si alguna '
          'familia queda con precios fuera de orden, no se guarda nada.',
      textoConfirmar: 'Guardar y recalcular',
    );
    if (!seguir || !mounted) return;

    final r = await ref.read(armadoProvider.notifier).guardarFletes();
    if (!mounted) return;
    if (!r.salio) {
      avisar(context, r.error!, esError: true);
      return;
    }
    final resultado = r.valor!;
    avisar(
      context,
      resultado.familiasRecalculadas == 0
          ? 'Fletes guardados.'
          : 'Fletes guardados. Se recalcularon '
              '${resultado.familiasRecalculadas} '
              '${resultado.familiasRecalculadas == 1 ? 'familia' : 'familias'}.',
    );
  }
}

/// El selector de tipo, con lo que significa cada uno: el nombre solo no
/// alcanza para saber cual elegir.
class _BloqueTipo extends StatelessWidget {
  const _BloqueTipo({required this.estado, required this.onTipo});

  final EstadoArmado estado;
  final ValueChanged<TipoArmado> onTipo;

  @override
  Widget build(BuildContext context) {
    final explicacion = switch (estado.tipo) {
      TipoArmado.porFamilia =>
        'Se reprecian familias enteras: por cada una se escribe el costo por '
            'tonelada y el sistema calcula el precio de cada lista con su '
            'porcentaje, el IVA, el IT y el flete de la sucursal.',
      TipoArmado.porArticulo =>
        'Se eligen artículos puntuales, típicamente mercadería nueva que hay '
            'que dar de alta con el precio vigente de su familia. No cambia '
            'ningún precio por tonelada.',
    };

    return BloquePanel(
      titulo: 'Tipo de propuesta',
      icono: Icons.category_outlined,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<TipoArmado>(
            segments: const [
              ButtonSegment(
                value: TipoArmado.porFamilia,
                icon: Icon(Icons.price_change_outlined),
                label: Text('Por familias'),
              ),
              ButtonSegment(
                value: TipoArmado.porArticulo,
                icon: Icon(Icons.inventory_2_outlined),
                label: Text('Por artículos'),
              ),
            ],
            selected: {estado.tipo},
            onSelectionChanged: (s) => onTipo(s.first),
          ),
          const SizedBox(height: Esp.s),
          Text(explicacion, style: context.apagado()),
        ],
      ),
    );
  }
}

/// Una sucursal y su flete.
class _FilaFlete extends StatelessWidget {
  const _FilaFlete({
    required this.flete,
    required this.controlador,
    required this.habilitado,
    required this.onValor,
  });

  final FleteArmadoEntity flete;
  final TextEditingController controlador;
  final bool habilitado;

  /// Null cuando el texto no es un importe: el estado lo guarda como -1 para
  /// que el paso no se pueda cerrar con un flete ilegible.
  final ValueChanged<double?> onValor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            flete.nombreSucursal.isEmpty
                ? 'Sucursal ${flete.codSucursal}'
                : flete.nombreSucursal,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: Esp.m),
        SizedBox(
          width: 160,
          child: TextField(
            controller: controlador,
            enabled: habilitado,
            textAlign: TextAlign.end,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: context.numero(),
            onChanged:
                (t) => onValor(t.trim().isEmpty ? 0 : importeDesdeTexto(t)),
            decoration: const InputDecoration(
              prefixText: 'USD ',
              suffixText: '/t',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
