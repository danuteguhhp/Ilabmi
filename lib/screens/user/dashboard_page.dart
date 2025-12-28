import 'package:flutter/material.dart';


// =============================================================================
// 1. CONFIG & PALET WARNA (Sesuai Style Global)
// =============================================================================
const Color primaryBlue = Color(0xFF2575FC);
const Color primaryPurple = Color(0xFF6A11CB);
const Color lightGreyBackground = Color(0xFFF4F6F9);
const Color darkGreyText = Color(0xFF2C3E50);
const Color borderGrey = Color(0xFFBDC3C7);

class DashboardPage extends StatelessWidget {
  // Callback untuk navigasi antar halaman
  final void Function(int)? goToPage;

  const DashboardPage({super.key, this.goToPage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  "Dashboard",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // Grid Statistik
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: const [
                      ModernSummaryCard(
                        title: "Berlangsung",
                        value: "0",
                        color: primaryBlue,
                        icon: Icons.hourglass_top_rounded,
                      ),
                      ModernSummaryCard(
                        title: "Disetujui",
                        value: "0",
                        color: Color(0xFF4CAF50),
                        icon: Icons.verified_user_rounded,
                      ),
                      ModernSummaryCard(
                        title: "Belum Kembali",
                        value: "0",
                        color: Color(0xFFFF9800),
                        icon: Icons.access_time_filled_rounded,
                      ),
                      ModernSummaryCard(
                        title: "Dikembalikan",
                        value: "0",
                        color: Color(0xFF607D8B),
                        icon: Icons.assignment_return_rounded,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Section Peminjaman Terbaru (Empty State dengan Tombol)
              const Text(
                "Aktivitas Terbaru",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGreyText,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderGrey, width: 0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: lightGreyBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Belum ada riwayat peminjaman",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // 🟢 TOMBOL PINDAH KE HALAMAN PEMINJAMAN
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Pindah ke tab Peminjaman (index 2)
                          // Pastikan 'goToPage' di-pass dari AdminDashboard
                          goToPage?.call(2);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                        label: const Text(
                          "Buat Peminjaman",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// 🌟 Modern Summary Card
class ModernSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const ModernSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGrey.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: darkGreyText,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}