import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// =============================================================================
// KONFIGURASI WARNA & MODEL
// =============================================================================
const Color primaryBlue = Color(0xFF2575FC);
const Color lightGreyBackground = Color(0xFFF4F6F9);
const Color darkGreyText = Color(0xFF2C3E50);
const Color borderGrey = Color(0xFFBDC3C7);
const Color dangerRed = Color(0xFFE74C3C);

class Alat {
  String nama;
  String kode;
  String kategori;
  int stokTotal;
  int stokTersedia;
  String lokasi;
  String kondisi;

  Alat({
    required this.nama,
    required this.kode,
    required this.kategori,
    required this.stokTotal,
    required this.stokTersedia,
    required this.lokasi,
    required this.kondisi,
  });
}

// =============================================================================
// HALAMAN UTAMA (ALAT PAGE)
// =============================================================================
class AlatPage extends StatefulWidget {
  const AlatPage({super.key});

  @override
  State<AlatPage> createState() => _AlatPageState();
}

class _AlatPageState extends State<AlatPage> {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  
  // Form Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kodeController = TextEditingController();
  final TextEditingController _stokTotalController = TextEditingController();
  final TextEditingController _stokSediaController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  // Data State
  String _filterKetersediaan = "Semua";
  List<String> _kategoriList = ["Elektronik", "Furniture", "Alat Tulis"];
  
  String? _selectedKategori;
  String? _selectedKondisi;

  // Data Dummy
  List<Alat> alatList = [
    Alat(
      nama: "Proyektor Epson X500",
      kode: "PRJ-001",
      kategori: "Elektronik",
      stokTotal: 5,
      stokTersedia: 3,
      lokasi: "Lemari A1",
      kondisi: "Baik",
    ),
    Alat(
      nama: "Laptop ASUS ROG",
      kode: "LPT-045",
      kategori: "Elektronik",
      stokTotal: 2,
      stokTersedia: 0,
      lokasi: "Meja Admin",
      kondisi: "Rusak Ringan",
    ),
    Alat(
      nama: "Kursi Kantor",
      kode: "FUR-102",
      kategori: "Furniture",
      stokTotal: 50,
      stokTersedia: 48,
      lokasi: "Gudang B",
      kondisi: "Baik",
    ),
  ];

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

