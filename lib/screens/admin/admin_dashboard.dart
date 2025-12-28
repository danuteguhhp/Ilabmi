import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'user_page.dart';
import 'equipment_page.dart';
import 'loan_page.dart';
import 'account_page.dart';

// =============================================================================
// KONFIGURASI WARNA GLOBAL
// =============================================================================
const Color primaryBlue = Color(0xFF2575FC);
const Color lightGreyBackground = Color(0xFFF4F6F9);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // 0️⃣ Dashboard
      KeepAlivePage(
        child: DashboardPage(
          key: const PageStorageKey('dashboardKey'),
          goToPage: goToPage,
        ),
      ),

      // 1️⃣ User
      const KeepAlivePage(
        child: UserPage(),
      ),

      // 2️⃣ Alat / Equipment
      const KeepAlivePage(
        child: AlatPage(),
      ),

      // 3️⃣ Peminjaman
      const KeepAlivePage(
        child: LoanPage(),
      ),

      // 4️⃣ Akun
      const KeepAlivePage(
        child: AccountPage(),
      ),
    ];
  }

  // Fungsi untuk ganti tab (dipakai juga oleh DashboardPage)
  void goToPage(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onItemTapped(int index) => goToPage(index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBackground,
      resizeToAvoidBottomInset: false,

      // 🟢 BODY: IndexedStack agar state halaman tetap hidup
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // 🟢 BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group_rounded),
              label: "User",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: "Alat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: "Peminjaman",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: "Akun",
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// KEEP ALIVE WRAPPER (STATE TIDAK HILANG)
// =============================================================================
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
