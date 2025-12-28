import 'package:flutter/material.dart';
import 'package:flutter_application_1/routes.dart'; // <-- Sesuaikan dengan path routes Anda
import 'package:firebase_core/firebase_core.dart'; // <-- 1. Impor Firebase Core
import 'firebase_options.dart'; // <-- 2. Impor file konfigurasi Anda

Future<void> main() async { // <-- 3. Ubah menjadi async
  // 4. Pastikan Flutter siap
  WidgetsFlutterBinding.ensureInitialized();
  
  // 5. Inisialisasi Firebase SEBELUM runApp()
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventarisasi Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/', // Halaman awal
      routes: appRoutes, // Ambil dari routes.dart
    );
  }
}
