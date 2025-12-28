import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'history_page.dart';
import 'loan_page.dart';
import 'account_page.dart';

// 🎨 Palet warna global
const Color primaryBlue = Color(0xFF2575FC);
const Color primaryPurple = Color(0xFF6A11CB);
const Color lightGreyBackground = Color(0xFFF0F4F8);
const Color darkGreyText = Color(0xFF333333);
const Color accentTextColor = Color(0xFF1E88E5);

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // --- ✨ PERUBAHAN DI SINI ---
    // Kita bungkus setiap halaman dengan KeepAlivePage di sini
    // agar state-nya terjaga saat menggunakan IndexedStack.
    _pages = [
      KeepAlivePage(
        child: DashboardPage(
            key: const PageStorageKey('dashboardKey'), goToPage: goToPage),
      ),
      const KeepAlivePage(
        child: HistoryPage(key: PageStorageKey('historyKey')),
      ),
      const KeepAlivePage(
        child: LoanPage(key: PageStorageKey('loanKey')),
      ),
      const KeepAlivePage(
        child: AccountPage(key: PageStorageKey('accountKey')),
      ),
    ];
    // --- ✨ AKHIR PERUBAHAN ---
  }

  void goToPage(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onItemTapped(int index) {
    goToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- ✨ PERUBAHAN UTAMA DI SINI ---
      // Mengganti AnimatedSwitcher dengan IndexedStack.
      // Ini adalah cara paling ringan untuk menangani
      // BottomNavigationBar karena tidak ada animasi build/destroy,
      // hanya beralih halaman mana yang terlihat.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // --- ✨ AKHIR PERUBAHAN ---

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 26),
              activeIcon: Icon(Icons.home, size: 28),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined, size: 26),
              activeIcon: Icon(Icons.history, size: 28),
              label: "Riwayat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined, size: 26),
              activeIcon: Icon(Icons.add_box, size: 28),
              label: "Peminjaman",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 26),
              activeIcon: Icon(Icons.person, size: 28),
              label: "Akun",
            ),
          ],
        ),
      ),
    );
  }
}

// 📌 Wrapper kustom untuk menjaga state setiap halaman
// (Tidak perlu diubah)
class KeepAlivePage extends StatefulWidget {
  const KeepAlivePage({super.key, required this.child});
  final Widget child;

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}