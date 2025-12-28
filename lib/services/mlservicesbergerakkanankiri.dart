// 📂 Lokasi: lib/services/ml_services.dart

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/*
|--------------------------------------------------------------------------
| 🚀 MLService
|--------------------------------------------------------------------------
| Menangani:
| 1. Face Detection (ML Kit)
| 2. Face Recognition (MobileFaceNet - TFLite)
| 3. Liveness Detection (Head Movement)
|--------------------------------------------------------------------------
*/
class MLService {
  // ==========================================================
  // 🔹 TFLite (Face Recognition)
  // ==========================================================
  Interpreter? _interpreter;

  final int _inputSize = 112;    // MobileFaceNet input
  final int _outputSize = 192;   // Embedding size

  // ==========================================================
  // 🔹 ML Kit (Face Detection)
  // ==========================================================
  late FaceDetector _faceDetector;

  // ==========================================================
  // ✅ 1. INITIALIZE
  // ==========================================================
  Future<void> initialize() async {
    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableLandmarks: false,
          enableContours: false,
          enableTracking: false,
        ),
      );

      _interpreter =
          await Interpreter.fromAsset('assets/mobilefacenet.tflite');

      print('✅ MLService initialized');
    } catch (e) {
      print('❌ MLService initialization error: $e');
    }
  }

  // ==========================================================
  // ✅ 2. LIVENESS DETECTION (HEAD MOVEMENT)
  // ==========================================================
  Future<bool> checkLiveness(XFile img1, XFile img2) async {
    final image1 = InputImage.fromFile(File(img1.path));
    final image2 = InputImage.fromFile(File(img2.path));

    final faces1 = await _faceDetector.processImage(image1);
    final faces2 = await _faceDetector.processImage(image2);

    if (faces1.isEmpty || faces2.isEmpty) {
      return false;
    }

    final Rect box1 = faces1.first.boundingBox;
    final Rect box2 = faces2.first.boundingBox;

    // ✅ Deteksi pergerakan horizontal kepala
    final double deltaX = (box1.center.dx - box2.center.dx).abs();

    return deltaX > 15; // threshold aman TA
  }

  // ==========================================================
  // ✅ 3. FACE EMBEDDING (RECOGNITION)
  // ==========================================================
  Future<List<double>?> processFace(XFile imageFile) async {
    if (_interpreter == null) {
      print('❌ Interpreter belum diinisialisasi');
      return null;
    }

    // A. ML Kit input
    final inputImage = InputImage.fromFilePath(imageFile.path);

    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) {
      print('⚠️ Tidak ada wajah terdeteksi');
      return null;
    }

    final Face face = faces.first;

    // B. Decode image
    final img.Image? originalImage =
        img.decodeImage(await imageFile.readAsBytes());
    if (originalImage == null) return null;

    // C. Crop wajah
    final img.Image cropped = _cropFace(
      originalImage,
      face.boundingBox,
    );

    // D. Resize
    final img.Image resized = img.copyResize(
      cropped,
      width: _inputSize,
      height: _inputSize,
    );

    // E. Convert to tensor
    final Float32List inputBuffer = _imageToFloat32(resized);
    final input = inputBuffer.reshape([1, _inputSize, _inputSize, 3]);

    final output =
        List.filled(_outputSize, 0.0).reshape([1, _outputSize]);

    // F. Run inference
    _interpreter!.run(input, output);

    // G. Normalize embedding
    final embedding = _normalizeEmbedding(output[0]);

    return embedding;
  }

  // ==========================================================
  // 🔧 Helper: Crop wajah aman
  // ==========================================================
  img.Image _cropFace(img.Image imgSrc, Rect box) {
    int x = max(0, box.left.toInt());
    int y = max(0, box.top.toInt());
    int w = min(imgSrc.width - x, box.width.toInt());
    int h = min(imgSrc.height - y, box.height.toInt());

    return img.copyCrop(
      imgSrc,
      x: x,
      y: y,
      width: w,
      height: h,
    );
  }

  // ==========================================================
  // 🔧 Helper: Convert image → Float32
  // ==========================================================
  Float32List _imageToFloat32(img.Image image) {
    final Float32List buffer =
        Float32List(_inputSize * _inputSize * 3);
    int idx = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final p = image.getPixel(x, y);
        buffer[idx++] = (p.r - 127.5) / 127.5;
        buffer[idx++] = (p.g - 127.5) / 127.5;
        buffer[idx++] = (p.b - 127.5) / 127.5;
      }
    }
    return buffer;
  }

  // ==========================================================
  // 🔧 Helper: Normalisasi L2
  // ==========================================================
  List<double> _normalizeEmbedding(List<double> emb) {
    final double norm =
        sqrt(emb.map((e) => e * e).reduce((a, b) => a + b));
    return emb.map((e) => e / norm).toList();
  }

  // ==========================================================
  // ✅ DISPOSE
  // ==========================================================
  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
    print('ℹ️ MLService disposed');
  }
}
