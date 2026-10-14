{{flutter_js}}
{{flutter_build_config}}

// Sin service worker: guardaba main.dart.js y dejaba navegadores con la version
// anterior. Se quita el que quedo instalado y main.dart.js va con el build en la
// URL (?b=, no ?v=: el worker viejo trata ?v= como el archivo guardado).
(function () {
  window.bosqueBuild = {{flutter_service_worker_version}};
  var build = window.bosqueBuild;
  try {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.getRegistrations().then(function (rs) {
        rs.forEach(function (r) { r.unregister(); });
      }).catch(function () {});
    }
    if (window.caches) {
      caches.keys().then(function (ks) {
        ks.forEach(function (k) { if (k.indexOf('flutter') === 0) caches.delete(k); });
      }).catch(function () {});
    }
  } catch (e) {}
  if (build) {
    _flutter.buildConfig.builds.forEach(function (b) {
      if (b.mainJsPath) b.mainJsPath += '?b=' + build;
    });
  }
  _flutter.loader.load();
})();
