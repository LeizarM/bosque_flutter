/// El formulario de una verificacion: «Cheque a regularizar» (alta, desde el
/// modal de pendientes) y «Editar verificación». Muestra el cheque (solo lectura)
/// y deja elegir el banco en el que se comprobo el deposito, el dia y una
/// observacion de hasta 50 caracteres.
///
/// El estado no se elige aqui: el servidor lo fija (`Y` en el alta) o lo conserva
/// (en la edicion; una verificacion anulada que se edita sigue anulada). El
/// cheque tampoco cambia al editar. Todas las reglas las vuelve a comprobar el
/// servidor y su mensaje se muestra completo junto al formulario.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/bancos_provider.dart';
import 'package:bosque_flutter/core/state/cheques_provider.dart'
    show mensajeDeErrorCheque;
import 'package:bosque_flutter/core/state/verificaciones_provider.dart';
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/datos_cheque_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_preparada_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_registro_entity.dart';
import 'package:bosque_flutter/domain/utils/reglas_verificacion.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/piezas_verificacion.dart';

/// Abre «Cheque a regularizar» con el cheque que acaba de preparar el servidor.
/// Devuelve true si se guardo.
Future<bool?> abrirVerificacionNueva(
  BuildContext context,
  VerificacionPreparadaEntity preparada,
) => _abrir(
  context,
  _Origen(
    esAlta: true,
    codvd: BigInt.zero,
    cheque: preparada.cheque.cheque,
    codBancoInicial: preparada.cheque.codBancoCheque,
    fechaInicial: preparada.fechaBanco,
    observacionInicial: '',
    anulada: false,
  ),
);

/// Abre «Editar verificación» para [fila]. Devuelve true si se guardo.
Future<bool?> abrirVerificacionEditar(
  BuildContext context,
  VerificacionFilaEntity fila,
) => _abrir(
  context,
  _Origen(
    esAlta: false,
    codvd: fila.codvd,
    cheque: fila.cheque,
    codBancoInicial: fila.verificacion.codBanco,
    fechaInicial: fila.verificacion.fechaBanco,
    observacionInicial: (fila.verificacion.observacion ?? '').trim(),
    anulada: fila.estaAnulada,
  ),
);

Future<bool?> _abrir(BuildContext context, _Origen origen) {
  // El error de una escritura anterior no debe aparecer en un dialogo nuevo.
  ProviderScope.containerOf(
    context,
  ).read(operacionesVerificacionesProvider.notifier).limpiarError();
  return abrirPanelCheque<bool>(
    context,
    anchoMaximo: 600,
    contenido: (_) => _DialogoVerificacion(origen: origen),
  );
}

/// Lo que el formulario necesita saber de donde viene.
class _Origen {
  const _Origen({
    required this.esAlta,
    required this.codvd,
    required this.cheque,
    required this.codBancoInicial,
    required this.fechaInicial,
    required this.observacionInicial,
    required this.anulada,
  });

  final bool esAlta;
  final BigInt codvd;
  final DatosChequeVerificacionEntity cheque;
  final int? codBancoInicial;
  final DateTime? fechaInicial;
  final String observacionInicial;

  /// Se esta editando una verificacion anulada: seguira anulada.
  final bool anulada;
}

class _DialogoVerificacion extends ConsumerStatefulWidget {
  const _DialogoVerificacion({required this.origen});

  final _Origen origen;

  @override
  ConsumerState<_DialogoVerificacion> createState() =>
      _DialogoVerificacionState();
}

