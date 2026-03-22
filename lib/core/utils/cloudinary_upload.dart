import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dnba3dkxk';
  static const String uploadPreset = 'fitora_upload';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

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

  /// Extracts the public_id from a Cloudinary secure_url and calls destroy.
  /// Best-effort: errors are silently swallowed.
  static Future<void> deleteImage(String imageUrl) async {
    try {
      // URL: https://res.cloudinary.com/<cloud>/image/upload/v<ver>/<public_id>.<ext>
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final uploadIdx = segments.indexOf('upload');
      if (uploadIdx == -1 || uploadIdx + 1 >= segments.length) return;

      final afterUpload = segments.sublist(uploadIdx + 1);
      // Skip version segment (v followed by digits)
      final startIdx = (afterUpload.isNotEmpty && RegExp(r'^v\d+$').hasMatch(afterUpload[0])) ? 1 : 0;
      final publicIdWithExt = afterUpload.sublist(startIdx).join('/');
      final publicId = publicIdWithExt.contains('.')
          ? publicIdWithExt.substring(0, publicIdWithExt.lastIndexOf('.'))
          : publicIdWithExt;

      if (publicId.isEmpty) return;

      final destroyUrl = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');
      await http.post(destroyUrl, body: {
        'public_id': publicId,
        'upload_preset': uploadPreset,
      });
    } catch (_) {
      // Best-effort; ignore errors
    }
  }
}
