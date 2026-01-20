import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'cloudinary_config.dart';

class CloudinaryService {
  /// Genera un signature para la autenticación de Cloudinary
  static String _generateSignature(Map<String, String> params) {
    // Ordenar parámetros alfabéticamente
    final sortedKeys = params.keys.toList()..sort();
    final paramsString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    // Crear signature usando SHA-1
    final bytes = utf8.encode('$paramsString${CloudinaryConfig.apiSecret}');
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// Sube un archivo de audio a Cloudinary
  /// 
  /// [file] - Archivo a subir
  /// [title] - Título del archivo (se usa como public_id)
  /// 
  /// Retorna el resultado de la subida con la URL y public_id
  static Future<Map<String, dynamic>> uploadAudioFile(
    File file,
    String title,
  ) async {
    try {
      // Generar timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Limpiar el título para usarlo como public_id
      final publicId = '${CloudinaryConfig.folder}/${_sanitizeFileName(title)}_$timestamp';

      // Crear parámetros para la firma
      final params = {
        'timestamp': timestamp,
        'public_id': publicId,
        'folder': CloudinaryConfig.folder,
      };

      // Generar signature
      final signature = _generateSignature(params);

      // Crear request multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryConfig.uploadUrl),
      );

      // Agregar campos
      request.fields['api_key'] = CloudinaryConfig.apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      request.fields['public_id'] = publicId;
      request.fields['folder'] = CloudinaryConfig.folder;
      request.fields['resource_type'] = 'auto'; // Detecta automáticamente el tipo

      // Agregar archivo
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: path.basename(file.path),
      );
      request.files.add(multipartFile);

      // Enviar request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          'success': true,
          'url': jsonResponse['secure_url'],
          'public_id': jsonResponse['public_id'],
          'resource_type': jsonResponse['resource_type'],
          'format': jsonResponse['format'],
          'bytes': jsonResponse['bytes'],
          'duration': jsonResponse['duration'] ?? 0.0,
        };
      } else {
        return {
          'success': false,
          'error': 'Error en la subida: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al subir archivo: $e',
      };
    }
  }

  /// Elimina un archivo de Cloudinary
  /// 
  /// [publicId] - Public ID del archivo a eliminar
  static Future<bool> deleteAudioFile(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Crear parámetros para la firma
      final params = {
        'public_id': publicId,
        'timestamp': timestamp,
      };

      // Generar signature
      final signature = _generateSignature(params);

      // Crear request
      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/destroy'),
        body: {
          'api_key': CloudinaryConfig.apiKey,
          'timestamp': timestamp,
          'signature': signature,
          'public_id': publicId,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['result'] == 'ok';
      }
      return false;
    } catch (e) {
      print('Error al eliminar archivo: $e');
      return false;
    }
  }

  /// Sanitiza el nombre del archivo para usarlo como public_id
  static String _sanitizeFileName(String fileName) {
    return fileName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  /// Obtiene la URL de streaming de un archivo de audio
  static String getStreamingUrl(String publicId) {
    return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/video/upload/$publicId';
  }
}
