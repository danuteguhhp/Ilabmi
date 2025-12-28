import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// 1. CONFIG & PALET WARNA
// =============================================================================
const Color primaryBlue = Color(0xFF2575FC);
const Color primaryPurple = Color(0xFF6A11CB);
const Color lightGreyBackground = Color(0xFFF4F6F9);
const Color darkGreyText = Color(0xFF2C3E50);
const Color borderGrey = Color(0xFFBDC3C7);
const Color dangerRed = Color(0xFFE74C3C);

class UserData {
  String nama;
  String nim;
  String email;
  String role;

  UserData({
    required this.nama,
    required this.nim,
    required this.email,
    required this.role,
  });
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  UserData currentUser = UserData(
    nama: "Memuat...",
    nim: "-",
    email: "-",
    role: "user",
  );

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 🔹 FUNGSI: Ambil Data dari Firestore
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              currentUser.nama = data['name'] ?? 'Tanpa Nama';
              currentUser.nim = data['nim'] ?? '-';
              currentUser.email = data['email'] ?? user.email!;
              currentUser.role = data['role'] ?? 'user';
              isLoading = false;
            });
          }
        }
      } catch (e) {
        debugPrint("Error mengambil data: $e");
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  // 🔹 FUNGSI: Logout (DIPERBARUI)
  Future<void> _handleLogout() async {
    try {
      // 1. Sign out dari Firebase
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        // 2. Arahkan ke Named Route '/' (Halaman Login)
        // pushNamedAndRemoveUntil akan menghapus semua halaman sebelumnya dari stack
        // sehingga user tidak bisa menekan tombol "Back" untuk kembali ke akun.
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal logout: $e")),
      );
    }
  }

  // 🔹 Variabel Deskripsi Aplikasi
  String appDescription = "Aplikasi Manajemen Peminjaman Alat Laboratorium.\n\n"
      "Versi: 1.0.0\n"
      "Pengembang: Tim IT Kampus";

  // 🔹 Modal Detail Profil
  void _showProfileDetailModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              "Detail Pengguna",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGreyText),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.person_outline, "Nama Lengkap", currentUser.nama),
            const Divider(height: 24),
            _buildDetailRow(Icons.email_outlined, "Email", currentUser.email),
            const Divider(height: 24),
            _buildDetailRow(Icons.badge_outlined, "NIM", currentUser.nim),
            const Divider(height: 24),
            _buildDetailRow(Icons.admin_panel_settings_outlined, "Role", currentUser.role),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  // ℹ️ Tentang Aplikasi Modal
  void _showAppInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text("Tentang Aplikasi", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGreyText)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: lightGreyBackground, borderRadius: BorderRadius.circular(12)),
              child: Text(appDescription, style: const TextStyle(fontSize: 14, color: darkGreyText, height: 1.5)),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup", style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  // 🔹 Logout confirmation
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi Keluar", style: TextStyle(fontWeight: FontWeight.bold, color: darkGreyText)),
        content: const Text("Apakah Anda yakin ingin keluar dari akun ini?"),
        actions: [
          TextButton(
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context); // Tutup Dialog
              _handleLogout(); // Jalankan fungsi logout Firebase
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: primaryBlue, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkGreyText)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey, width: 0.5),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkGreyText)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBackground,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      "Akun Pengguna",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 0.8),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderGrey, width: 0.7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: primaryBlue.withOpacity(0.1),
                            child: const Icon(Icons.person, size: 40, color: primaryBlue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(currentUser.nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGreyText)),
                                const SizedBox(height: 4),
                                Text(currentUser.nim, style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Monospace')),
                                const SizedBox(height: 4),
                                Text(currentUser.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 10),
                          child: Text("Pengaturan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                        _buildMenuTile(Icons.person_outline, "Detail Profil", primaryBlue, _showProfileDetailModal),
                        const SizedBox(height: 10),
                        _buildMenuTile(Icons.info_outline, "Tentang Aplikasi", primaryPurple, _showAppInfoModal),
                        _buildMenuTile(Icons.logout, "Keluar", dangerRed, _showLogoutConfirmation),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}