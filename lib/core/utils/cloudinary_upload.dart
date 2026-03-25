import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dnba3dkxk';
  static const String uploadPreset = 'fitora_upload';

  static Future<String?> uploadMedia(File file, bool isVideo) async {
    try {
      final resourceType = isVideo ? 'video' : 'image';
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Backwards compatibility wrapper for standard images
  static Future<String?> uploadImage(File imageFile) async {
    return await uploadMedia(imageFile, false);
  }

  static Future<void> deleteMedia(String mediaUrl, {bool isVideo = false}) async {
    try {
      final resourceType = isVideo ? 'video' : 'image';
      final uri = Uri.parse(mediaUrl);
      final segments = uri.pathSegments;
      final uploadIdx = segments.indexOf('upload');
      if (uploadIdx == -1 || uploadIdx + 1 >= segments.length) return;

      final afterUpload = segments.sublist(uploadIdx + 1);
      final startIdx = (afterUpload.isNotEmpty && RegExp(r'^v\d+$').hasMatch(afterUpload[0])) ? 1 : 0;
      final publicIdWithExt = afterUpload.sublist(startIdx).join('/');
      final publicId = publicIdWithExt.contains('.')
          ? publicIdWithExt.substring(0, publicIdWithExt.lastIndexOf('.'))
          : publicIdWithExt;

      if (publicId.isEmpty) return;

      final destroyUrl = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/destroy');
      await http.post(destroyUrl, body: {
        'public_id': publicId,
        'upload_preset': uploadPreset,
      });
    } catch (_) {
      // Best-effort; ignore errors
    }
  }

  /// Backwards compatibility wrapper
  static Future<void> deleteImage(String imageUrl) async {
    await deleteMedia(imageUrl, isVideo: false);
  }
}
