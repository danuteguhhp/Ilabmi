import 'package:flutter/material.dart';
import 'dart:async';

// =============================================================================
// 1. CONFIG & PALET WARNA
// =============================================================================
const Color primaryBlue = Color(0xFF2575FC);
const Color primaryPurple = Color(0xFF6A11CB);
const Color lightGreyBackground = Color(0xFFF4F6F9);
const Color darkGreyText = Color(0xFF2C3E50);
const Color borderGrey = Color(0xFFBDC3C7);
const Color dangerRed = Color(0xFFE74C3C);
const Color successGreen = Color(0xFF2ECC71);
const Color warningOrange = Color(0xFFF39C12);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Riwayat Peminjaman',
      theme: ThemeData(
        scaffoldBackgroundColor: lightGreyBackground,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HistoryPage(),
    );
  }
}

// =============================================================================
// 2. DATA MODEL
// =============================================================================
class Peminjaman {
  final String nama;
  final String deskripsi;
  final String tglPinjam;
  final String deadline;
  final String status;
  final bool isOverdue;

  Peminjaman({
    required this.nama,
    required this.deskripsi,
    required this.tglPinjam,
    required this.deadline,
    required this.status,
    required this.isOverdue,
  });

  factory Peminjaman.fromMap(Map<String, String> map) {
    final now = DateTime(2025, 10, 05); 
    DateTime deadlineDate;
    try {
      deadlineDate = DateTime.parse(map["deadline"]!);
    } catch (e) {
      deadlineDate = now.subtract(const Duration(days: 1));
    }
    
    // Logika Overdue hanya jika statusnya "Belum Kembali" (barang ada di user)
    final isOverdue = map["status"] == "Belum Kembali" && now.isAfter(deadlineDate);
    
    return Peminjaman(
      nama: map["nama"]!,
      deskripsi: map["deskripsi"]!,
      tglPinjam: map["tglPinjam"]!,
      deadline: map["deadline"]!,
      status: map["status"]!,
      isOverdue: isOverdue,
    );
  }

  Peminjaman copyWith({String? status}) {
    return Peminjaman(
      nama: nama,
      deskripsi: deskripsi,
      tglPinjam: tglPinjam,
      deadline: deadline,
      status: status ?? this.status,
      isOverdue: isOverdue,
    );
  }
}

