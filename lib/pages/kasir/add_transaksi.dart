import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddTransaksiPage extends StatefulWidget {
  const AddTransaksiPage({super.key});

  @override
  State<AddTransaksiPage> createState() => _AddTransaksiPageState();
}

class _AddTransaksiPageState extends State<AddTransaksiPage> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _kodeSeriController = TextEditingController();

  String? _selectedProductId;
  Map<String, dynamic>? _selectedProductData;

  bool _isLoading = false;

  Stream<QuerySnapshot> _getProductsStream() {
    return FirebaseFirestore.instance
        .collection('products')
        .orderBy('nama_product')
        .snapshots();
  }

  void _setSelectedByKodeSeri(String input) async {
    final snap =
        await FirebaseFirestore.instance
            .collection('products')
            .where('kode_seri', isEqualTo: input.trim())
            .limit(1)
            .get();

    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      setState(() {
        _selectedProductId = doc.id;
        _selectedProductData = doc.data() as Map<String, dynamic>;
      });
    } else {
      setState(() {
        _selectedProductId = null;
        _selectedProductData = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kode seri tidak ditemukan")),
      );
    }
  }

  Future<void> _konfirmasiDanSimpan() async {
    if (!_formKey.currentState!.validate() || _selectedProductData == null)
      return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: Text(
              'Yakin ingin menyimpan transaksi ini?\n\n'
              'Produk: ${_selectedProductData?['nama_product']}\n'
              'Jumlah: ${_jumlahController.text}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ya, Simpan'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final int jumlah = int.parse(_jumlahController.text);
      final double harga = _selectedProductData?['harga_product'] ?? 0;
      final int stok = _selectedProductData?['stok_product'] ?? 0;

      if (jumlah > stok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Stok tidak mencukupi')));
        return;
      }

      // Tambah transaksi
      await FirebaseFirestore.instance.collection('transactions').add({
        'id_product': _selectedProductId,
        'jumlah_product': jumlah,
        'total_harga': harga * jumlah,
        'waktu_transaksi': FieldValue.serverTimestamp(),
      });

      // Kurangi stok
      await FirebaseFirestore.instance
          .collection('products')
          .doc(_selectedProductId)
          .update({'stok_product': stok - jumlah});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil ditambahkan')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan transaksi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _kodeSeriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: const Text('Tambah Transaksi'),
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Pilih Produk',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: _getProductsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Text('Error');
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();

                  final docs = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: _selectedProductId,
                    decoration: InputDecoration(
                      hintText: 'Pilih produk',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items:
                        docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(
                              '${data['nama_product']} (Stok: ${data['stok_product']})',
                            ),
                          );
                        }).toList(),
                    onChanged: (val) {
                      final selected = docs.firstWhere((d) => d.id == val);
                      setState(() {
                        _selectedProductId = val;
                        _selectedProductData =
                            selected.data() as Map<String, dynamic>;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // 🔎 Kode Seri dan Tombol Cari
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _kodeSeriController,
                      decoration: InputDecoration(
                        labelText: 'Atau masukkan Kode Seri Produk',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onFieldSubmitted: (val) => _setSelectedByKodeSeri(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        () => _setSelectedByKodeSeri(_kodeSeriController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.search, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🔢 Jumlah
              TextFormField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Produk',
                  prefixIcon: const Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  final n = int.tryParse(val ?? '');
                  if (n == null || n <= 0) return 'Jumlah tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _konfirmasiDanSimpan,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Transaksi'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
