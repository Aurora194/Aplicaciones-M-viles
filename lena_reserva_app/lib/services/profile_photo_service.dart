import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class ProfilePhotoService {
  ProfilePhotoService._();

  static const String _photoKey = 'profile_photo_base64';

  static Future<void> savePhoto(File file) async {
    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_photoKey, base64);
  }

  static Future<Uint8List?> loadPhoto() async {
    final preferences = await SharedPreferences.getInstance();

    final value = preferences.getString(_photoKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deletePhoto() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_photoKey);
  }
}
