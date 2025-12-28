import 'package:flutter/material.dart';

// 🎨 Palet Warna
const Color primaryBlue = Color(0xFF2575FC);
const Color primaryPurple = Color(0xFF6A11CB);
const Color accentColor = Color(0xFF3498DB);
const Color lightGreyBackground = Color(0xFFF4F6F9);
const Color darkGreyText = Color(0xFF2C3E50);
const Color borderGrey = Color(0xFFBDC3C7);

class DashboardPage extends StatelessWidget {
  final void Function(int)? goToPage;

  const DashboardPage({super.key, this.goToPage});

  // Data Dummy Statistik
  final List<Map<String, dynamic>> monthlyStats = const [
    {"month": "Jan", "value": 15},
    {"month": "Feb", "value": 24},
    {"month": "Mar", "value": 10},
    {"month": "Apr", "value": 35},
    {"month": "Mei", "value": 20},
    {"month": "Jun", "value": 45},
  ];

  // Data Dummy Peminjaman
  final List<Map<String, dynamic>> recentLoans = const [
    {
      "name": "Dina Wulandari",
      "nim": "230155001",
      "device": "Laptop ASUS ROG",
      "dateStart": "14 Okt",
      "dateEnd": "16 Okt",
      "status": "Menunggu Persetujuan",
    },
    {
      "name": "Budi Santoso",
      "nim": "210155201",
      "device": "Kamera DSLR Canon 80D",
      "dateStart": "10 Okt",
      "dateEnd": "12 Okt",
      "status": "Dipinjam",
    },
    {
      "name": "Ahmad Rizky",
      "nim": "200155099",
      "device": "Tripod Takara",
      "dateStart": "01 Okt",
      "dateEnd": "03 Okt",
      "status": "Terlambat",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== HEADER TITLE =====
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "Dashboard Admin",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // [BAGIAN 1] GRID STATISTIK (DIPERBARUI)
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.count(
                    crossAxisCount: 2, // 2 Kolom
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1, // Rasio agar kartu tidak terlalu tinggi
                    children: const [
                      // 1. Total User
                      ModernSummaryCard(
                        title: "Total User",
                        value: "12",
                        color: accentColor,
                        icon: Icons.people_alt_rounded,
                      ),
                      // 2. Total Alat
                      ModernSummaryCard(
                        title: "Total Alat",
                        value: "45",
                        color: Color(0xFF2ECC71), // Hijau
                        icon: Icons.build_circle_rounded,
                      ),
                      // 3. Peminjaman Aktif
                      ModernSummaryCard(
                        title: "Peminjaman Aktif",
                        value: "5",
                        color: Color(0xFF1ABC9C), // Tosca
                        icon: Icons.sync_rounded,
                      ),
                      // 4. Belum Disetujui
                      ModernSummaryCard(
                        title: "Belum Disetujui",
                        value: "3",
                        color: Color(0xFFF39C12), // Oranye/Kuning
                        icon: Icons.pending_actions_rounded,
                      ),
                      // 5. Terlambat
                      ModernSummaryCard(
                        title: "Terlambat",
                        value: "2",
                        color: Color(0xFFE74C3C), // Merah
                        icon: Icons.warning_rounded,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // [BAGIAN 2] GRAFIK PEMINJAMAN
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGrey, width: 0.7),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Grafik Peminjaman",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: darkGreyText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 150,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: monthlyStats.map((data) {
                          return SimpleBarChartItem(
                            label: data['month'],
                            value: data['value'],
                            maxVal: 50,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // [BAGIAN 3] LIST PEMINJAMAN TERBARU
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGrey, width: 0.7),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Peminjaman Terbaru",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700, color: darkGreyText),
                        ),
                        Icon(Icons.list_alt_rounded, color: primaryBlue),
                      ],
                    ),
                    const Divider(height: 30),
                    ...recentLoans.map((loan) {
                      return LoanItemCard(
                        name: loan['name'],
                        nim: loan['nim'],
                        device: loan['device'],
                        dateStart: loan['dateStart'],
                        dateEnd: loan['dateEnd'],
                        status: loan['status'],
                      );
                    }),
                    const SizedBox(height: 10),
                    // Tombol untuk pindah ke Tab Peminjaman (index 3)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (goToPage != null) goToPage!(3);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Lihat Selengkapnya",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET COMPONENTS
// =========================================================================

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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey, width: 0.7),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: darkGreyText)),
        ],
      ),
    );
  }
}

class SimpleBarChartItem extends StatelessWidget {
  final String label;
  final int value;
  final int maxVal;

  const SimpleBarChartItem({
    super.key,
    required this.label,
    required this.value,
    required this.maxVal,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = (value / maxVal).clamp(0.0, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value.toString(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryBlue)),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 100 * percentage,
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class LoanItemCard extends StatelessWidget {
  final String name;
  final String nim;
  final String device;
  final String dateStart;
  final String dateEnd;
  final String status;

  const LoanItemCard({
    super.key,
    required this.name,
    required this.nim,
    required this.device,
    required this.dateStart,
    required this.dateEnd,
    required this.status,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'Menunggu Persetujuan': return const Color(0xFF9B59B6);
      case 'Dipinjam': return const Color(0xFFF39C12);
      case 'Terlambat': return const Color(0xFFE74C3C);
      case 'Dikembalikan': return const Color(0xFF2ECC71);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(nim, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getStatusColor()),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: _getStatusColor(), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 16, color: primaryBlue),
              const SizedBox(width: 6),
              Expanded(child: Text(device, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.date_range, size: 16, color: Colors.purple),
              const SizedBox(width: 6),
              Text("$dateStart - $dateEnd", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}