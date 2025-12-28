// 📂 Lokasi: lib/screens/auth/face_login_page.dart

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../services/ml_services.dart';
import '../../utils/camera_utils.dart';
import '../admin/admin_dashboard.dart';
import '../user/user_dashboard.dart';

class FaceLoginPage extends StatefulWidget {
  const FaceLoginPage({super.key});

  @override
  State<FaceLoginPage> createState() => _FaceLoginPageState();
}

class _FaceLoginPageState extends State<FaceLoginPage> {
  CameraController? _controller;
  final MLService _mlService = MLService();
  final _storage = const FlutterSecureStorage();
  
  bool _isInitializing = true;
  bool _isProcessingFrame = false;
  bool _isVerifying = false;
  
  String _statusMessage = "Cari Wajah...";
  bool _eyesClosed = false; // Flag status kedipan
  int _frameCounter = 0;    // Untuk throttle stream

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    await _mlService.initialize();
    
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.high, 
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21, // Penting buat Android agar tidak error ML Kit
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() => _isInitializing = false);
      _startImageStream(); // Langsung mulai stream
    }
  }

  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isStreamingImages) {
      return; 
    }

    _controller!.startImageStream((CameraImage image) async {
      if (_isProcessingFrame || _isVerifying) return;

      // Proses tiap 5 frame (biar gak berat)
      _frameCounter++;
      if (_frameCounter % 5 != 0) return;

      _isProcessingFrame = true;

      try {
        await _processFrame(image);
      } catch (e) {
        debugPrint("Error processing stream: $e");
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  // ==========================================================
  // 1. Logic Deteksi Kedipan (Looping di Stream)
  // ==========================================================
  Future<void> _processFrame(CameraImage image) async {
    final inputImage = CameraUtils.inputImageFromCameraImage(
      image: image, 
      controller: _controller!, 
      camera: _controller!.description
    );

    final faces = await _mlService.detector.processImage(inputImage);

    if (faces.isEmpty) {
      if (mounted) setState(() => _statusMessage = "Wajah tidak ditemukan");
      _eyesClosed = false; 
      return;
    }

    final Face face = faces.first;

    // Cek status kedipan (menggunakan ML Service)
    final bool isBlinking = _mlService.isBlinking(face);

    if (isBlinking) {
      // User sedang merem
      _eyesClosed = true;
      if (mounted) setState(() => _statusMessage = "Tahan...");
    } else {
      // User melek. Jika sebelumnya merem, berarti SUDAH KEDIP
      if (_eyesClosed) {
        _eyesClosed = false;
        // ACTION: Stop stream & Ambil foto
        await _stopStreamAndLogin();
      } else {
        if (mounted) setState(() => _statusMessage = "Silakan Berkedip");
      }
    }
  }

  // ==========================================================
  // 2. Transisi: Stop Stream -> Ambil Foto High Res
  // ==========================================================
  Future<void> _stopStreamAndLogin() async {
    // A. Matikan Stream dengan AMAN (Try-Catch Fix)
    try {
      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) {
      debugPrint("Warning: Stream sudah stop ($e)");
    }

    if (!mounted) return;
    setState(() {
      _isVerifying = true;
      _statusMessage = "Memproses Wajah...";
    });

    try {
      // B. Jeda sebentar agar kamera fokus/stabil setelah stream stop
      await Future.delayed(const Duration(milliseconds: 500)); 
      
      if (_controller == null || !_controller!.value.isInitialized) {
         throw Exception("Kamera error/tidak siap");
      }

      // C. Ambil Foto Resolusi TINGGI
      final XFile imageFile = await _controller!.takePicture();

      // D. Proses AI
      final embedding = await _mlService.processFace(imageFile);

      if (embedding != null) {
        await _matchFaceWithDatabase(embedding);
      } else {
        _showError("Gagal ekstrak wajah. Cahaya kurang?");
        _restartCamera();
      }
    } catch (e) {
      _showError("Error Camera: $e");
      _restartCamera();
    }
  }

  // ==========================================================
  // 3. Cocokkan dengan Database Firebase
  // ==========================================================
  Future<void> _matchFaceWithDatabase(List<double> newEmbedding) async {
    try {
      final users = await FirebaseFirestore.instance.collection('users').get();
      
      double minDistance = double.infinity;
      Map<String, dynamic>? matchedUser;

      for (var doc in users.docs) {
        final data = doc.data();
        if (data['faceEmbedding'] != null) {
          final List<dynamic> rawList = data['faceEmbedding'];
          final dbEmbedding = rawList.map((e) => e as double).toList();

          // Hitung Jarak Euclidean
          double distance = _euclideanDistance(newEmbedding, dbEmbedding);
          
          if (distance < minDistance) {
            minDistance = distance;
            matchedUser = data;
          }
        }
      }

      // Threshold: 0.85 (Semakin kecil semakin ketat/akurat)
      const double threshold = 0.85; 

      if (minDistance < threshold && matchedUser != null) {
        await _performFirebaseLogin(matchedUser);
      } else {
        _showError("Wajah tidak dikenali.");
        _restartCamera();
      }
    } catch (e) {
      _showError("Database Error: $e");
      _restartCamera();
    }
  }

  // ==========================================================
  // 4. Login Firebase & Navigasi (Sapaan & Role Fix)
  // ==========================================================
  Future<void> _performFirebaseLogin(Map<String, dynamic> userData) async {
    try {
      final email = userData['email'];
      // Ambil data dari local storage (pastikan user pernah login manual sebelumnya)
      final storedEmail = await _storage.read(key: 'userEmail');
      final storedPass = await _storage.read(key: 'userPassword');

      // Validasi session local
      if (storedEmail == email && storedPass != null) {
        // Login ke Auth
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: storedPass,
        );

        if (!mounted) return;

        // -----------------------------------------------------------
        // 🔥 LOGIKA SAPAAN WAKTU & ROLE CHECKING 🔥
        // -----------------------------------------------------------
        
        // A. Ambil Nama & Waktu
        String name = userData['name'] ?? 'User';
        int hour = DateTime.now().hour;
        String greeting;

        if (hour >= 4 && hour < 11) {
          greeting = "Selamat Pagi";
        } else if (hour >= 11 && hour < 15) {
          greeting = "Selamat Siang";
        } else if (hour >= 15 && hour < 18) {
          greeting = "Selamat Sore";
        } else {
          greeting = "Selamat Malam";
        }

        // B. Ambil & Bersihkan Role
        // Mengatasi masalah "Admin " (spasi) atau "ADMIN" (capslock)
        String rawRole = userData['role'] ?? 'user';
        String cleanRole = rawRole.toString().toLowerCase().trim();

        // Debugging di console
        print("🔍 Login Success: $name | Role: $cleanRole");

        // C. Tampilkan Notifikasi Sapaan
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   "$greeting, $name!", // Contoh: Selamat Pagi, Budi!
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                 ),
                 Text("Login berhasil sebagai $cleanRole"),
               ],
             ), 
             backgroundColor: Colors.green,
             duration: const Duration(seconds: 2),
           ),
        );

        // D. Navigasi Sesuai Role
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) {
            if (cleanRole == 'admin') {
              return const AdminDashboard();
            } else {
              return const UserDashboard();
            }
          }),
          (route) => false,
        );
        // -----------------------------------------------------------

      } else {
        _showError("Sesi habis atau akun beda. Silakan login manual.");
      }
    } catch (e) {
      _showError("Login Gagal: $e");
      _restartCamera();
    }
  }
  
  // Helper Matematika
  double _euclideanDistance(List<double> e1, List<double> e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow(e1[i] - e2[i], 2);
    }
    return sqrt(sum);
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  void _restartCamera() {
    setState(() {
      _isVerifying = false;
      _statusMessage = "Silakan Berkedip";
      _frameCounter = 0;
      _eyesClosed = false;
    });
    _startImageStream();
  }

  @override
  void dispose() {
    try {
      if (_controller != null && _controller!.value.isStreamingImages) {
        _controller!.stopImageStream();
      }
    } catch (_) {}
    _controller?.dispose();
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          if (_isInitializing || _controller == null)
            const Center(child: CircularProgressIndicator())
          else
            Transform.scale(
              scale: 1.1, // Zoom sedikit agar full screen
              child: Center(child: CameraPreview(_controller!)),
            ),

          // 2. Overlay Oval
          CustomPaint(painter: OverlayPainter()),

          // 3. Status Text
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_isVerifying)
                  const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 20, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 4. Tombol Back
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          )
        ],
      ),
    );
  }
}

class OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ovalWidth = size.width * 0.7;
    final ovalHeight = ovalWidth * 1.3;
    final center = size.center(Offset.zero);
    
    final path = Path()
      ..addOval(Rect.fromCenter(center: center, width: ovalWidth, height: ovalHeight));
    
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, path),
      Paint()..color = Colors.black.withOpacity(0.6),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}