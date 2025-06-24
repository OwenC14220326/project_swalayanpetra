import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'add_transaksi.dart';

class TransaksiPage extends StatelessWidget {
  final DateTime tanggal;

  const TransaksiPage({super.key, required this.tanggal});

  void _deleteTransaksi(
      String docId, int jumlah, String idProduk, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Yakin ingin menghapus transaksi ini?\nStok akan dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final productRef = FirebaseFirestore.instance.collection('products').doc(idProduk);
      final productSnap = await productRef.get();
      final stokLama = (productSnap.data()?['stok_product'] ?? 0) as int;

      await productRef.update({'stok_product': stokLama + jumlah});
      await FirebaseFirestore.instance.collection('transactions').doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi dihapus dan stok dikembalikan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final startOfDay = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: Text('Transaksi: ${DateFormat('dd MMM yyyy').format(tanggal)}'),
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransaksiPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('waktu_transaksi', isGreaterThanOrEqualTo: startOfDay)
            .where('waktu_transaksi', isLessThan: endOfDay)
            .orderBy('waktu_transaksi', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Terjadi kesalahan'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transaksiList = snapshot.data!.docs;

          if (transaksiList.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada transaksi pada tanggal ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transaksiList.length,
            itemBuilder: (context, index) {
              final doc = transaksiList[index];
              final data = doc.data() as Map<String, dynamic>;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('products')
                    .doc(data['id_product'])
                    .get(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                  }

                  final productData =
                      productSnapshot.data?.data() as Map<String, dynamic>?;

                  final namaProduk = productData?['nama_product'] ?? 'Produk tidak ditemukan';
                  final harga = productData?['harga_product'] ?? 0;
                  final jumlah = data['jumlah_product'] ?? 0;
                  final total = data['total_harga'] ?? 0;
                  final waktu = (data['waktu_transaksi'] as Timestamp?)?.toDate();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.receipt_long, size: 40, color: Colors.deepPurple),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  namaProduk,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Harga: Rp $harga'),
                                Text('Jumlah: $jumlah'),
                                Text('Total: Rp $total'),
                                if (waktu != null)
                                  Text(
                                    'Waktu: ${DateFormat('HH:mm:ss').format(waktu)}',
                                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteTransaksi(doc.id, jumlah, data['id_product'], context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