class _DialogoVerificacionState extends ConsumerState<_DialogoVerificacion> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _observacion = TextEditingController(
    text: widget.origen.observacionInicial,
  );
  late int? _banco = widget.origen.codBancoInicial;
  late DateTime? _fecha = widget.origen.fechaInicial;
  bool _intentado = false;

  _Origen get _o => widget.origen;

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _intentado = true);
    if (!(_form.currentState?.validate() ?? false)) {
      avisar(context, 'Revisa los campos marcados en rojo.', esError: true);
      return;
    }
    final pedido = VerificacionRegistroEntity(
      codvd: _o.codvd,
      codCheque: _o.cheque.codCheque,
      codBanco: _banco!,
      fechaBanco: _fecha!,
      observacion: _observacion.text.trim(),
    );
    final id = await ref
        .read(operacionesVerificacionesProvider.notifier)
        .registrar(pedido);
    // El error, si lo hubo, queda en el estado y se dibuja en el dialogo.
    if (id == null || !mounted) return;
    avisar(
      context,
      _o.esAlta ? 'Verificación registrada.' : 'Verificación actualizada.',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesVerificacionesProvider.select((s) => s.ocupado),
    );
    final errorServidor = ref.watch(
      operacionesVerificacionesProvider.select((s) => s.error),
    );
    final bancos = ref.watch(listaBancosProvider);
    final c = _o.cheque;

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorServidor != null) ...[
          ErrorServidorCheque(errorServidor),
          const SizedBox(height: Esp.l),
        ],
        if (_o.anulada) ...[
          const _NotaAnulada(),
          const SizedBox(height: Esp.l),
        ],
        _FichaCheque(cheque: c),
        const SizedBox(height: Esp.l),
        _CampoBanco(
          bancos: bancos,
          valor: _banco,
          onCambio: (v) => setState(() => _banco = v),
          onReintentar: () => ref.invalidate(listaBancosProvider),
        ),
        const SizedBox(height: Esp.l),
        CampoFechaCheque(
          etiqueta: 'Fecha de verificación',
          valor: _fecha,
          onCambio: (f) => setState(() => _fecha = f),
          ayuda: 'El día en que comprobaste el depósito en el banco.',
        ),
        const SizedBox(height: Esp.l),
        TextFormField(
          key: const ValueKey('campo-observacion-verificacion'),
          controller: _observacion,
          maxLength: ReglasVerificacion.largoMaximoObservacion,
          // Una sola linea: el servidor rechaza un salto de linea y 50
          // caracteres caben en una linea.
          maxLines: 1,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Observación',
            helperText:
                'Opcional. Letras sin tilde ni ñ, números, espacios, '
                'apóstrofe, coma y punto.',
            helperMaxLines: 3,
            errorMaxLines: 4,
            border: OutlineInputBorder(),
          ),
          validator: (t) => ReglasVerificacion.errorObservacion(t?.trim()),
        ),
      ],
    );

    return Form(
      key: _form,
      autovalidateMode:
          _intentado ? AutovalidateMode.always : AutovalidateMode.disabled,
      child: MarcoPanelCheque(
        titulo: _o.esAlta ? 'Cheque a regularizar' : 'Editar verificación',
        subtitulo:
            'Cheque ${textoODash(c.nroCheque)} · ${textoODash(c.datoBancoCheque)}',
        onCerrar: ocupado ? () {} : () => Navigator.of(context).pop(),
        cuerpo: cuerpo,
        acciones: [
          TextButton(
            onPressed: ocupado ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          BotonGuardarCheque(
            etiqueta: _o.esAlta ? 'Guardar verificación' : 'Guardar cambios',
            icono: Icons.verified_outlined,
            ocupado: ocupado,
            onPressed: ocupado ? null : _guardar,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS
// ═══════════════════════════════════════════════════════════════════════════

/// El cheque que se verifica, de solo lectura: numero, monto, banco, fecha de
/// cobranza y estado. Un recuadro tintado, para que no se lea como un campo.
class _FichaCheque extends StatelessWidget {
  const _FichaCheque({required this.cheque});

  final DatosChequeVerificacionEntity cheque;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const ValueKey('ficha-cheque'),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          cs.primary.withValues(alpha: 0.06),
          cs.surfaceContainerLow,
        ),
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Wrap(
          spacing: Esp.xl,
          runSpacing: Esp.m,
          children: [
            _Dato(
              'Nro. de cheque',
              Text(
                textoODash(cheque.nroCheque),
                style: context.cifraCheque(fuerte: true, tam: 15),
              ),
            ),
            _Dato(
              'Monto',
              ImporteVerificacion(
                cheque: cheque,
                tam: 15,
                alineacion: Alignment.centerLeft,
              ),
            ),
            _Dato(
              'Fecha de cobranza',
              Text(
                textoFecha(cheque.fechaCobrarCheque),
                style: context.cifraCheque(tam: 14),
              ),
            ),
            _Dato(
              'Estado del cheque',
              EtiquetaEstadoCheque(
                estado: cheque.chequeCerrado ? 'CER' : 'PEN',
                texto: cheque.datoEstadoCheque,
              ),
            ),
            _Dato(
              'Banco del cheque',
              Text(
                textoODash(cheque.datoBancoCheque),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              ancho: 260,
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor, {this.ancho});

  final String etiqueta;
  final Widget valor;
  final double? ancho;

  @override
  Widget build(BuildContext context) {
    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta, style: context.apagado()),
        const SizedBox(height: 2),
        valor,
      ],
    );
    return ancho == null ? contenido : ConstrainedBox(
      constraints: BoxConstraints(maxWidth: ancho!),
      child: contenido,
    );
  }
}

/// Una verificacion anulada que se edita sigue anulada: se dice antes de que el
/// usuario piense que editarla la reactiva.
class _NotaAnulada extends StatelessWidget {
  const _NotaAnulada();

  @override
  Widget build(BuildContext context) {
    final letra = ChequesColores.texto(context, SemanticaCheque.peligro);
    return DecoratedBox(
      key: const ValueKey('nota-anulada'),
      decoration: BoxDecoration(
        color: ChequesColores.fondo(context, SemanticaCheque.peligro),
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.block, size: 18, color: letra),
            const SizedBox(width: Esp.s),
            Expanded(
              child: Text(
                'Esta verificación está anulada. Puedes corregir sus datos, '
                'pero seguirá anulada.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: letra),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El combo del banco de verificacion. Los bancos llegan del servidor: mientras
/// cargan el campo lo dice, y si fallan se muestra el motivo con «Reintentar» en
/// vez de dejar un combo vacio que no explica nada.
class _CampoBanco extends StatelessWidget {
  const _CampoBanco({
    required this.bancos,
    required this.valor,
    required this.onCambio,
    required this.onReintentar,
  });

  final AsyncValue<List<BancoEntity>> bancos;
  final int? valor;
  final ValueChanged<int?> onCambio;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return bancos.when(
      loading:
          () => const InputDecorator(
            decoration: InputDecoration(
              labelText: 'Banco de la verificación',
              border: OutlineInputBorder(),
              isDense: true,
              suffixIcon: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            child: Text('Cargando bancos…'),
          ),
      error:
          (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ErrorServidorCheque(
                'No se pudieron cargar los bancos: ${mensajeDeErrorCheque(e)}',
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onReintentar,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
          ),
      data: (lista) {
        // Un banco que ya no esta en la lista no se puede dejar elegido.
        final elegido = lista.any((b) => b.codBanco == valor) ? valor : null;
        return DropdownButtonFormField<int>(
          key: ValueKey('banco-verificacion-$elegido-${lista.length}'),
          value: elegido,
          isExpanded: true,
          items: [
            for (final b in lista)
              DropdownMenuItem(
                value: b.codBanco,
                child: Text(b.nombre, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: lista.isEmpty ? null : onCambio,
          decoration: const InputDecoration(
            labelText: 'Banco de la verificación',
            helperText: 'El banco en el que se comprobó el depósito.',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          validator: (v) => v == null ? 'Elige el banco de la verificación.' : null,
        );
      },
    );
  }
}