  // 📝 MODAL BOTTOM SHEET (Form Muncul dari Bawah)
  void _showFormDialog({Alat? alatToEdit}) {
    final isEdit = alatToEdit != null;

    // Reset / Set Initial Values
    _namaController.text = isEdit ? alatToEdit.nama : "";
    _kodeController.text = isEdit ? alatToEdit.kode : "";
    _stokTotalController.text = isEdit ? alatToEdit.stokTotal.toString() : "0";
    _stokSediaController.text = isEdit ? alatToEdit.stokTersedia.toString() : "0";
    _lokasiController.text = isEdit ? alatToEdit.lokasi : "";
    
    _selectedKategori = isEdit ? alatToEdit.kategori : _kategoriList.first;
    _selectedKondisi = isEdit ? alatToEdit.kondisi : "Baik";

    if (isEdit && !_kategoriList.contains(alatToEdit.kategori)) {
       _kategoriList.add(alatToEdit.kategori);
       _selectedKategori = alatToEdit.kategori;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar bisa full screen saat keyboard muncul
      backgroundColor: Colors.transparent, // Transparan agar rounded corner terlihat
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              // Padding ini penting agar form naik saat keyboard muncul
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Tinggi menyesuaikan konten
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar (Garis kecil di atas)
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
                    
                    Text(
                      isEdit ? "Edit Data Alat" : "Tambah Data Alat",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.w800, 
                        color: darkGreyText
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Scrollable Content
                    Flexible(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildField(_kodeController, "Kode Alat", Icons.qr_code),
                              const SizedBox(height: 14),
                              _buildField(_namaController, "Nama Alat", Icons.inventory_2_outlined),
                              const SizedBox(height: 14),

                              _buildDropdown(
                                label: "Kategori",
                                icon: Icons.category_outlined,
                                value: _selectedKategori,
                                items: [
                                  ..._kategoriList.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                                  const DropdownMenuItem(
                                    value: "ADD_NEW",
                                    child: Text("+ Tambah Baru", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val == "ADD_NEW") {
                                    _showAddCategoryDialog(setModalState, (newCat) {
                                      setModalState(() => _selectedKategori = newCat);
                                    });
                                  } else {
                                    setModalState(() => _selectedKategori = val);
                                  }
                                },
                              ),
                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(child: _buildField(_stokTotalController, "Total", Icons.numbers, isNumber: true)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildField(_stokSediaController, "Tersedia", Icons.check_circle_outline, isNumber: true)),
                                ],
                              ),
                              const SizedBox(height: 14),

                              _buildField(_lokasiController, "Lokasi", Icons.location_on_outlined),
                              const SizedBox(height: 14),

                              _buildDropdown(
                                label: "Kondisi",
                                icon: Icons.info_outline,
                                value: _selectedKondisi,
                                items: ["Baik", "Rusak Ringan", "Rusak Berat"]
                                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                                    .toList(),
                                onChanged: (val) => setModalState(() => _selectedKondisi = val),
                              ),
                              const SizedBox(height: 24),

                              // Tombol Simpan Full Width
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final alatBaru = Alat(
                                      nama: _namaController.text,
                                      kode: _kodeController.text,
                                      kategori: _selectedKategori ?? "Lainnya",
                                      stokTotal: int.tryParse(_stokTotalController.text) ?? 0,
                                      stokTersedia: int.tryParse(_stokSediaController.text) ?? 0,
                                      lokasi: _lokasiController.text,
                                      kondisi: _selectedKondisi ?? "Baik",
                                    );

                                    setState(() {
                                      if (isEdit) {
                                         alatToEdit.nama = alatBaru.nama;
                                         alatToEdit.kode = alatBaru.kode;
                                         alatToEdit.kategori = alatBaru.kategori;
                                         alatToEdit.stokTotal = alatBaru.stokTotal;
                                         alatToEdit.stokTersedia = alatBaru.stokTersedia;
                                         alatToEdit.lokasi = alatBaru.lokasi;
                                         alatToEdit.kondisi = alatBaru.kondisi;
                                         _showSnackbar("Data alat diperbarui ✅", color: Colors.orange);
                                      } else {
                                         alatList.add(alatBaru);
                                         _showSnackbar("Alat ditambahkan ✅", color: const Color(0xFF2ECC71));
                                      }
                                    });
                                    Navigator.pop(ctx);
                                  }
                                },
                                child: Text(
                                  isEdit ? "Simpan Perubahan" : "Tambah Data", 
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  void _showAddCategoryDialog(StateSetter parentSetState, Function(String) onAdded) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kategori Baru"),
        content: TextField(
          controller: textCtrl,
          decoration: const InputDecoration(hintText: "Nama Kategori"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (textCtrl.text.isNotEmpty) {
                setState(() => _kategoriList.add(textCtrl.text));
                onAdded(textCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  void _confirmDelete(Alat alat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Alat", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Yakin ingin menghapus ${alat.nama}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Batal", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() => alatList.remove(alat));
              Navigator.pop(context);
              _showSnackbar("Alat dihapus ❌", color: dangerRed);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      validator: (v) => (v == null || v.isEmpty) ? "$label wajib diisi" : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryBlue),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey, width: 1),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryBlue),
          labelText: label,
          border: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero
        ),
        isExpanded: true,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = alatList.where((alat) {
      final matchName = alat.nama.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          alat.kode.toLowerCase().contains(_searchController.text.toLowerCase());
      
      bool matchFilter = true;
      if (_filterKetersediaan == "Tersedia") {
        matchFilter = alat.stokTersedia > 0;
      } else if (_filterKetersediaan == "Habis") {
        matchFilter = alat.stokTersedia == 0;
      }
      return matchName && matchFilter;
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
                "Manajemen Alat",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 0.8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGrey, width: 0.7),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: "Cari Nama atau Kode Alat...",
                    hintStyle: TextStyle(color: Color(0xFF7F8C8D)),
                    prefixIcon: Icon(Icons.search, color: primaryBlue),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ["Semua", "Tersedia", "Habis"].map((filter) {
                  final isSelected = _filterKetersediaan == filter;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      onTap: () => setState(() => _filterKetersediaan = filter),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryBlue : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: isSelected ? primaryBlue : borderGrey, width: 1.5),
                          boxShadow: isSelected
                              ? [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                              : [],
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(color: isSelected ? Colors.white : darkGreyText, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, color: borderGrey, size: 60),
                          const SizedBox(height: 10),
                          const Text("Data tidak ditemukan", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return AlatItemCard(
                          alat: filteredList[index],
                          onEdit: () => _showFormDialog(alatToEdit: filteredList[index]),
                          onDelete: () => _confirmDelete(filteredList[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
  heroTag: 'equipment_fab', // ✅ TAMBAHKAN INI (UNIK)
  backgroundColor: primaryBlue,
  elevation: 4,
  onPressed: () => _showFormDialog(),
  child: const Icon(Icons.add, color: Colors.white),
),

    );
  }
}

class AlatItemCard extends StatelessWidget {
  final Alat alat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AlatItemCard({super.key, required this.alat, required this.onEdit, required this.onDelete});

  Color _getKondisiColor() {
    if (alat.kondisi == "Baik") return const Color(0xFF2ECC71);
    if (alat.kondisi.contains("Rusak")) return dangerRed;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey, width: 0.7),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
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
                    Text(
                      alat.nama,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkGreyText),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${alat.kategori} • ${alat.lokasi}",
                      style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getKondisiColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getKondisiColor(), width: 1),
                ),
                child: Text(
                  alat.kondisi,
                  style: TextStyle(color: _getKondisiColor(), fontSize: 11, fontWeight: FontWeight.bold),
                ),
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
                  const Icon(Icons.qr_code, size: 18, color: Color(0xFF7F8C8D)),
                  const SizedBox(width: 8),
                  Text(
                    alat.kode,
                    style: const TextStyle(fontSize: 14, color: darkGreyText, fontWeight: FontWeight.w600, fontFamily: 'Monospace'),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: lightGreyBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Stok: ${alat.stokTersedia}/${alat.stokTotal}",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkGreyText),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.delete_outline_rounded, color: dangerRed, size: 20),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}