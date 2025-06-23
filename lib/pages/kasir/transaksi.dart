import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_transaksi.dart';

class TransaksiPage extends StatelessWidget {
  const TransaksiPage({super.key});

  void _deleteTransaksi(
    String docId,
    String idProduct,
    int jumlahProduct,
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Yakin ingin menghapus transaksi ini?\nStok akan dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final transaksiRef =
                  FirebaseFirestore.instance.collection('transactions').doc(docId);
              final produkRef =
                  FirebaseFirestore.instance.collection('products').doc(idProduct);

              try {
                await FirebaseFirestore.instance.runTransaction((transaction) async {
                  final produkSnapshot = await transaction.get(produkRef);
                  final currentStok =
                      (produkSnapshot.data()?['stok_product'] ?? 0) as int;

                  transaction.update(produkRef, {
                    'stok_product': currentStok + jumlahProduct,
                  });

                  transaction.delete(transaksiRef);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaksi dihapus dan stok dikembalikan')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menghapus: $e')),
                );
              }
            },
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Transaksi'),
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
            .orderBy('waktu_transaksi', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Terjadi kesalahan'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transaksiList = snapshot.data!.docs;

          if (transaksiList.isEmpty) {
            return const Center(child: Text('Belum ada transaksi'));
          }

          return ListView.builder(
            itemCount: transaksiList.length,
            itemBuilder: (context, index) {
              final doc = transaksiList[index];
              final data = doc.data() as Map<String, dynamic>;

              final idTransaksi = doc.id;
              final idProduct = data['id_product'] ?? '';
              final jumlahProduct = data['jumlah_product'] ?? 0;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('products')
                    .doc(idProduct)
                    .get(),
                builder: (context, productSnapshot) {
                  final productData =
                      productSnapshot.data?.data() as Map<String, dynamic>?;

                  return ListTile(
                    leading: const Icon(Icons.receipt),
                    title: Text(productData?['nama_product'] ?? 'Produk Tidak Ditemukan'),
                    subtitle: Text(
                      'Jumlah: $jumlahProduct | Total: Rp ${data['total_harga']}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _deleteTransaksi(idTransaksi, idProduct, jumlahProduct, context),
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
