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
      title: 'Manajemen Peminjaman',
      theme: ThemeData(
        scaffoldBackgroundColor: lightGreyBackground,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoanPage(),
    );
  }
}

// =============================================================================
// 2. DATA MODEL
// =============================================================================
class Loan {
  final String peminjam;
  final String nim;
  final String alat;
  final String tanggal;
  final String deadline;
  final String lokasi;
  String status;
  String alasan;
  final bool isLate;

  Loan({
    required this.peminjam,
    required this.nim,
    required this.alat,
    required this.tanggal,
    required this.deadline,
    required this.lokasi,
    this.status = "Menunggu Persetujuan",
    this.alasan = "",
    required this.isLate,
  });

  factory Loan.fromMap(Map<String, String> map) {
    final now = DateTime(2025, 10, 15); 

    DateTime deadlineDate;
    try {
      deadlineDate = DateTime.parse(map["deadline"]!);
    } catch (e) {
      deadlineDate = now.subtract(const Duration(days: 1));
    }

    final status = map["status"] ?? "Menunggu Persetujuan";
    final isOverdue = status == "Disetujui" && now.isAfter(deadlineDate);

    return Loan(
      peminjam: map["peminjam"] ?? "Tanpa Nama",
      nim: map["nim"] ?? "-",
      alat: map["alat"] ?? "Alat Tidak Diketahui",
      tanggal: map["tanggal"] ?? "-",
      deadline: map["deadline"] ?? "-",
      lokasi: map["lokasi"] ?? "Gudang Utama",
      status: status,
      alasan: map["alasan"] ?? "",
      isLate: isOverdue,
    );
  }

  Loan copyWith({String? status, String? alasan}) {
    final now = DateTime(2025, 10, 15);
    DateTime deadlineDate;
    try {
      deadlineDate = DateTime.parse(deadline);
    } catch (e) {
      deadlineDate = now.subtract(const Duration(days: 1));
    }

    final newStatus = status ?? this.status;
    final newIsLate = newStatus == "Disetujui" && now.isAfter(deadlineDate);

    return Loan(
      peminjam: peminjam,
      nim: nim,
      alat: alat,
      tanggal: tanggal,
      deadline: deadline,
      lokasi: lokasi,
      status: newStatus,
      alasan: alasan ?? this.alasan,
      isLate: newIsLate,
    );
  }
}

// =============================================================================
// 3. HALAMAN UTAMA
// =============================================================================
class LoanPage extends StatefulWidget {
  const LoanPage({super.key});

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  String selectedFilter = "Semua";
  final List<String> filters = [
    "Semua", "Menunggu Persetujuan", "Masih Dipinjam", "Telat", "Dikembalikan", "Ditolak",
  ];

  final List<Map<String, String>> initialLoanData = [
    {"peminjam": "Rina", "nim": "19001001", "alat": "Kamera DSLR Canon", "lokasi": "Lemari A1", "tanggal": "2025-10-14", "deadline": "2025-10-17", "status": "Menunggu Persetujuan"},
    {"peminjam": "Bambang", "nim": "19001002", "alat": "Mic Wireless Shure", "lokasi": "Rak Audio B2", "tanggal": "2025-10-10", "deadline": "2025-10-13", "status": "Menunggu Persetujuan"},
    {"peminjam": "Siti", "nim": "19001003", "alat": "Proyektor Epson", "lokasi": "Meja Admin", "tanggal": "2025-10-09", "deadline": "2025-10-20", "status": "Disetujui"},
    {"peminjam": "Agus", "nim": "19001006", "alat": "Speaker Portable", "lokasi": "Gudang Belakang", "tanggal": "2025-09-28", "deadline": "2025-10-14", "status": "Disetujui"}, 
    {"peminjam": "Putri", "nim": "19001008", "alat": "Drone DJI Mini", "lokasi": "Lemari Khusus", "tanggal": "2025-09-01", "deadline": "2025-09-05", "status": "Dikembalikan"},
    {"peminjam": "Fajar", "nim": "19001010", "alat": "Stabilizer Gimbal", "lokasi": "Rak C3", "tanggal": "2025-10-01", "deadline": "2025-10-03", "status": "Ditolak", "alasan": "Alat sedang diservis rutin."},
  ];

