// Configuración de Cloudinary
// IMPORTANTE: En producción, estas credenciales deben almacenarse de forma segura
// usando variables de entorno o un servicio de gestión de secretos.

class CloudinaryConfig {
  // Credenciales de Cloudinary
  static const String cloudName = 'dsfazlofc';
  static const String apiKey = '375549546746736';
  static const String apiSecret = '2pvXZo07QeUjClYKqHgFBoMjoVI';

  // URL base de la API de Cloudinary
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';

  static String get deleteUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/delete';

  // Configuración de upload presets
  static const String uploadPreset = 'music_loops'; // Crear este preset en Cloudinary console
  static const String folder = 'music_loops'; // Carpeta donde se almacenarán los loops
}
