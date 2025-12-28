import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // Wajib untuk WriteBuffer
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraUtils {
  static InputImage inputImageFromCameraImage({
    required CameraImage image,
    required CameraController controller,
    required CameraDescription camera,
  }) {
    final sensorOrientation = camera.sensorOrientation;
    
    // 1. Tentukan Rotasi Gambar
    InputImageRotation rotation = InputImageRotation.rotation0deg;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation0deg;
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return InputImage.fromBytes(bytes: Uint8List(0), metadata: InputImageMetadata(size: Size.zero, rotation: rotation, format: InputImageFormat.nv21, bytesPerRow: 0));
      if (camera.lensDirection == CameraLensDirection.front) {
        // Front camera
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // Back camera
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation) ??
          InputImageRotation.rotation0deg;
    }

    // 2. Tentukan Format Gambar
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    // 3. Gabungkan Bytes (PENTING untuk Android/NV21)
    // Di versi baru, kita harus menggabungkan plane secara manual untuk Android
    if (image.planes.isEmpty) return InputImage.fromBytes(bytes: Uint8List(0), metadata: InputImageMetadata(size: Size.zero, rotation: rotation, format: format, bytesPerRow: 0));

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // 4. Buat Metadata (API TERBARU)
    // InputImagePlaneMetadata sudah dihapus, sekarang pakai bytesPerRow langsung
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow, // Ambil dari plane pertama
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  // Helper untuk orientasi
  static final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
}