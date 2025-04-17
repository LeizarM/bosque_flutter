class AppConstants {
  //static const String baseUrl = 'http://192.168.3.107:9223';
  static const String baseUrl = 'http://181.114.119.194:8800';
  static const String loginEndpoint = '/auth/login';
  static const String menuEndpoint = '/view/vistaDinamica';
  static const String articulosEndpoint = '/paginaXApp/articulosX';
  static const String articulosAlmacenEndpoint = '/paginaXApp/articulosXAlmacen';
  static const String entregasEndpoint = '/entregas/chofer-entrega';
  static const String marcarEntregaCompletada = '/entregas/registro-entrega-chofer';
  static const String inicioEntregaYFinEndpoint = '/entregas/registro-inicio-fin-entrega';
  
  // Constantes para el servicio de geocodificación de Nominatim
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String nominatimReverseEndpoint = '/reverse';
  static const String nominatimUserAgent = 'Bosque';
  
  // Puedes agregar más endpoints aquí cuando sea necesario
}