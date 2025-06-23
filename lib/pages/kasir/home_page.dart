import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_page.dart';
import 'product.dart';
import 'transaksi.dart';

class KasirHomePage extends StatelessWidget {
  const KasirHomePage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _konfirmasiLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // tutup dialog
              _logout(context);       // lanjut logout
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _openProductPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductManagementPage()),
    );
  }

  void _openTransaksiPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransaksiPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir Home'),
        actions: [
          IconButton(
            onPressed: () => _konfirmasiLogout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.inventory),
              label: const Text("Manajemen Produk"),
              onPressed: () => _openProductPage(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text("Manajemen Transaksi"),
              onPressed: () => _openTransaksiPage(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
