/// Catalogo de grupos de familia de SAP y su equivalencia de codigo en cada
/// empresa (tabla tpr_grupoFamiliaSap, modulo de precios).
///
/// OJO con los codigos: [codGrpFamSap], [codGrpFamSapEpp] y
/// [codGrpFamSapProdPap] son varchar(20) en la tabla, NO numericos. El
/// procedimiento legacy los declaraba INT y el modelo viejo los tenia como int,
/// lo que rompia o convertia mal cualquier codigo alfanumerico. Aqui viajan
/// siempre como String: no los parsees a numero para ordenar ni para comparar.
///
/// Un grupo puede tener cargado el codigo de una sola empresa, de dos o de las
/// tres: la cadena vacia significa "no configurado para esa empresa".
class GrupoFamiliaSapEntity {
  /// PK. bigint IDENTITY: en un alta vale BigInt.zero porque lo genera el motor.
  final BigInt idGrpFamiliaSap;

  /// Codigo del grupo en el SAP de IMPEXPAP. varchar(20), alfanumerico.
  final String codGrpFamSap;

  /// Codigo del grupo en el SAP de ESPPAPEL. varchar(20), mismo criterio.
  final String codGrpFamSapEpp;

  /// Codigo del grupo en el SAP de PRODUCTIVA PAPEL. varchar(20).
  ///
  /// Trampa del backend: el procedimiento lo graba con
  /// ISNULL(@codGrpFamSapProdPap, codGrpFamSapProdPap) para que el JSF viejo,
  /// que no manda el parametro, no borre el valor cargado. Desde esta app el
  /// campo se envia siempre, asi que lo que se ve en pantalla es lo que queda:
  /// dejarlo vacio limpia la columna.
  final String codGrpFamSapProdPap;

  /// Nombre del grupo de familia. varchar(150).
  final String grpFam;

  /// Alias o nombre corto. varchar(250) en la tabla; el proc declara 300.
  final String alias;

  /// Usuario de auditoria.
  final BigInt audUsuario;

  /// Fecha de auditoria. La escribe el procedimiento con GETDATE(), por eso es
  /// de solo lectura y puede llegar en null en registros antiguos.
  final DateTime? audFecha;

  const GrupoFamiliaSapEntity({
    required this.idGrpFamiliaSap,
    required this.codGrpFamSap,
    required this.codGrpFamSapEpp,
    required this.codGrpFamSapProdPap,
    required this.grpFam,
    required this.alias,
    required this.audUsuario,
    this.audFecha,
  });

  /// Registro todavia no guardado: el IDENTITY aun no asigno la PK.
  bool get esNuevo => idGrpFamiliaSap == BigInt.zero;

  /// Banderas de configuracion por empresa, para pintar chips o iconos.
  bool get tieneCodigoIpx => codGrpFamSap.trim().isNotEmpty;
  bool get tieneCodigoEpp => codGrpFamSapEpp.trim().isNotEmpty;
  bool get tieneCodigoProdPap => codGrpFamSapProdPap.trim().isNotEmpty;

  /// Cuantas de las tres empresas tienen codigo cargado.
  int get empresasConfiguradas =>
      (tieneCodigoIpx ? 1 : 0) +
      (tieneCodigoEpp ? 1 : 0) +
      (tieneCodigoProdPap ? 1 : 0);

  /// Grupo mapeado en las tres empresas.
  bool get mapeoCompleto => empresasConfiguradas == 3;

  /// Grupo sin ningun codigo SAP: queda huerfano y no cruza con articulos.
  bool get sinMapeo => empresasConfiguradas == 0;

  /// Con que se nombra el grupo en combos, titulos y tarjetas: el nombre
  /// (grpFam), y el alias solo si el grupo no tiene nombre.
  ///
  /// **Por que no el alias.** El alias NO es unico: en BOSQUE2PRUEBA seis
  /// grupos distintos -Bobina Bond Blanco, Bond Hueso, Bond Reciclado, Kraft,
  /// Periodico y Termico- tienen el alias "BOBINA", y dos pares comparten
  /// "CARTULINA REVERSO BLANCO" y "CARTULINA REVERSO CAFE". Mostrando el
  /// alias, el combo de «Porcentajes» listaba seis "BOBINA" iguales y no habia
  /// forma de saber cual era cual. El nombre si es unico.
  String get nombreVisible {
    final g = grpFam.trim();
    if (g.isNotEmpty) return g;
    final a = alias.trim();
    return a.isNotEmpty ? a : 'Sin nombre';
  }

  /// El alias, cuando dice algo distinto del nombre: para mostrarlo debajo.
  String? get aliasDistinto {
    final a = alias.trim();
    if (a.isEmpty || a.toLowerCase() == grpFam.trim().toLowerCase()) {
      return null;
    }
    return a;
  }

  /// Codigos cargados en una sola linea. Omite las empresas sin configurar.
  String get codigosResumen {
    final partes = <String>[
      if (tieneCodigoIpx) 'IPX: ${codGrpFamSap.trim()}',
      if (tieneCodigoEpp) 'EPP: ${codGrpFamSapEpp.trim()}',
      if (tieneCodigoProdPap) 'PRP: ${codGrpFamSapProdPap.trim()}',
    ];
    return partes.isEmpty ? 'Sin códigos SAP' : partes.join(' | ');
  }

  /// Estado legible del mapeo, para la columna de la tabla web.
  String get estadoMapeo {
    if (sinMapeo) return 'Sin mapear';
    if (mapeoCompleto) return 'Mapeo completo';
    return 'Mapeo parcial ($empresasConfiguradas de 3)';
  }

  /// Fecha de auditoria en dd/MM/yyyy. Vacia cuando el registro no la tiene.
  String get audFechaLegible {
    final f = audFecha;
    if (f == null) return '';
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    return '$dia/$mes/${f.year}';
  }

  GrupoFamiliaSapEntity copyWith({
    BigInt? idGrpFamiliaSap,
    String? codGrpFamSap,
    String? codGrpFamSapEpp,
    String? codGrpFamSapProdPap,
    String? grpFam,
    String? alias,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => GrupoFamiliaSapEntity(
    idGrpFamiliaSap: idGrpFamiliaSap ?? this.idGrpFamiliaSap,
    codGrpFamSap: codGrpFamSap ?? this.codGrpFamSap,
    codGrpFamSapEpp: codGrpFamSapEpp ?? this.codGrpFamSapEpp,
    codGrpFamSapProdPap: codGrpFamSapProdPap ?? this.codGrpFamSapProdPap,
    grpFam: grpFam ?? this.grpFam,
    alias: alias ?? this.alias,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
