// lib/routes.dart
import 'package:flutter/material.dart';

// ✅ Pastikan semua import sesuai struktur folder barumu
import 'package:flutter_application_1/screens/auth/login_page.dart';
import 'package:flutter_application_1/screens/auth/register_page.dart';
import 'package:flutter_application_1/screens/user/user_dashboard.dart';
import 'package:flutter_application_1/screens/user/loan_page.dart';
import 'package:flutter_application_1/screens/admin/admin_dashboard.dart';

// ❗ PERUBAHAN DI SINI: Tambahkan import untuk face_login_page
import 'package:flutter_application_1/screens/auth/face_login_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
    '/': (context) => const LoginPage(),

  // '/': (context) => const UserDashboard(),
  '/register': (context) => const RegisterPage(),
  
  // ❗ PERUBAHAN DI SINI: Tambahkan rute baru
  '/face-login': (context) => const FaceLoginPage(),

  '/user/user-dashboard': (context) => const UserDashboard(),
  '/user/loan-page': (context) => const LoanPage(),
  '/admin/loan-page': (context) => const LoanPage(), // kalau beda halaman, ubah nanti
  '/admin-dashboard': (context) => const AdminDashboard(),
};