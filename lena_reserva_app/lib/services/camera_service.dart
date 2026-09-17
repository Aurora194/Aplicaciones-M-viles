import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraResult {
  const CameraResult({required this.status, this.file});

  final CameraStatus status;
  final File? file;
}

enum CameraStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unavailable,
  cancelled,
  error,
}

class CameraService {
  CameraService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<CameraResult> takePhoto() async {
    try {
      final status = await Permission.camera.status;

      if (status.isPermanentlyDenied) {
        return const CameraResult(status: CameraStatus.permanentlyDenied);
      }

      if (status.isRestricted) {
        return const CameraResult(status: CameraStatus.restricted);
      }

      PermissionStatus permission = status;

      if (!permission.isGranted) {
        permission = await Permission.camera.request();
      }

      if (permission.isGranted) {
        final image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );

        if (image == null) {
          return const CameraResult(status: CameraStatus.cancelled);
        }

        return CameraResult(
          status: CameraStatus.granted,
          file: File(image.path),
        );
      }

      if (permission.isPermanentlyDenied) {
        return const CameraResult(status: CameraStatus.permanentlyDenied);
      }

      if (permission.isRestricted) {
        return const CameraResult(status: CameraStatus.restricted);
      }

      return const CameraResult(status: CameraStatus.denied);
    } catch (_) {
      return const CameraResult(status: CameraStatus.error);
    }
  }

  static Future<bool> openSettings() {
    return openAppSettings();
  }
}
