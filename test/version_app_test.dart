import 'package:bosque_flutter/core/network/web_version_checker.dart';
import 'package:bosque_flutter/core/utils/version_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('versionAppVigente: la app entra si es igual o mayor a la mínima', () {
    test('igual, mayor y menor', () {
      expect(versionAppVigente('1.0.2', actual: '1.0.2'), isTrue);
      expect(versionAppVigente('1.0.1', actual: '1.0.2'), isTrue);
      expect(versionAppVigente('1.0.3', actual: '1.0.2'), isFalse);
      expect(versionAppVigente('2.0', actual: '1.9.9'), isFalse);
      expect(versionAppVigente('1.0.10', actual: '1.0.9'), isFalse);
      expect(versionAppVigente('1', actual: '1.0.0'), isTrue);
    });

    test('una mínima vacía o ilegible no deja entrar, como antes', () {
      expect(versionAppVigente(null, actual: '1.0.2'), isFalse);
      expect(versionAppVigente('', actual: '1.0.2'), isFalse);
      expect(versionAppVigente('1.0.x', actual: '1.0.2'), isFalse);
    });
  });

  group('buildPublicadoDe: el build del index.html publicado', () {
    test('lo lee del bootstrap en línea', () {
      const html =
          '<script>(function () {\n  window.bosqueBuild = "3941547892";\n'
          '  var build = window.bosqueBuild;';
      expect(buildPublicadoDe(html), '3941547892');
    });

    test('un index sin el bootstrap nuevo no trae build', () {
      expect(
        buildPublicadoDe('<script src="flutter_bootstrap.js"></script>'),
        isNull,
      );
    });
  });
}
