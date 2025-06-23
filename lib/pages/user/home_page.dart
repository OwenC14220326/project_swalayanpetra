import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getProductStream() {
    return FirebaseFirestore.instance
        .collection('products')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk Tersedia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Search input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan nama, kategori, atau kode seri...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) {
                setState(() {
                  _searchKeyword = val.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),

            // 📦 List produk
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getProductStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Terjadi kesalahan'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allProducts = snapshot.data!.docs;

                  // 🔍 Filter berdasarkan nama, kode seri, atau kategori
                  final filtered = allProducts.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nama = data['nama_product']?.toLowerCase() ?? '';
                    final kode = data['kode_seri']?.toLowerCase() ?? '';
                    final kategori = data['kategori_product']?.toLowerCase() ?? '';

                    return nama.contains(_searchKeyword) ||
                        kode.contains(_searchKeyword) ||
                        kategori.contains(_searchKeyword);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Tidak ada produk ditemukan'));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final data = filtered[index].data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: data['foto_product']?.isNotEmpty == true
                                    ? Image.network(
                                        data['foto_product'],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.image_not_supported, size: 60),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['nama_product'] ?? '-',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Deskripsi: ${data['deskripsi_product'] ?? '-'}'),
                                    Text('Kategori: ${data['kategori_product'] ?? '-'}'),
                                    Text('Kode Seri: ${data['kode_seri'] ?? '-'}'),
                                    Text('Harga: Rp ${data['harga_product'] ?? 0}'),
                                    Text('Stok: ${data['stok_product'] ?? 0}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
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
