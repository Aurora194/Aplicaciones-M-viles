import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class ProfilePhotoService {
  ProfilePhotoService._();

  static String _photoKey(String userKey) {
    final normalized = userKey.trim().toLowerCase();

    if (normalized.isEmpty) {
      return 'profile_photo_default';
    }

    return 'profile_photo_$normalized';
  }

  static Future<void> savePhoto({
    required String userKey,
    required File file,
  }) async {
    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_photoKey(userKey), base64);
  }

  static Future<Uint8List?> loadPhoto({required String userKey}) async {
    final preferences = await SharedPreferences.getInstance();

    final value = preferences.getString(_photoKey(userKey));

    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deletePhoto({required String userKey}) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_photoKey(userKey));
  }
}
