import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/imagekit_config.dart';

class ImageKitService {
  ImageKitService._internal();
  static final ImageKitService instance = ImageKitService._internal();

  /// رفع صورة واحدة إلى ImageKit داخل مجلد برقم هاتف البائع
  Future<String?> uploadImage({
    required String filePath,
    required String sellerNumber,
    int index = 0,
  }) async {
    // إذا كانت الصورة رابط إنترنت بالفعل (تم رفعها مسبقاً) لا نعيد رفعها
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('Image file does not exist: $filePath');
      return null;
    }

    if (!ImageKitConfig.isConfigured) {
      debugPrint(
        '⚠️ ImageKit keys not configured in lib/config/imagekit_config.dart. Using local path.',
      );
      return filePath;
    }

    try {
      final sanitizedSeller = sellerNumber.trim().isNotEmpty
          ? sellerNumber.trim().replaceAll(RegExp(r'[^0-9a-zA-Z_+]'), '_')
          : 'unknown_seller';

      final folder = '/$sanitizedSeller';
      final fileName = 'device_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';

      final uri = Uri.parse(ImageKitConfig.uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      // Basic Auth: privateKey: (empty password)
      final authHeader =
          'Basic ${base64Encode(utf8.encode('${ImageKitConfig.privateKey}:'))}';
      request.headers['Authorization'] = authHeader;

      request.fields['fileName'] = fileName;
      request.fields['folder'] = folder;
      request.fields['useUniqueFileName'] = 'true';

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final url = json['url'] as String?;
        debugPrint('✅ Image uploaded successfully to ImageKit: $url');
        return url;
      } else {
        debugPrint('❌ ImageKit upload failed [${response.statusCode}]: ${response.body}');
        return filePath;
      }
    } catch (e) {
      debugPrint('❌ Exception while uploading to ImageKit: $e');
      return filePath;
    }
  }

  /// رفع مجموعة صور دفعة واحدة وإرجاع روابطها
  Future<List<String>> uploadMultipleImages({
    required List<String> filePaths,
    required String sellerNumber,
  }) async {
    final List<String> uploadedUrls = [];
    for (int i = 0; i < filePaths.length; i++) {
      final path = filePaths[i];
      final url = await uploadImage(
        filePath: path,
        sellerNumber: sellerNumber,
        index: i,
      );
      if (url != null && url.isNotEmpty) {
        uploadedUrls.add(url);
      }
    }
    return uploadedUrls;
  }
}
