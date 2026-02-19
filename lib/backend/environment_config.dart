import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static late String cloudinaryCloudName;
  static late String cloudinaryApiKey;
  static late String cloudinaryApiSecret;
  static late String cloudinaryUploadPreset;
  static late bool enableOfflineMode;

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');

      cloudinaryCloudName =
          dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: 'dsfazlofc');
      cloudinaryApiKey =
          dotenv.get('CLOUDINARY_API_KEY', fallback: '375549546746736');
      cloudinaryApiSecret = dotenv.get('CLOUDINARY_API_SECRET',
          fallback: '2pvXZo07QeUjClYKqHgFBoMjoVI');
      cloudinaryUploadPreset =
          dotenv.get('CLOUDINARY_UPLOAD_PRESET', fallback: 'musical_studio');
      enableOfflineMode =
          dotenv.get('ENABLE_OFFLINE_MODE', fallback: 'true') == 'true';
    } catch (e) {
      print('Error loading environment config: $e');
      // Use defaults if .env file is not found
      cloudinaryCloudName = 'dsfazlofc';
      cloudinaryApiKey = '375549546746736';
      cloudinaryApiSecret = '2pvXZo07QeUjClYKqHgFBoMjoVI';
      cloudinaryUploadPreset = 'musical_studio';
      enableOfflineMode = true;
    }
  }

  static String getCloudinaryUrl() {
    return 'CLOUDINARY_URL=cloudinary://$cloudinaryApiKey:$cloudinaryApiSecret@$cloudinaryCloudName';
  }
}
