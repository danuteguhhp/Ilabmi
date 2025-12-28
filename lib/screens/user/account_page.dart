import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// <-- 1. IMPOR FIREBASE -->
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🎨 Palet warna modern (Tidak berubah)
const Color primaryBlue = Color(0xFF2575FC);
const Color primaryPurple = Color(0xFF6A11CB);
const Color lightGreyBackground = Color(0xFFF0F4F8);
const Color darkGreyText = Color(0xFF333333);
const Color accentTextColor = Color(0xFF1E88E5);

// <-- 2. HAPUS 'password' DARI UserData -->
class UserData {
  String nama;
  String nim;
  String email;
  // String password; // <-- Dihapus

  UserData({
    required this.nama,
    required this.nim,
    required this.email,
  });

  // <-- 3. TAMBAHKAN factory constructor -->
  factory UserData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserData(
      nama: data['name'] ?? 'Tanpa Nama',
      nim: data['nim'] ?? 'Tanpa NIM',
      email: data['email'] ?? 'Tanpa Email',
    );
  }
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // <-- 4. UBAH STATE -->
  UserData? currentUserData; // Akan diisi saat data di-load
  bool _isLoading = true; // Untuk menampilkan loading indicator
  // final User? _firebaseUser = FirebaseAuth.instance.currentUser; // <-- Dihapus

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // <-- 5. FUNGSI DIPERBAIKI UNTUK MENGAMBIL DATA DARI FIRESTORE -->
  Future<void> _loadUserData() async {
    
    // -----------------------------------------------------------------
    // 🔥 PERBAIKAN: Tunggu instance-nya siap
    // -----------------------------------------------------------------
    
    // Coba ambil user saat ini
    User? user = FirebaseAuth.instance.currentUser;

    // Jika user null (mungkin karena race condition setelah login),
    // kita beri jeda sangat singkat agar state-nya "mapan"
    if (user == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      // Coba ambil lagi setelah jeda
      user = FirebaseAuth.instance.currentUser;
    }
    
    // -----------------------------------------------------------------

    if (user == null) {
      // Jika SETELAH DITUNGGU masih null, baru kita anggap error
      setState(() => _isLoading = false);
      _showErrorDialog("Error", "Sesi login tidak terdeteksi. Silakan login ulang.");
      return;
    }

    try {
      // Ambil dokumen user dari koleksi 'users' berdasarkan UID
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // <-- Gunakan 'user' dari variabel lokal
          .get();

      if (doc.exists) {
        setState(() {
          currentUserData = UserData.fromFirestore(doc);
          _isLoading = false;
        });
      } else {
        // Data user tidak ditemukan di Firestore
        setState(() => _isLoading = false);
        _showErrorDialog("Error", "Data user tidak ditemukan di database.");
      }
    } catch (e) {
      // Error saat mengambil data
      setState(() => _isLoading = false);
      _showErrorDialog("Error", "Gagal memuat data: ${e.toString()}");
    }
  }

  // Helper untuk menampilkan error
  void _showErrorDialog(String title, String content) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  // 🔹 Show Profile Modal
  // <-- 6. MODIFIKASI: Baca data dari state 'currentUserData' -->
  void _showProfileModal() {
    // Pastikan data sudah ada sebelum menampilkan modal
    if (currentUserData == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Text(
                "Detail Pengguna",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue),
              ),
            ),
            const Divider(height: 20),
            ModernDetailRow(
                icon: Icons.person,
                label: "Nama",
                value: currentUserData!.nama, // <-- Baca dari state
                color: primaryBlue),
            ModernDetailRow(
                icon: Icons.vpn_key,
                label: "NIM",
                value: currentUserData!.nim, // <-- Baca dari state
                color: Colors.orange),
            ModernDetailRow(
                icon: Icons.email,
                label: "Email",
                value: currentUserData!.email, // <-- Baca dari state
                color: Colors.green),
            const SizedBox(height: 20),
            GradientButton(
              text: "Edit Profil",
              onPressed: () {
                Navigator.pop(context);
                _showEditProfileModal();
              },
            )
          ],
        ),
      ),
    );
  }

  // ✏️ Edit Profile Modal
  // <-- 7. MODIFIKASI: Update data ke Firebase saat "Simpan" -->
  void _showEditProfileModal() {
    // 🔥 PERBAIKAN: Ambil user saat ini di dalam fungsi
    final User? user = FirebaseAuth.instance.currentUser;
    // Pastikan data dan user ada
    if (currentUserData == null || user == null) return;

    final nameController = TextEditingController(text: currentUserData!.nama);
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureNewPass = true;
    bool obscureConfirmPass = true;
    bool isSaving = false; // <-- State loading untuk tombol simpan

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: Text(
                      "Edit Profil",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue),
                    ),
                  ),
                  const Divider(height: 20),
                  TextField(
                    controller: nameController,
                    decoration:
                        modernInputDecoration("Nama Lengkap", Icons.person),
                  ),
                  const SizedBox(height: 16),
                  // NIM (Read-Only)
                  TextField(
                    controller:
                        TextEditingController(text: currentUserData!.nim),
                    readOnly: true,
                    decoration: modernInputDecoration(
                            "NIM (Tidak dapat diubah)", Icons.vpn_key)
                        .copyWith(
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Email (Read-Only)
                  TextField(
                    controller:
                        TextEditingController(text: currentUserData!.email),
                    readOnly: true,
                    decoration: modernInputDecoration(
                            "Email (Tidak dapat diubah)", Icons.email)
                        .copyWith(
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password Baru
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNewPass,
                    decoration: modernInputDecoration(
                            "Password Baru (Kosongi jika tidak diubah)",
                            Icons.lock)
                        .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPass
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          modalSetState(() {
                            obscureNewPass = !obscureNewPass;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Konfirmasi Password Baru
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPass,
                    decoration: modernInputDecoration(
                            "Konfirmasi Password Baru", Icons.lock_outline)
                        .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPass
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          modalSetState(() {
                            obscureConfirmPass = !obscureConfirmPass;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          text: isSaving ? "Menyimpan..." : "Simpan",
                          onPressed: isSaving
                              ? () {} // Do nothing if already saving
                              : () async {
                                  // <-- UBAH LOGIKA SIMPAN KE FIREBASE -->

                                  // Validasi Password
                                  if (newPasswordController.text !=
                                      confirmPasswordController.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text("Password baru tidak cocok!"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return; // Hentikan proses simpan
                                  }

                                  modalSetState(() => isSaving = true);

                                  try {
                                    // 1. Update Nama di Firestore
                                    final newName = nameController.text;
                                    if (newName != currentUserData!.nama) {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid) // <-- Gunakan 'user'
                                          .update({'name': newName});
                                    }

                                    // 2. Update Password di Firebase Auth
                                    final newPassword =
                                        newPasswordController.text;
                                    if (newPassword.isNotEmpty) {
                                      await user
                                          .updatePassword(newPassword); // <-- Gunakan 'user'
                                    }

                                    // 3. Sukses
                                    Navigator.pop(context); // Tutup modal
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "Profil berhasil diperbarui!"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    // 4. Muat ulang data di halaman
                                    _loadUserData();
                                  } catch (e) {
                                    // 5. Tangani Error
                                    Navigator.pop(context); // Tutup modal
                                    _showErrorDialog("Gagal Memperbarui",
                                        "Error: ${e.toString()}\n\nJika ingin ganti password, Anda mungkin perlu login ulang terlebih dahulu.");
                                  } finally {
                                    // Hentikan loading di modal jika masih terbuka
                                    if (mounted) {
                                      modalSetState(() => isSaving = false);
                                    }
                                  }
                                },
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 Logout confirmation
  // <-- 8. MODIFIKASI: Panggil Firebase SignOut -->
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Konfirmasi Keluar"),
          ],
        ),
        content: const Text("Apakah Anda yakin ingin keluar dari akun ini?"),
        actions: [
          TextButton(
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Keluar"),
            onPressed: () async { // <-- JADIKAN ASYNC
              Navigator.of(context).pop(); // Tutup dialog

              // Panggil Firebase SignOut
              await FirebaseAuth.instance.signOut();

              // Navigasi ke halaman login (/)
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBackground,
      // <-- 9. LOGIKA LOADING/ERROR DI BODY DIPERBAIKI -->
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : (currentUserData == null) // <-- Cukup cek ini
              ? Center(
                  // Ini adalah tampilan jika _loadUserData gagal (misal: user null)
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Gagal memuat data pengguna.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        GradientButton(
                          text: "Kembali ke Login",
                          onPressed: _showLogoutConfirmation, // Arahkan ke logout
                        )
                      ],
                    ),
                  ),
                )
              : Stack(
                  // Ini adalah tampilan jika sukses
                  children: [
                    ClipPath(
                      clipper: CurvedHeaderClipper(),
                      child: Container(
                        height: 180,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryPurple, primaryBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // <-- Tambahan
                        children: [
                          const SizedBox(height: 10),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(
                              "Akun",
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ModernUserCard(
                              user: currentUserData!, // <-- Gunakan data state
                              onTap: _showProfileModal,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Expanded(
                            child: ListView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                ModernMenuTile(
                                    icon: Icons.info_outline,
                                    title: "Tentang Aplikasi",
                                    color: primaryPurple,
                                    onTap: () {}),
                                ModernMenuTile(
                                    icon: Icons.logout,
                                    title: "Keluar",
                                    color: Colors.redAccent,
                                    onTap: _showLogoutConfirmation),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

// =================== WIDGET MODERN ===================
// (Semua widget di bawah ini tidak perlu diubah, biarkan apa adanya)

class ModernUserCard extends StatelessWidget {
  final UserData user;
  final VoidCallback onTap;

  const ModernUserCard({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: primaryBlue.withOpacity(0.2),
        highlightColor: primaryBlue.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: primaryBlue,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent, width: 2),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.nama,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("NIM: ${user.nim}",
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ModernMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const ModernMenuTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class ModernDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const ModernDetailRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color colorStart;
  final Color colorEnd;

  const GradientButton(
      {super.key,
      required this.text,
      required this.onPressed,
      this.colorStart = primaryPurple,
      this.colorEnd = primaryBlue});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(colors: [colorStart, colorEnd]),
        boxShadow: [
          BoxShadow(
              color: colorStart.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

InputDecoration modernInputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Colors.blueGrey),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2)),
    disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!)),
  );
}