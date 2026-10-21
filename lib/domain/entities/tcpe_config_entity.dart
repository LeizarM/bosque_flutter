/// Una clave de la configuración del módulo (`p_list_tcpe_Config` L): límites,
/// valores por defecto y textos que se cambian en SQL sin recompilar.
class TcpeConfigEntity {
  final String clave;
  final String? valor;
  final String? descripcion;

  const TcpeConfigEntity({required this.clave, this.valor, this.descripcion});

  TcpeConfigEntity copyWith({String? clave, String? valor, String? descripcion}) => TcpeConfigEntity(
    clave: clave ?? this.clave,
    valor: valor ?? this.valor,
    descripcion: descripcion ?? this.descripcion,
  );
}

/// La configuración ya leída, con un respaldo por clave que solo se usa si el
/// servidor no respondió o no trae esa clave.
class TcpeConfiguracion {
  const TcpeConfiguracion._(this._valores, {this.deRespaldo = false});

  factory TcpeConfiguracion.desde(List<TcpeConfigEntity> filas) => TcpeConfiguracion._({
    for (final f in filas)
      if ((f.valor ?? '').trim().isNotEmpty) f.clave: f.valor!.trim(),
  });

  /// Sin configuración del servidor: todo sale de los respaldos.
  static const respaldo = TcpeConfiguracion._({}, deRespaldo: true);

  final Map<String, String> _valores;
  final bool deRespaldo;

  String? valor(String clave) => _valores[clave];

  int _entero(String clave, int defecto) => int.tryParse(_valores[clave] ?? '') ?? defecto;

  String _texto(String clave, String defecto) => _valores[clave] ?? defecto;

  double get notaAprobacionDefecto =>
      double.tryParse((_valores['notaAprobacionDefecto'] ?? '').replaceAll(',', '.')) ?? 51;
  int get maxExamenesPorLote => _entero('maxExamenesPorLote', 200);
  int get maxOpcionesPorPregunta => _entero('maxOpcionesPorPregunta', 30);
  int get duracionMaxMinutos => _entero('duracionMaxMinutos', 1440);
  int get diasVerResultado => _entero('diasVerResultado', 7);
  int get segundosLatido => _entero('segundosLatido', 15).clamp(5, 300);
  int get segundosInactivo => _entero('segundosInactivo', 40);
  int get segundosDesconectado => _entero('segundosDesconectado', 90);
  int get segundosRefrescoPanel => _entero('segundosRefrescoPanel', 5).clamp(2, 300);

  String get ayudaIngreso => _texto(
    'ayudaIngreso',
    'Usa el usuario y la clave temporal que te entregó el evaluador. Deja de funcionar cuando entregas tu examen.',
  );
  String get avisoSalidaExamen => _texto(
    'avisoSalidaExamen',
    'Tu examen está en curso. Solo puedes salir entregándolo; el tiempo sigue corriendo.',
  );
  String get msgPendienteRevision => _texto(
    'msgPendienteRevision',
    'Tu examen tiene respuestas escritas que revisará el evaluador. Vuelve a ingresar más tarde para ver tu nota.',
  );
  String get msgCredencialVencida => _texto('msgCredencialVencida', 'Estas credenciales ya no son válidas.');
  String get msgFueraDeVentana => _texto('msgFueraDeVentana', 'El examen no está disponible en este horario.');

  /// v11: el CI de un externo sin carnet o anónimo. No identifica a nadie: no
  /// cuenta como repetido y cada uno es una persona distinta.
  String get ciSinDocumento => _texto('ciSinDocumento', '0');
  String get ayudaCiRegistro => _texto('ayudaCiRegistro', 'Si no tienes carnet o la encuesta es anónima, escribe 0.');
  String get ayudaCiPersonas => _texto(
    'ayudaCiPersonas',
    'Escribe 0 si la persona no tiene carnet o es anónima: cada 0 es una persona distinta.',
  );

  /// El título que se muestra si la pregunta de la semana no tiene uno propio.
  String get tituloPreguntaSemana => _texto('tituloPreguntaSemana', 'Pregunta de la semana');

  /// Días que propone el plazo de una pregunta de la semana nueva (al menos uno).
  int get preguntaSemanaDias {
    final d = _entero('preguntaSemanaDias', 7);
    return d < 1 ? 1 : d;
  }
}
