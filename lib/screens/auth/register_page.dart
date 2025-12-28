// Lokasi: lib/screens/auth/register_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ❗ PENTING: Import halaman rekam wajah
import 'face_recognition_page.dart'; 

// (Kita mungkin tidak perlu firebase di sini lagi, tapi biarkan saja)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🎨 Warna utama
const Color primaryBlue = Color(0xFF2575FC);
const Color primaryPurple = Color(0xFF6A11CB);
const Color lightGreyBackground = Color(0xFFF0F4F8);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final nimController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _passwordHasText = false;
  bool _confirmPasswordHasText = false;

  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_onPasswordChanged);
    confirmPasswordController.addListener(_onConfirmPasswordChanged);
  }

  @override
  void dispose() {
    passwordController.removeListener(_onPasswordChanged);
    confirmPasswordController.removeListener(_onConfirmPasswordChanged);
    nameController.dispose();
    emailController.dispose();
    nimController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordHasText = passwordController.text.isNotEmpty;
    });
  }

  void _onConfirmPasswordChanged() {
    setState(() {
      _confirmPasswordHasText = confirmPasswordController.text.isNotEmpty;
    });
  }

  // ==========================================================
  // LOGIKA REGISTER
  // ==========================================================
  Future<void> _register(BuildContext context) async {
    // 1. Validasi form terlebih dahulu
    if (!_formKey.currentState!.validate()) return;
    
    // Set loading
    setState(() => _isLoading = true);

    // 2. Ambil semua data dari controller
    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String nim = nimController.text.trim();
    final String password = passwordController.text;

    // 3. Navigasi ke FaceRecognitionPage, kirim semua datanya
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceRecognitionPage(
            name: name,
            email: email,
            nim: nim,
            password: password,
          ),
        ),
      );
    }
    
    // Matikan loading setelah kembali dari halaman face recognition
    if(mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: lightGreyBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: lightGreyBackground,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 260),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            "Let's Get Started!",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),

                          ModernTextField(
                            label: 'Nama Lengkap',
                            controller: nameController,
                            icon: Icons.person_outline,
                            validator: (value) =>
                                value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                          ),
                          const SizedBox(height: 14),

                          ModernTextField(
                            label: 'Email',
                            controller: emailController,
                            icon: Icons.email_outlined,
                            errorText: _emailError,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              const String domain = '@mhs.unesa.ac.id';
                              if (!value.endsWith(domain)) {
                                return 'Email harus berdomain $domain';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          ModernTextField(
                            label: 'NIM',
                            controller: nimController,
                            icon: Icons.badge_outlined,
                            validator: (value) =>
                                value!.isEmpty ? 'NIM tidak boleh kosong' : null,
                          ),
                          const SizedBox(height: 14),

                          ModernTextField(
                            label: 'Password',
                            controller: passwordController,
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            errorText: _passwordError,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              if (value.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                            suffixIcon: _passwordHasText
                                ? IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: primaryBlue,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          const SizedBox(height: 14),

                          ModernTextField(
                            label: 'Konfirmasi Password',
                            controller: confirmPasswordController,
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi password tidak boleh kosong';
                              }
                              if (value != passwordController.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                            suffixIcon: _confirmPasswordHasText
                                ? IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: primaryBlue,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          const SizedBox(height: 20),

                          GradientButton(
                            text: "Lanjut Rekam Wajah",
                            isLoading: _isLoading,
                            onPressed:
                                _isLoading ? null : () => _register(context),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Sudah punya akun? "),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(
                                    context, '/'),
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Bagian Google telah dihapus di sini
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🌊 Wave header
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 280,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryPurple, primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // 🔷 Logo
            Positioned.fill(
              top: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Icon(Icons.flutter_dash, size: 70, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "ILABMI APP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🌊 Wave
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 4,
      size.height - 100,
      size.width / 2,
      size.height - 60,
    );
    path.quadraticBezierTo(
      3 * size.width / 4,
      size.height - 20,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// 🔤 TextField modern
class ModernTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final String? errorText;

  const ModernTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, color: primaryBlue),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        errorText: errorText,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }
}

// 🌈 Tombol gradien
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        gradient: const LinearGradient(
          colors: [primaryPurple, primaryBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}