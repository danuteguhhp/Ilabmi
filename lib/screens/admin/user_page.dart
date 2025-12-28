import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Import Firestore
// import 'package:firebase_core/firebase_core.dart'; // ✅ Jangan lupa init di main()

// =============================================================================
// 1. CONFIG & PALET WARNA
// =============================================================================
const Color primaryBlue = Color(0xFF2575FC);
const Color primaryPurple = Color(0xFF6A11CB);
const Color lightGreyBackground = Color(0xFFF4F6F9);
const Color darkGreyText = Color(0xFF2C3E50);
const Color borderGrey = Color(0xFFBDC3C7);

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // ✅ Pastikan Firebase sudah di-init di main asli Anda
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manajemen User',
      theme: ThemeData(
        scaffoldBackgroundColor: lightGreyBackground,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const UserPage(),
    );
  }
}

// =============================================================================
// 2. DATA MODEL (Disesuaikan dengan Firestore)
// =============================================================================

enum UserRole { mahasiswa, admin }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.mahasiswa:
        return 'Mahasiswa';
      case UserRole.admin:
        return 'Admin';
    }
  }

  // Helper untuk convert String dari Firestore ke Enum
  static UserRole fromString(String? role) {
    if (role == 'admin') return UserRole.admin;
    return UserRole.mahasiswa; // Default
  }
  
  // Helper untuk convert Enum ke String Firestore
  String get toFirestoreString {
    return this == UserRole.admin ? 'admin' : 'mahasiswa';
  }
}

class UserData {
  String id; // ✅ Document ID dari Firestore
  String name;
  String email;
  UserRole role;
  String nim;
  String? password; // Opsional, hati-hati menyimpan password text biasa

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.nim,
    this.password,
  });

  // ✅ Factory untuk convert dari DocumentSnapshot Firestore
  factory UserData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserData(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      nim: data['nim'] ?? '',
      role: UserRoleExtension.fromString(data['role']),
      // Password biasanya tidak di return balik demi keamanan, atau disimpan terpisah
    );
  }

  // ✅ Convert ke Map untuk dikirim ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'nim': nim,
      'role': role.toFirestoreString,
      'createdAt': FieldValue.serverTimestamp(), // Tambahan timestamp
      // 'uid': ... (Sebaiknya dihandle Auth, tapi bisa ditambah jika perlu)
    };
  }
}

