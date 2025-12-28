import 'package:flutter/material.dart';

// 🎨 Palet warna modern
const Color primaryBlue = Color(0xFF2575FC);
const Color primaryPurple = Color(0xFF6A11CB);
const Color lightGreyBackground = Color(0xFFF0F4F8);
const Color darkGreyText = Color(0xFF333333);
const Color accentTextColor = Color(0xFF1E88E5);

class LoanPage extends StatefulWidget {
  const LoanPage({super.key});

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  // GlobalKey dipertahankan untuk mengontrol validasi Form (tampilan)
  final _formKey = GlobalKey<FormState>();

  // Semua Controller dipertahankan untuk mengontrol input (tampilan)
  final arsipController = TextEditingController();
  final deskripsiController = TextEditingController();
  final tglPinjamController = TextEditingController();
  final deadlineController = TextEditingController();

  final List<String> daftarAlat = [
    "Laptop Asus",
    "Proyektor Epson",
    "Printer Canon",
    "Router TP-Link",
    "Monitor Samsung",
    "Kamera DSLR Canon",
    "Kabel HDMI 5m",
  ];

  @override
  void dispose() {
    arsipController.dispose();
    deskripsiController.dispose();
    tglPinjamController.dispose();
    deadlineController.dispose();
    super.dispose();
  }

  // 🚫 DUMMY FUNCTION: Hanya menunjukkan pesan Batal
  void _resetFormDummy() {
    // Hanya menampilkan UI notifikasi dummy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Berhasil Membatalkan Pengajuan Peminjaman"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // 🚫 DUMMY FUNCTION: Hanya menampilkan DatePicker UI
  Future<void> _selectDateDummy(
      BuildContext context, TextEditingController controller) async {
    // Tampilkan date picker UI
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    // Update text controller untuk tampilan saja
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  // 🚫 DUMMY FUNCTION: Hanya menunjukkan pesan Berhasil
  void _submitPeminjamanDummy() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Peminjaman Berhasil Diajukan"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Fungsi untuk dekorasi input (UI Helper)
  InputDecoration _buildInputDecoration({
    required String labelText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onTapSuffix,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: Colors.blueGrey) : null,
      suffixIcon: suffixIcon != null
          ? IconButton(
              icon: Icon(suffixIcon, color: primaryBlue),
              onPressed: onTapSuffix,
            )
          : null,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBackground,
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            // 🌊 Background melengkung
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "Ajukan Peminjaman",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 80),

                    // Autocomplete Arsip/Alat
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return daftarAlat;
                        }
                        return daftarAlat.where((option) =>
                            option
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (selection) {
                        arsipController.text = selection;
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                        if (arsipController.text != controller.text) {
                          arsipController.text = controller.text;
                        }
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama arsip/alat wajib diisi';
                            }
                            return null;
                          },
                          decoration: _buildInputDecoration(
                            labelText: "Cari atau Pilih Arsip/Alat",
                            prefixIcon: Icons.search,
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxHeight: 250, maxWidth: 350),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option),
                                    leading: const Icon(
                                        Icons.inventory_2_outlined,
                                        color: primaryBlue,
                                        size: 20),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi
                    TextFormField(
                      controller: deskripsiController,
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Deskripsi peminjaman wajib diisi';
                        }
                        return null;
                      },
                      decoration: _buildInputDecoration(
                        labelText: "Deskripsi Peminjaman",
                        prefixIcon: Icons.description,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Pinjam
                    TextFormField(
                      controller: tglPinjamController,
                      readOnly: true,
                      onTap: () => _selectDateDummy(context, tglPinjamController),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tanggal pinjam wajib diisi';
                        }
                        return null;
                      },
                      decoration: _buildInputDecoration(
                        labelText: "Tanggal Pinjam",
                        prefixIcon: Icons.date_range,
                        suffixIcon: Icons.calendar_today,
                        onTapSuffix: () =>
                            _selectDateDummy(context, tglPinjamController),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deadline
                    TextFormField(
                      controller: deadlineController,
                      readOnly: true,
                      onTap: () => _selectDateDummy(context, deadlineController),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Deadline wajib diisi';
                        }
                        return null;
                      },
                      decoration: _buildInputDecoration(
                        labelText: "Deadline Pengembalian",
                        prefixIcon: Icons.access_time,
                        suffixIcon: Icons.calendar_today,
                        onTapSuffix: () =>
                            _selectDateDummy(context, deadlineController),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Tombol Batal & Ajukan
                    Row(
                      children: [
                        // 🌟 MODIFIKASI: Menggunakan RedSolidButton untuk konsistensi bentuk
                        Expanded(
                          child: RedSolidButton(
                            text: "BATAL",
                            onPressed: _resetFormDummy,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GradientButton(
                            text: "AJUKAN",
                            onPressed: _submitPeminjamanDummy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🌈 Lengkungan header (Tidak diubah)
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

// 🔘 Gradient Button Modern (Tidak diubah)
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color colorStart;
  final Color colorEnd;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.colorStart = primaryPurple,
    this.colorEnd = primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
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

// 🌟 WIDGET BARU: Tombol Solid Merah Konsisten
class RedSolidButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const RedSolidButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Menggunakan struktur yang mirip dengan GradientButton
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: color, // Warna solid
        borderRadius: BorderRadius.circular(40), // Bentuk konsisten
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.25),
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
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}