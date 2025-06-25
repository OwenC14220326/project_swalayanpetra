import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../login_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  String _namaLengkap = 'Pengguna';

  @override
  void initState() {
    super.initState();
    _getNamaLengkap();
  }

  Future<void> _getNamaLengkap() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('nama_lengkap')) {
          setState(() {
            _namaLengkap = data['nama_lengkap'];
          });
        }
      }
    }
  }

  void _logoutWithConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Stream<QuerySnapshot> _getProductStream() {
    return FirebaseFirestore.instance
        .collection('products')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF145A32),
        foregroundColor: Colors.white,
        title: const Text('Beranda Pengguna'),
        actions: [
          IconButton(
            onPressed: () => _logoutWithConfirmation(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "👋 Selamat datang, $_namaLengkap!",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Anda dapat melihat stok produk secara real-time di bawah ini.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk, kategori, atau kode seri...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) {
                setState(() {
                  _searchKeyword = val.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getProductStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Terjadi kesalahan.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allProducts = snapshot.data!.docs;

                  final filtered = allProducts.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nama = data['nama_product']?.toLowerCase() ?? '';
                    final kode = data['kode_seri']?.toLowerCase() ?? '';
                    final kategori =
                        data['kategori_product']?.toLowerCase() ?? '';

                    return nama.contains(_searchKeyword) ||
                        kode.contains(_searchKeyword) ||
                        kategori.contains(_searchKeyword);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Tidak ada produk ditemukan.'));
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final data =
                          filtered[index].data() as Map<String, dynamic>;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: data['foto_product']?.isNotEmpty == true
                                  ? Image.network(
                                      data['foto_product'],
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.image, size: 40),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['nama_product'] ?? '-',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Kategori: ${data['kategori_product'] ?? '-'}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                            Text(
                              'Harga: Rp ${data['harga_product'] ?? 0}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87),
                            ),
                            Text(
                              'Stok: ${data['stok_product'] ?? 0}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (index * 100).ms);
                    },
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
