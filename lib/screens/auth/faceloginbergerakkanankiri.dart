// Lokasi: lib/screens/auth/face_login_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// Firebase & MLService
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Secure storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import service dan dashboard
import '../../services/ml_services.dart';
import '../admin/admin_dashboard.dart';
import '../user/user_dashboard.dart';

// ==========================================================
// 🎯 FACE LOGIN PAGE
// ==========================================================
class FaceLoginPage extends StatefulWidget {
  const FaceLoginPage({super.key});

  @override
  State<FaceLoginPage> createState() => _FaceLoginPageState();
}

class _FaceLoginPageState extends State<FaceLoginPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;

  final MLService _mlService = MLService();
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllerFuture = _initializeCameraAndML();
  }

  Future<void> _initializeCameraAndML() async {
    await _initializeCamera();
    await _mlService.initialize();

    if (mounted) setState(() {});
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      return _controller!.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal inisialisasi kamera: $e")),
        );
      }
      rethrow;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      setState(() {
        _initializeControllerFuture = _initializeCameraAndML();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _mlService.dispose();
    super.dispose();
  }

  // ==========================================================
  // 🧠 Fungsi Euclidean Distance
  // ==========================================================
  double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
  }

  // ==========================================================
  // 📷 Capture Foto + Liveness + Face Recognition
  // ==========================================================
  Future<void> _captureAndLogin() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isProcessing = true);

    try {
      // ===============================
      // 1️⃣ AMBIL FOTO PERTAMA
      // ===============================
      final XFile image1 = await _controller!.takePicture();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gerakkan kepala ke kiri/kanan..."),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      // ===============================
      // 2️⃣ AMBIL FOTO KEDUA
      // ===============================
      final XFile image2 = await _controller!.takePicture();

      // ===============================
      // 3️⃣ LIVENESS CHECK
      // ===============================
      final bool isLive = await _mlService.checkLiveness(image1, image2);

      if (!isLive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Liveness gagal. Pastikan kepala bergerak."),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // ===============================
      // 4️⃣ PROSES FACE EMBEDDING
      // ===============================
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Memproses wajah...")),
      );

      final liveEmbedding = await _mlService.processFace(image2);

      if (liveEmbedding == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Wajah tidak terdeteksi."),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // ===============================
      // 5️⃣ Ambil user dari Firestore
      // ===============================
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      double minDistance = double.infinity;
      Map<String, dynamic>? bestMatch;

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();

        if (data['faceEmbedding'] != null) {
          final storedEmbedding = List<double>.from(data['faceEmbedding']);
          final distance = _euclideanDistance(liveEmbedding, storedEmbedding);

          if (distance < minDistance) {
            minDistance = distance;
            bestMatch = data;
          }
        }
      }

      const threshold = 1.0;

      // ===============================
      // 6️⃣ CHECK MATCH
      // ===============================
      if (minDistance <= threshold && bestMatch != null) {
        final String email = bestMatch['email'];
        final String? storedEmail = await _storage.read(key: 'userEmail');
        final String? storedPassword = await _storage.read(key: 'userPassword');

        // Jika user belum pernah login pakai password
        if (storedEmail != email || storedPassword == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Face login belum aktif. Login dulu pakai email & password.",
              ),
              backgroundColor: Colors.orangeAccent,
            ),
          );
          setState(() => _isProcessing = false);
          return;
        }

        // -----------------------------
        // 🔐 Login ke Firebase Auth
        // -----------------------------
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: email,
          password: storedPassword,
        );

        if (credential.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text("Login berhasil! Selamat datang, ${bestMatch['name']}"),
              backgroundColor: Colors.green,
            ),
          );

          final role = bestMatch['role'] ?? 'user';

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  role == 'admin' ? const AdminDashboard() : const UserDashboard(),
            ),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Wajah tidak cocok."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ==========================================================
  // 🧩 UI / TAMPILAN
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Login Wajah",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Kamera
          SizedBox.expand(
            child: FutureBuilder(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    _controller != null &&
                    _controller!.value.isInitialized) {
                  final size = MediaQuery.of(context).size;
                  var scale =
                      size.aspectRatio * _controller!.value.aspectRatio;
                  if (scale < 1) scale = 1 / scale;

                  return Transform.scale(
                    scale: scale,
                    child: CameraPreview(_controller!),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
            ),
          ),

          // Overlay oval
          SizedBox.expand(
            child: CustomPaint(painter: OverlayPainter()),
          ),

          // Instruksi teks
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            child: Column(
              children: [
                const Text(
                  "Posisikan Wajah Anda",
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  "Pastikan wajah berada dalam oval\nPencahayaan harus baik",
                  style:
                      TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Tombol
          Positioned(
            bottom: 40,
            child: GestureDetector(
              onTap: _isProcessing ? null : _captureAndLogin,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Container(
                          width: 65,
                          height: 65,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// 🎨 Overlay Painter
// ==========================================================
class OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ovalWidth = size.width * 0.75;
    final ovalHeight = ovalWidth * 1.25;

    final ovalRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: ovalWidth,
      height: ovalHeight,
    );

    final path = Path()..addOval(ovalRect);
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final overlay = Path.combine(PathOperation.difference, fullPath, path);

    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