// =============================================================================
// 3. HALAMAN UTAMA
// =============================================================================
class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // Firestore Instance
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  UserRole _selectedRole = UserRole.mahasiswa;

  // Helper Snackbar
  void _showSnackbar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // 📝 MODAL FORM (Tambah/Edit ke Firestore)
  void _showFormDialog({UserData? user}) {
    final isEdit = user != null;

    // Reset Form
    _nameController.text = user?.name ?? "";
    _emailController.text = user?.email ?? "";
    _nimController.text = user?.nim ?? "";
    _passwordController.text = ""; // Password selalu kosong saat edit demi keamanan
    _selectedRole = user?.role ?? UserRole.mahasiswa;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 10
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Text(
                      isEdit ? "Edit User" : "Tambah User",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: darkGreyText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField(_nameController, "Nama Lengkap", Icons.person_outline, validator: (v) => (v == null || v.isEmpty) ? "Nama wajib diisi" : null),
                          const SizedBox(height: 14),
                          _buildField(_emailController, "Email Institusi", Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => (v == null || v.isEmpty) ? "Email wajib diisi" : null),
                          const SizedBox(height: 14),
                          _buildField(_nimController, "NIM / NIP", Icons.badge_outlined, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => (v == null || v.isEmpty) ? "NIM wajib diisi" : null),
                          const SizedBox(height: 14),
                          _buildRoleDropdown(setStateSB),
                          // const SizedBox(height: 14),
                          // ⚠️ Note: Password field disembunyikan jika hanya update data profil biasa di Firestore.
                          // Jika ingin update password Authentication, butuh logika khusus (reauthenticate).
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  // ✅ UPDATE / CREATE LOGIC
                                  final Map<String, dynamic> data = {
                                    'name': _nameController.text,
                                    'email': _emailController.text,
                                    'nim': _nimController.text,
                                    'role': _selectedRole.toFirestoreString,
                                  };

                                  if (isEdit) {
                                    // Update Existing Document
                                    await _usersCollection.doc(user.id).update(data);
                                    _showSnackbar("Data diperbarui ✅", color: Colors.orange);
                                  } else {
                                    // Create New Document
                                    data['createdAt'] = FieldValue.serverTimestamp();
                                    // data['uid'] = ... (Jika ingin generate UID manual)
                                    await _usersCollection.add(data);
                                    _showSnackbar("User ditambahkan ✅", color: const Color(0xFF2ECC71));
                                  }
                                  
                                  if (context.mounted) Navigator.pop(sheetContext);
                                } catch (e) {
                                  _showSnackbar("Error: $e", color: Colors.red);
                                }
                              }
                            },
                            child: Text(isEdit ? "Simpan" : "Tambah", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleDropdown(StateSetter setStateSB) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey, width: 1)),
      child: DropdownButtonFormField<UserRole>(
        initialValue: _selectedRole,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.shield_outlined, color: primaryBlue), labelText: "Role", border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero),
        isExpanded: true,
        items: UserRole.values.map((UserRole role) => DropdownMenuItem(value: role, child: Text(role.displayName))).toList(),
        onChanged: (UserRole? newValue) {
          if (newValue != null) setStateSB(() => _selectedRole = newValue);
        },
      ),
    );
  }

  // 🗑️ MODAL HAPUS (Firestore)
  void _confirmDelete(UserData user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const Text("Hapus User", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGreyText), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text("Apakah anda yakin ingin menghapus data ${user.name}? Tindakan ini tidak dapat dibatalkan.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text("Batal", style: TextStyle(color: Colors.grey)))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        try {
                          // ✅ DELETE LOGIC
                          await _usersCollection.doc(user.id).delete();
                          if (context.mounted) Navigator.pop(context);
                          _showSnackbar("User ${user.name} dihapus ❌", color: const Color(0xFFE74C3C));
                        } catch (e) {
                          _showSnackbar("Gagal menghapus: $e", color: Colors.red);
                        }
                      },
                      child: const Text("Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, bool isPassword = false, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryBlue),
        labelText: label,
        filled: true, fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text("Manajemen User", textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 0.8)),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey, width: 0.7)),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}), // Trigger rebuild for client-side filtering
                  decoration: const InputDecoration(hintText: "Cari Nama, NIM, atau Email...", hintStyle: TextStyle(color: Color(0xFF7F8C8D)), prefixIcon: Icon(Icons.search, color: primaryBlue), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ REAL-TIME LIST BUILDER
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _usersCollection.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Terjadi kesalahan koneksi"));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  // Konversi Snapshot ke List<UserData>
                  final allUsers = snapshot.data!.docs.map((doc) => UserData.fromFirestore(doc)).toList();

                  // Filter Client-Side (Search Logic)
                  final query = _searchController.text.toLowerCase();
                  final filteredUsers = allUsers.where((u) {
                    return u.name.toLowerCase().contains(query) ||
                        u.email.toLowerCase().contains(query) ||
                        u.nim.contains(query) ||
                        u.role.displayName.toLowerCase().contains(query);
                  }).toList();

                  if (filteredUsers.isEmpty) {
                     return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search_off_rounded, color: borderGrey, size: 60),
                          SizedBox(height: 10),
                          Text("Data tidak ditemukan", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return UserItemCard(
                        userData: user,
                        onEdit: () => _showFormDialog(user: user),
                        onDelete: () => _confirmDelete(user),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        heroTag: 'user_fab',
        backgroundColor: primaryBlue,
        elevation: 4,
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// =============================================================================
// 4. WIDGET KARTU USER (Tidak Berubah Banyak)
// =============================================================================
class UserItemCard extends StatelessWidget {
  final UserData userData;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserItemCard({super.key, required this.userData, required this.onEdit, required this.onDelete});

  Color _getRoleColor() {
    switch (userData.role) {
      case UserRole.admin: return primaryPurple;
      case UserRole.mahasiswa: return primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey, width: 0.7), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userData.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkGreyText), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(userData.email, style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _getRoleColor().withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _getRoleColor(), width: 1)),
                child: Text(userData.role.displayName, style: TextStyle(color: _getRoleColor(), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: borderGrey),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF7F8C8D)),
                  const SizedBox(width: 8),
                  Text(userData.nim, style: const TextStyle(fontSize: 14, color: darkGreyText, fontWeight: FontWeight.w600, fontFamily: 'Monospace', letterSpacing: 0.5)),
                ],
              ),
              Row(
                children: [
                  Material(color: Colors.transparent, child: InkWell(onTap: onEdit, borderRadius: BorderRadius.circular(8), child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.edit_outlined, color: Colors.orange, size: 20)))),
                  const SizedBox(width: 4),
                  Material(color: Colors.transparent, child: InkWell(onTap: onDelete, borderRadius: BorderRadius.circular(8), child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.delete_outline_rounded, color: Color(0xFFE74C3C), size: 20)))),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}