  late List<Loan> loanList;

  @override
  void initState() {
    super.initState();
    loanList = initialLoanData.map((e) => Loan.fromMap(e)).toList();
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

  void updateStatus(int index, String newStatus, {String alasan = ""}) {
    setState(() {
      loanList[index] = loanList[index].copyWith(status: newStatus, alasan: alasan);
    });
    
    Color color = primaryBlue;
    if (newStatus == "Disetujui") color = successGreen;
    if (newStatus == "Ditolak") color = dangerRed;
    if (newStatus == "Dikembalikan") color = successGreen;
    
    _showSnackbar("Status diperbarui: $newStatus", color: color);
  }

  // 🔄 🚀 UNIFIED PROCESS SHEET (APPROVE, REJECT, RETURN)
  void _showActionProcessSheet(int index, String actionType) {
    final loan = loanList[index];
    
    // Init State Lokal
    String kondisiAlat = "Baik"; 
    bool lokasiSesuai = false;
    TextEditingController reasonController = TextEditingController();
    
    // 🟢 START STEP LOGIC
    // Jika Approve: Langsung ke Step 2 (Preview)
    // Jika Reject/Return: Step 1 (Input)
    int currentStep = actionType == "Approve" ? 2 : 1; 
    
    bool isVerifying = false;

    // Setup Teks & Warna
    Color themeColor = primaryBlue;
    String titleText = "Proses";
    
    if (actionType == "Approve") {
      themeColor = successGreen;
      titleText = "Persetujuan Peminjaman";
    } else if (actionType == "Reject") {
      themeColor = dangerRed;
      titleText = "Penolakan Peminjaman";
    } else {
      themeColor = primaryBlue; // Return
      titleText = "Proses Pengembalian";
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Title
                    Text(
                      currentStep == 3 ? "Verifikasi Wajah" : titleText,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: themeColor),
                    ),
                    const SizedBox(height: 20),

                    // =========================================================
                    // CONTENT AREA
                    // =========================================================
                    if (currentStep == 1) ...[
                      // --- STEP 1: INPUT DATA (Hanya untuk Return & Reject) ---
                      
                      if (actionType == "Return") ...[
                        const Text("1. Konfirmasi Kondisi Alat", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildRadioOption("Baik", "Baik", kondisiAlat, primaryBlue, (val) => setSheetState(() => kondisiAlat = val)),
                        _buildRadioOption("Rusak Ringan", "Rusak Ringan", kondisiAlat, primaryBlue, (val) => setSheetState(() => kondisiAlat = val)),
                        _buildRadioOption("Rusak Berat", "Rusak Berat", kondisiAlat, primaryBlue, (val) => setSheetState(() => kondisiAlat = val)),
                        
                        const Divider(height: 24),
                        const Text("2. Konfirmasi Lokasi", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildLocationInfo(loan.lokasi),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          title: const Text("Alat sudah diletakkan di lokasi yang sesuai"),
                          value: lokasiSesuai,
                          activeColor: primaryBlue,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setSheetState(() => lokasiSesuai = val!),
                        ),
                      ] 
                      else if (actionType == "Reject") ...[
                        const Text("Alasan Penolakan:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: reasonController,
                          decoration: InputDecoration(
                            hintText: "Contoh: Alat sedang rusak / Stok habis",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          maxLines: 3,
                        ),
                      ]

                    ] else if (currentStep == 2) ...[
                      // --- STEP 2: PREVIEW (Berlaku untuk SEMUA) ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: lightGreyBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _previewRow("Tindakan", 
                              actionType == "Return" ? "Pengembalian" : actionType == "Approve" ? "Persetujuan" : "Penolakan", 
                              isBold: true, color: themeColor),
                            const Divider(),
                            _previewRow("Peminjam", loan.peminjam),
                            _previewRow("Alat", loan.alat),
                            
                            // Info Khusus Return
                            if (actionType == "Return") ...[
                              _previewRow("Kondisi", kondisiAlat, isBold: true, color: kondisiAlat == "Baik" ? successGreen : dangerRed),
                              _previewRow("Lokasi", "Meja Admi", isBold: true),
                            ],
                            
                            // Info Khusus Reject
                            if (actionType == "Reject")
                              _previewRow("Alasan", reasonController.text, color: dangerRed),
                              
                            // Info Khusus Approve
                            if (actionType == "Approve")
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text("Menyetujui peminjaman ini akan mengubah status menjadi 'Disetujui'.", 
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey), textAlign: TextAlign.center),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Lanjutkan untuk verifikasi wajah admin.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                    ] else if (currentStep == 3) ...[
                      // --- STEP 3: VERIFIKASI WAJAH ---
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            height: 120,
                            width: 120,
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isVerifying ? themeColor : successGreen,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      )
                    ],

                    const SizedBox(height: 24),

                    // =========================================================
                    // BUTTONS AREA
                    // =========================================================
                    if (currentStep < 3)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                // Logic Tombol Kiri (Batal/Kembali)
                                if (currentStep == 2 && actionType == "Approve") {
                                  // Jika Approve, Step 2 adalah step pertama, jadi tombolnya 'Batal' (Tutup)
                                  Navigator.pop(context);
                                } else if (currentStep == 2) {
                                  // Jika lainnya, Step 2 bisa 'Kembali' ke Step 1
                                  setSheetState(() => currentStep = 1);
                                } else {
                                  // Default 'Batal' (Tutup)
                                  Navigator.pop(context);
                                }
                              },
                              child: Text(
                                // Text Label Button
                                (currentStep == 2 && actionType == "Approve") || currentStep == 1 
                                  ? "Batal" 
                                  : "Kembali", 
                                style: const TextStyle(color: Colors.grey)
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentStep == 1 ? themeColor : primaryPurple,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                // Logic Tombol Kanan (Lanjut)
                                if (currentStep == 1) {
                                  // Validasi Input
                                  if (actionType == "Return" && !lokasiSesuai) return; 
                                  if (actionType == "Reject" && reasonController.text.isEmpty) {
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alasan harus diisi")));
                                     return;
                                  }
                                  setSheetState(() => currentStep = 2);
                                } else {
                                  // Masuk ke Verifikasi
                                  setSheetState(() {
                                    currentStep = 3;
                                    isVerifying = true;
                                  });
                                  
                                  // Simulasi Proses Verifikasi
                                  Future.delayed(const Duration(seconds: 3), () {
                                     if (context.mounted) {
                                       setSheetState(() => isVerifying = false);
                                       Future.delayed(const Duration(seconds: 1), () {
                                         if(context.mounted) {
                                            // FINAL ACTION
                                            String finalStatus = "";
                                            String finalReason = "";
                                            
                                            if (actionType == "Approve") finalStatus = "Disetujui";
                                            if (actionType == "Reject") {
                                              finalStatus = "Ditolak";
                                              finalReason = reasonController.text;
                                            }
                                            if (actionType == "Return") finalStatus = "Dikembalikan";

                                            updateStatus(index, finalStatus, alasan: finalReason);
                                            Navigator.pop(context);
                                         }
                                       });
                                     }
                                  });
                                }
                              },
                              child: Text(
                                currentStep == 1 ? "Selanjutnya" : "Verifikasi Wajah", 
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

  // --- Helper Widgets ---

  Widget _buildRadioOption(String title, String value, String groupValue, Color color, Function(String) onChanged) {
    return RadioListTile<String>(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: groupValue == value ? color : darkGreyText)),
      value: value,
      groupValue: groupValue,
      activeColor: color,
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
      onChanged: (val) { if (val != null) onChanged(val); },
    );
  }

  Widget _buildLocationInfo(String lokasi) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Lokasi Penyimpanan:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                Text(lokasi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkGreyText)),
              ],
            ),
          ),
        ],
      ),
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
    final filtered = loanList.where((loan) {
      if (selectedFilter == "Semua") return true;
      if (selectedFilter == "Menunggu Persetujuan") return loan.status == "Menunggu Persetujuan";
      if (selectedFilter == "Masih Dipinjam") return loan.status == "Disetujui" && !loan.isLate;
      if (selectedFilter == "Telat") return loan.status == "Disetujui" && loan.isLate;
      return loan.status == selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: lightGreyBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "Manajemen Peminjaman",
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
                          Icon(Icons.assignment_outlined, color: borderGrey, size: 60),
                          const SizedBox(height: 10),
                          const Text("Data tidak ditemukan", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final data = filtered[index];
                        final originalIndex = loanList.indexOf(data);
                        return LoanItemCard(
                          loan: data,
                          // 🚀 SEMUA AKSI MEMANGGIL FUNGSI UNIFIED SHEET
                          onApprove: () => _showActionProcessSheet(originalIndex, "Approve"),
                          onReject: () => _showActionProcessSheet(originalIndex, "Reject"),
                          onReturn: () => _showActionProcessSheet(originalIndex, "Return"),
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
class LoanItemCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onReturn;

  const LoanItemCard({
    super.key,
    required this.loan,
    required this.onApprove,
    required this.onReject,
    required this.onReturn,
  });

  Color _getStatusColor() {
    if (loan.status == "Disetujui" && loan.isLate) return dangerRed;
    if (loan.status == "Disetujui") return warningOrange;
    if (loan.status == "Dikembalikan") return successGreen;
    if (loan.status == "Ditolak") return Colors.grey;
    return primaryBlue;
  }

  String _getStatusText() {
    if (loan.status == "Disetujui" && loan.isLate) return "Telat";
    if (loan.status == "Disetujui") return "Dipinjam";
    return loan.status;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Icon(Icons.person_outline, size: 20, color: Color(0xFF7F8C8D)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.peminjam,
                            style: const TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold, 
                              color: darkGreyText
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loan.nim,
                            style: const TextStyle(
                              fontSize: 12, 
                              color: Color(0xFF7F8C8D),
                              fontFamily: 'Monospace'
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: lightGreyBackground),
          const SizedBox(height: 8),

          Text(
            loan.alat,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: darkGreyText,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              _dateInfo(Icons.calendar_today, "Pinjam", loan.tanggal),
              const SizedBox(width: 20),
              _dateInfo(
                Icons.event_busy, 
                "Deadline", 
                loan.deadline, 
                isDanger: loan.isLate && loan.status == 'Disetujui'
              ),
            ],
          ),

          if (loan.status == "Ditolak" && loan.alasan.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Alasan: ${loan.alasan}",
                style: const TextStyle(fontSize: 12, color: dangerRed, fontStyle: FontStyle.italic),
              ),
            ),

          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (loan.status == "Menunggu Persetujuan") ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onReject,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: dangerRed),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.close, size: 16, color: dangerRed),
                          SizedBox(width: 4),
                          Text("Tolak", style: TextStyle(color: dangerRed, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 16, color: Colors.white),
                  label: const Text("Setujui", style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ] else if (loan.status == "Disetujui") ...[
                ElevatedButton.icon(
                  onPressed: onReturn,
                  icon: const Icon(Icons.keyboard_return, size: 16, color: Colors.white),
                  label: const Text("Tandai Kembali", style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ] else ...[
                const Text("Selesai", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateInfo(IconData icon, String label, String value, {bool isDanger = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDanger ? dangerRed : Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            Text(
              value, 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                color: isDanger ? dangerRed : darkGreyText
              )
            ),
          ],
        )
      ],
    );
  }
}