// =============================================================================
// 3. HALAMAN UTAMA
// =============================================================================
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedFilter = "Semua";
  final List<String> filters = [
    "Semua", "Menunggu", "Belum Kembali", "Telat", "Dikembalikan", "Dibatalkan",
  ];

  // Data Dummy
  final List<Map<String, String>> riwayatData = [
    {
      "nama": "Tripod Kamera",
      "deskripsi": "Digunakan untuk dokumentasi outdoor",
      "tglPinjam": "2025-10-06",
      "deadline": "2025-10-08",
      "status": "Menunggu Konfirmasi" // 🔥 KASUS 1: Pengajuan Baru (Bisa Dibatalkan)
    },
    {
      "nama": "Speaker Portable",
      "deskripsi": "Untuk kegiatan workshop",
      "tglPinjam": "2025-10-05",
      "deadline": "2025-10-12",
      "status": "Menunggu Persetujuan" // 🔥 KASUS 2: Sedang verifikasi pengembalian (Hanya Teks)
    },
    {
      "nama": "Laptop Asus",
      "deskripsi": "Laptop untuk presentasi kelas A",
      "tglPinjam": "2025-10-01",
      "deadline": "2025-10-05",
      "status": "Belum Kembali"
    },
    {
      "nama": "Proyektor Epson",
      "deskripsi": "Digunakan untuk seminar internal",
      "tglPinjam": "2025-10-02",
      "deadline": "2025-10-15",
      "status": "Belum Kembali"
    },
    {
      "nama": "Kabel HDMI",
      "deskripsi": "Dipakai untuk lab komputer",
      "tglPinjam": "2025-09-28",
      "deadline": "2025-09-30",
      "status": "Dikembalikan"
    },
  ];

  late List<Peminjaman> riwayat;

  @override
  void initState() {
    super.initState();
    riwayat = riwayatData.map((e) => Peminjaman.fromMap(e)).toList();
  }

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

  List<Peminjaman> getFilteredHistory() {
    switch (selectedFilter) {
      case "Semua": return riwayat;
      case "Dikembalikan": return riwayat.where((e) => e.status == "Dikembalikan").toList();
      case "Telat": return riwayat.where((e) => e.isOverdue).toList();
      case "Belum Kembali": return riwayat.where((e) => e.status == "Belum Kembali" && !e.isOverdue).toList();
      // Menggabungkan kedua status "Menunggu" ke dalam filter Menunggu
      case "Menunggu": return riwayat.where((e) => e.status.contains("Menunggu")).toList();
      case "Dibatalkan": return riwayat.where((e) => e.status == "Dibatalkan").toList();
      default: return riwayat;
    }
  }

  void updateStatus(int index, String newStatus) {
    setState(() {
      riwayat[index] = riwayat[index].copyWith(status: newStatus);
    });
    
    Color color = primaryBlue;
    if (newStatus == "Dibatalkan") color = dangerRed;
    if (newStatus == "Menunggu Persetujuan") color = successGreen;

    _showSnackbar("Status diperbarui: $newStatus", color: color);
  }

  // 🔄 🚀 LOGIKA MODAL / SHEET (Updated: Cancel Now Uses Face ID)
  void _showUserActionProcessSheet(int index, String actionType) {
    final item = riwayat[index];
    bool isVerifying = false;
    int currentStep = 1;

    Color themeColor = primaryBlue;
    String titleText = "";
    
    if (actionType == "RequestReturn") {
      themeColor = primaryBlue;
      titleText = "Ajukan Pengembalian";
    } else {
      themeColor = dangerRed;
      titleText = "Batalkan Peminjaman";
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
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
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Title
                    Text(
                      currentStep == 2 ? "Verifikasi Wajah" : titleText,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: themeColor),
                    ),
                    const SizedBox(height: 20),

                    // =========================================================
                    // CONTENT AREA
                    // =========================================================
                    
                    // --- STEP 1: PREVIEW ---
                    if (currentStep == 1) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: lightGreyBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                             _previewRow("Tindakan", 
                                actionType == "RequestReturn" ? "Pengembalian Alat" : "Pembatalan Peminjaman", 
                                isBold: true, color: themeColor),
                            const Divider(),
                            _previewRow("Alat", item.nama, isBold: true),
                            _previewRow("Deskripsi", item.deskripsi),
                            
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                "Lanjutkan untuk verifikasi wajah pengguna.", 
                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey), 
                                textAlign: TextAlign.center
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      Text(
                        actionType == "RequestReturn" 
                          ? "Pastikan alat dalam kondisi baik."
                          : "Apakah Anda yakin ingin membatalkan?",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                    // --- STEP 2: VERIFIKASI WAJAH ---
                    ] else if (currentStep == 2) ...[
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            height: 120, width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                              border: Border.all(color: isVerifying ? themeColor : successGreen, width: 3),
                            ),
                            child: isVerifying
                                ? Center(child: CircularProgressIndicator(color: themeColor))
                                : const Icon(Icons.face_retouching_natural, size: 60, color: successGreen),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isVerifying ? "Memindai Wajah..." : "Verifikasi Berhasil!",
                            style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold,
                              color: isVerifying ? themeColor : successGreen,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if(isVerifying)
                            const Text("Mohon jangan tutup aplikasi", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      )
                    ],

                    const SizedBox(height: 24),

                    // =========================================================
                    // BUTTONS AREA
                    // =========================================================
                    if (currentStep != 2) 
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                // 🔥 Keduanya (Kembali & Batal) masuk ke Step 2 (Verifikasi Wajah)
                                setSheetState(() {
                                  currentStep = 2;
                                  isVerifying = true;
                                });
                                
                                Future.delayed(const Duration(seconds: 3), () {
                                  if (context.mounted) {
                                    setSheetState(() => isVerifying = false);
                                    Future.delayed(const Duration(seconds: 1), () {
                                      if (context.mounted) {
                                        // Update Status sesuai Action
                                        if (actionType == "RequestReturn") {
                                          updateStatus(index, "Menunggu Persetujuan");
                                        } else {
                                          updateStatus(index, "Dibatalkan");
                                        }
                                        Navigator.pop(context);
                                      }
                                    });
                                  }
                                });
                              },
                              child: Text(
                                actionType == "RequestReturn" ? "Lanjut Verifikasi" : "Ya, Batalkan",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _previewRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? darkGreyText,
              )
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = getFilteredHistory();

    return Scaffold(
      backgroundColor: lightGreyBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "Riwayat Peminjaman",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: filters.map((filter) {
                    final isSelected = selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () => setState(() => selectedFilter = filter),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected ? primaryBlue : borderGrey,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                : [],
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : darkGreyText,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off, color: borderGrey, size: 60),
                          const SizedBox(height: 10),
                          const Text("Tidak ada riwayat", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final originalItem = filtered[index];
                        final originalIndex = riwayat.indexOf(originalItem);
                        
                        return HistoryItemCard(
                          data: originalItem,
                          onReturnRequest: () => _showUserActionProcessSheet(originalIndex, "RequestReturn"),
                          onCancelRequest: () => _showUserActionProcessSheet(originalIndex, "Cancel"),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 4. WIDGET KARTU PEMINJAMAN
// =============================================================================
class HistoryItemCard extends StatelessWidget {
  final Peminjaman data;
  final VoidCallback onReturnRequest;
  final VoidCallback onCancelRequest;

  const HistoryItemCard({
    super.key,
    required this.data,
    required this.onReturnRequest,
    required this.onCancelRequest,
  });

  Color _getStatusColor() {
    if (data.status == "Dikembalikan") return successGreen;
    if (data.status == "Dibatalkan") return Colors.grey;
    if (data.status.contains("Menunggu")) return primaryBlue;
    if (data.isOverdue) return dangerRed;
    return warningOrange;
  }

  String _getStatusText() {
    if (data.status == "Dikembalikan") return "Selesai";
    if (data.isOverdue) return "Telat";
    if (data.status == "Belum Kembali") return "Dipinjam";
    if (data.status == "Menunggu Persetujuan") return "Verifikasi";
    if (data.status == "Menunggu Konfirmasi") return "Diajukan";
    return data.status;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey, width: 0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.devices_other, size: 20, color: primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.nama,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: darkGreyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.deskripsi,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: lightGreyBackground),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align top agar teks status bisa turun
            children: [
              Expanded(
                flex: 2, // Memberi porsi lebih untuk tanggal
                child: Row(
                  children: [
                    _dateInfo(Icons.calendar_today, "Pinjam", data.tglPinjam),
                    const SizedBox(width: 16),
                    _dateInfo(Icons.event_busy, "Deadline", data.deadline, isDanger: data.isOverdue),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),

              // 🔥 LOGIKA STATUS & BUTTON
              // Menggunakan Flexible agar teks bisa turun ke bawah jika sempit
              if (data.status == "Belum Kembali")
                ElevatedButton.icon(
                  onPressed: onReturnRequest,
                  icon: const Icon(Icons.assignment_return, size: 16, color: Colors.white),
                  label: const Text("Kembalikan", style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                  ),
                )
              // Jika baru diajukan (Menunggu Konfirmasi), bisa dibatalkan
              else if (data.status == "Menunggu Konfirmasi")
                 OutlinedButton(
                    onPressed: onCancelRequest,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: dangerRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("Batalkan", style: TextStyle(color: dangerRed, fontSize: 12)),
                  )
              // Jika Menunggu Persetujuan (Pengembalian), hanya teks status yang bisa wrapping
              else if (data.status == "Menunggu Persetujuan")
                const Flexible(
                  fit: FlexFit.loose,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.hourglass_top, size: 14, color: primaryBlue),
                      SizedBox(width: 4),
                      Flexible( // 🔥 INI YANG MEMBUAT TEKS TURUN JIKA KEPANJANGAN
                        child: Text(
                          "Menunggu Konfirmasi Admin",
                          textAlign: TextAlign.right,
                          style: TextStyle(color: primaryBlue, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateInfo(IconData icon, String label, String value, {bool isDanger = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: isDanger ? dangerRed : Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
        Text(
          value, 
          style: TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            color: isDanger ? dangerRed : darkGreyText
          )
        ),
      ],
    );
  }
}