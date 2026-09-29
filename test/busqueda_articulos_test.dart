import 'package:bosque_flutter/core/utils/busqueda_articulos.dart';
import 'package:flutter_test/flutter_test.dart';

/// La búsqueda del catálogo de Ventas: por palabras, en cualquier orden, con
/// los números comparados sin ceros a la izquierda.
void main() {
  const suzano =
      'BOBINA BOND BLANCO 075G 058X100CM 1ROLLO  SUZANO BBB075058100FZO';

  test('"bond 75" encuentra 075G (el caso que no andaba)', () {
    expect(BusquedaArticulos('bond 75').coincide(suzano), isTrue);
  });

  test('el orden de las palabras no importa', () {
    expect(BusquedaArticulos('75 suzano bond').coincide(suzano), isTrue);
  });

  test('todas las palabras tienen que estar', () {
    expect(BusquedaArticulos('bond 90').coincide(suzano), isFalse);
    expect(BusquedaArticulos('bond cartulina').coincide(suzano), isFalse);
  });

  test('un número no encuentra otro gramaje que lo contenga en el medio', () {
    expect(BusquedaArticulos('75').coincide('PAPEL 1750G'), isFalse);
    expect(BusquedaArticulos('75').coincide('PAPEL 750G'), isTrue);
    expect(BusquedaArticulos('075').coincide('PAPEL 75G'), isTrue);
  });

  test('parte de una palabra y letras+números también sirven', () {
    expect(BusquedaArticulos('bobi 75g').coincide(suzano), isTrue);
    expect(BusquedaArticulos('058x100').coincide(suzano), isTrue);
  });

  test('código de artículo y tildes', () {
    expect(BusquedaArticulos('bbb0750').coincide(suzano), isTrue);
    expect(BusquedaArticulos('cartulina').coincide('CARTULÍNA DÚPLEX'), isTrue);
  });

  test('consulta vacía o solo espacios', () {
    expect(BusquedaArticulos('   ').vacia, isTrue);
  });

  test('tramos a resaltar: la palabra y el número completo', () {
    final t = BusquedaArticulos('bond 75').tramos(suzano);
    expect(suzano.substring(t[0].$1, t[0].$2), 'BOND');
    expect(suzano.substring(t[1].$1, t[1].$2), '075');
  });

  test('en un número largo (código) se marca sólo lo buscado', () {
    const codigo = 'BBB075058100FZO';
    final t = BusquedaArticulos('75').tramos(codigo);
    expect(codigo.substring(t.single.$1, t.single.$2), '075');
  });

  test('tramos superpuestos se unen', () {
    final t = BusquedaArticulos('bla blanco').tramos('BLANCO');
    expect(t, [(0, 6)]);
  });
}
