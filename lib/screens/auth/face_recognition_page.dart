// Lokasi: lib/screens/auth/face_recognition_page.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ml_services.dart';

class FaceRecognitionPage extends StatefulWidget {
  final String name, email, nim, password;

  const FaceRecognitionPage({
    super.key,
    required this.name,
    required this.email,
    required this.nim,
    required this.password,
  });

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  CameraController? _controller;
  final MLService _mlService = MLService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _mlService.initialize();
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first);

    _controller = CameraController(frontCamera, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _captureAndRegister() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isProcessing = true);

    try {
      // 1. Ambil Foto
      final XFile image = await _controller!.takePicture();

      // 2. Generate Embedding
      final embedding = await _mlService.processFace(image);

      if (embedding == null) {
        _showSnack("Wajah tidak terdeteksi. Pastikan pencahayaan cukup.", Colors.red);
        setState(() => _isProcessing = false);
        return;
      }

      // 3. Register ke Firebase
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: widget.email, password: widget.password);

      if (userCred.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'uid': userCred.user!.uid,
          'name': widget.name,
          'email': widget.email,
          'nim': widget.nim,
          'role': 'user',
          'faceEmbedding': embedding, // Simpan embedding di sini
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          _showSnack("Registrasi Berhasil!", Colors.green);
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      }
    } catch (e) {
      _showSnack("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  void dispose() {
    _controller?.dispose();
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Daftar Wajah"), backgroundColor: Colors.transparent),
      body: Stack(
        alignment: Alignment.center,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!)
          else
            const CircularProgressIndicator(),
            
          // Simple Overlay
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 3),
              borderRadius: BorderRadius.circular(200),
            ),
            width: 300,
            height: 400,
          ),
          
          Positioned(
            bottom: 30,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _captureAndRegister,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(), 
                padding: const EdgeInsets.all(20),
                backgroundColor: Colors.white
              ),
              child: _isProcessing 
                ? const CircularProgressIndicator() 
                : const Icon(Icons.camera_alt, size: 40, color: Colors.black),
            ),
          )
        ],
      ),
    );
  }
}