/// Conversores tolerantes a null, compartidos por los modelos de Permisos RR.HH.
///
/// El backend devuelve wrappers (`Long`/`Integer`) en las columnas que admiten
/// NULL, asi que aca se colapsan a 0 o a cadena vacia. Un `?? 0` de mas no
/// molesta; uno de menos revienta en runtime con un tipo raro.
///
/// Prefijo `pr` y archivo propio, igual que el `rs` de `rol_sabados_json.dart`:
/// el patron del repo es «cada modulo trae sus conversores», no «importar los
/// del vecino» —un import de sabados desde permisos leeria como un error—.
library;

int prInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
String prStr(dynamic v) => v?.toString() ?? '';
DateTime? prDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

/// `yyyy-MM-dd` para las columnas `date` (`trh_vacacionAsignada.fecha`,
/// `trh_abonoDias.fecha`) y para los filtros de fecha.
///
/// **Sin `toIso8601String()` y sin `intl`**: aquel manda tambien la hora en
/// horario local, y del otro lado la columna es `date` — un
/// `2026-08-31T00:00:00` desde un telefono con el reloj corrido se guarda como
/// el 30 de agosto, o sea otro aniversario.
String prDia(DateTime f) =>
    '${f.year.toString().padLeft(4, '0')}-'
    '${f.month.toString().padLeft(2, '0')}-'
    '${f.day.toString().padLeft(2, '0')}';

/// `yyyy-MM-ddTHH:mm:ss` para las columnas `datetime` (`trh_permiso.desde` y
/// `.hasta`, que es donde escribe la vacacion colectiva).
///
/// **Aca la hora SI importa**: el calculo de dias del legacy avanza de 30 en 30
/// minutos entre las dos, asi que perderla convierte medio dia en cero. Se manda
/// sin sufijo de zona a proposito: el servidor guarda hora local de Bolivia y una
/// `Z` de mas correria todo cuatro horas.
String prInstante(DateTime f) =>
    '${prDia(f)}T'
    '${f.hour.toString().padLeft(2, '0')}:'
    '${f.minute.toString().padLeft(2, '0')}:'
    '${f.second.toString().padLeft(2, '0')}';

/// Para los `float` de SQL. **Es la defensa central de este modulo**: SQL Server
/// manda un `float` sin decimales como entero y Jackson lo serializa como `12` y
/// no como `12.0`, asi que un `as double` revienta en runtime con «type 'int' is
/// not a subtype of type 'double'» justo para el empleado que tiene los dias
/// redondos, o sea la mayoria. Tampoco sirve [prInt]: los dias vienen en
/// fracciones —0.4375, 0.5, 0.625— y truncarlos convertiria medio dia de
/// vacacion en cero.
double prNum(dynamic v) => v is num ? v.toDouble() : 0;
