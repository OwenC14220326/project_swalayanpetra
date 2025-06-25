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
  final _searchController = TextEditingController();

  String? _selectedProductId;
  Map<String, dynamic>? _selectedProductData;

  bool _isLoading = false;
  List<QueryDocumentSnapshot> _allProducts = [];
  List<QueryDocumentSnapshot> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _ambilSemuaProduk();
  }

  Future<void> _ambilSemuaProduk() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .orderBy('nama_product')
        .get();
    setState(() {
      _allProducts = snapshot.docs;
      _filteredProducts = _allProducts;
    });
  }

  void _filterProduk(String input) {
    final query = input.toLowerCase();
    final hasil = _allProducts.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final nama = (data['nama_product'] ?? '').toString().toLowerCase();
      final kategori = (data['kategori_product'] ?? '').toString().toLowerCase();
      final kodeSeri = (data['kode_seri'] ?? '').toString().toLowerCase();
      return nama.contains(query) || kategori.contains(query) || kodeSeri.contains(query);
    }).toList();

    setState(() => _filteredProducts = hasil);
  }

  Future<void> _konfirmasiDanSimpan() async {
    if (!_formKey.currentState!.validate() || _selectedProductData == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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
      final double harga = (_selectedProductData?['harga_product'] as num).toDouble();
      final int stok = _selectedProductData?['stok_product'] ?? 0;

      if (jumlah > stok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok tidak mencukupi')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('transactions').add({
        'id_product': _selectedProductId,
        'jumlah_product': jumlah,
        'total_harga': harga * jumlah,
        'waktu_transaksi': FieldValue.serverTimestamp(),
      });

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
    _searchController.dispose();
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
                'Cari Produk',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari berdasarkan nama, kategori, atau kode seri...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _filterProduk,
              ),

              const SizedBox(height: 8),

              if (_filteredProducts.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final doc = _filteredProducts[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['nama_product'] ?? ''),
                      subtitle: Text(
                          'Kategori: ${data['kategori_product']} • Kode: ${data['kode_seri']} • Stok: ${data['stok_product']}'),
                      onTap: () {
                        setState(() {
                          _selectedProductId = doc.id;
                          _selectedProductData = data;
                          _searchController.text = data['nama_product'];
                          _filteredProducts.clear();
                        });
                      },
                    );
                  },
                ),

              if (_selectedProductData != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Produk: ${_selectedProductData?['nama_product']}'),
                      Text('Harga: Rp ${_selectedProductData?['harga_product']}'),
                      Text('Stok tersedia: ${_selectedProductData?['stok_product']}'),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              TextFormField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Produk',
                  prefixIcon: const Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
