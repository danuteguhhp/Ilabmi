// Lokasi: lib/services/ml_services.dart

import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class MLService {
  Interpreter? _interpreter;
  late FaceDetector _faceDetector;
  
  // MobileFaceNet config
  final int _inputSize = 112;
  final int _outputSize = 192;

Future<void> initialize() async {
    // 1. Setup Face Detector dengan API TERBARU
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate, // Tetap gunakan mode akurat
      enableLandmarks: false,      // DULU: landmarkMode: FaceDetectorMode.none
      enableClassification: true,  // DULU: classificationMode: FaceDetectorMode.all (WAJIB TRUE UNTUK KEDIPAN)
      enableTracking: true,        // Agar ID wajah stabil saat tracking
      enableContours: false,
    );
    
    _faceDetector = FaceDetector(options: options);

    // 2. Load Model TFLite
    try {
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
      print('✅ MLService: Model Loaded');
    } catch (e) {
      print('❌ MLService Error: $e');
    }
  }
  
  // ==========================================================
  // 👁️ Cek Kedipan (Untuk Stream Logic)
  // ==========================================================
  bool isBlinking(Face face) {
    // Probabilitas mata terbuka (0.0 - 1.0)
    final double? leftEyeOpen = face.leftEyeOpenProbability;
    final double? rightEyeOpen = face.rightEyeOpenProbability;

    // Jika probabilitas < 0.1 artinya mata tertutup
    if (leftEyeOpen != null && rightEyeOpen != null) {
      return (leftEyeOpen < 0.1 && rightEyeOpen < 0.1);
    }
    return false;
  }

  // ==========================================================
  // 🧠 Proses Pengenalan Wajah (Dari File High-Res)
  // ==========================================================
  Future<List<double>?> processFace(XFile imageFile) async {
    if (_interpreter == null) return null;

    // 1. Deteksi Wajah di gambar statis
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final faces = await _faceDetector.processImage(inputImage);
    
    if (faces.isEmpty) return null;

    // Ambil wajah terbesar/paling tengah
    final Face face = faces.first;

    // 2. Decode Image
    final bytes = await imageFile.readAsBytes();
    final img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) return null;

    // 3. Crop Wajah (Dilebihkan sedikit/padding agar akurasi lebih baik)
    final img.Image croppedFace = _cropFace(originalImage, face.boundingBox);

    // 4. Preprocessing (Resize -> Normalize -> Float32)
    final img.Image resized = img.copyResize(
      croppedFace, 
      width: _inputSize, 
      height: _inputSize
    );
    
    final Float32List inputData = _imageToFloat32(resized);
    
    // 5. Inference
    final input = inputData.reshape([1, _inputSize, _inputSize, 3]);
    final output = List.filled(_outputSize, 0.0).reshape([1, _outputSize]);

    _interpreter!.run(input, output);

    return _normalizeEmbedding(output[0]);
  }

  // Helper: Smart Crop dengan Padding
  img.Image _cropFace(img.Image image, Rect box) {
    // Tambah padding 10% agar dagu/dahi tidak terpotong (meningkatkan akurasi)
    double padding = 10.0;
    
    int x = max(0, (box.left - padding).toInt());
    int y = max(0, (box.top - padding).toInt());
    int w = min(image.width - x, (box.width + padding * 2).toInt());
    int h = min(image.height - y, (box.height + padding * 2).toInt());

    return img.copyCrop(image, x: x, y: y, width: w, height: h);
  }

  Float32List _imageToFloat32(img.Image image) {
    final Float32List buffer = Float32List(_inputSize * _inputSize * 3);
    int idx = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final p = image.getPixel(x, y);
        // Normalisasi standar MobileFaceNet (-1 s/d 1)
        buffer[idx++] = (p.r - 127.5) / 128.0;
        buffer[idx++] = (p.g - 127.5) / 128.0;
        buffer[idx++] = (p.b - 127.5) / 128.0;
      }
    }
    return buffer;
  }

  List<double> _normalizeEmbedding(List<double> embedding) {
    double sum = 0;
    for (var x in embedding) sum += x * x;
    double norm = sqrt(sum);
    return embedding.map((e) => e / norm).toList();
  }

  // Getter face detector untuk stream
  FaceDetector get detector => _faceDetector;

  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
  }
}