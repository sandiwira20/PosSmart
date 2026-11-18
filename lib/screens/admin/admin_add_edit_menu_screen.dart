import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_network_image.dart';
import '../../models/menu_model.dart';
import '../../providers/menu_provider.dart';

class AdminAddEditMenuScreen extends StatefulWidget {
  final MenuModel? menu;

  const AdminAddEditMenuScreen({super.key, this.menu});

  @override
  State<AdminAddEditMenuScreen> createState() => _AdminAddEditMenuScreenState();
}

class _AdminAddEditMenuScreenState extends State<AdminAddEditMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _descController;
  String _category = 'Makanan';
  bool _isAvailable = true;
  bool _isPickingImage = false;

  final List<String> _categories = ['Makanan', 'Minuman', 'Snack', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menu?.name ?? '');
    _priceController = TextEditingController(
      text: widget.menu != null ? widget.menu!.price.toInt().toString() : '',
    );
    _imageController = TextEditingController(
      text: widget.menu?.imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
    );
    _descController = TextEditingController(text: widget.menu?.description ?? '');
    _category = widget.menu?.category ?? 'Makanan';
    _isAvailable = widget.menu?.isAvailable ?? true;
  }

  /// Memilih foto dari File Manager / Galeri Komputer atau HP
  Future<void> _pickImage() async {
    try {
      setState(() => _isPickingImage = true);
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _imageController.text = base64String;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final image = _imageController.text.trim();
    final desc = _descController.text.trim();

    final menuProv = Provider.of<MenuProvider>(context, listen: false);

    if (widget.menu == null) {
      // Create
      final newMenu = MenuModel(
        id: 'menu-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        category: _category,
        price: price,
        imageUrl: image,
        description: desc,
        isAvailable: _isAvailable,
      );
      await menuProv.addMenu(newMenu);
    } else {
      // Update
      final updated = widget.menu!.copyWith(
        name: name,
        category: _category,
        price: price,
        imageUrl: image,
        description: desc,
        isAvailable: _isAvailable,
      );
      await menuProv.updateMenu(updated);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.menu == null ? 'Menu baru berhasil ditambahkan ke Firebase!' : 'Menu berhasil diupdate!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.menu != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Menu' : 'Tambah Menu Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview Card (Bisa diklik untuk pilih file)
              Center(
                child: Column(
                  children: [
                    InkWell(
                      onTap: _isPickingImage ? null : _pickImage,
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryLight, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: AppNetworkImage(
                                imageUrl: _imageController.text,
                                fit: BoxFit.cover,
                                errorWidget: const Center(
                                  child: Icon(Icons.add_a_photo_outlined, size: 40, color: AppTheme.outline),
                                ),
                              ),
                            ),
                          ),
                          if (_isPickingImage)
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tombol Choose File / Pilih Foto dari Galeri
                    ElevatedButton.icon(
                      onPressed: _isPickingImage ? null : _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: const Text(
                        'Pilih Foto dari Komputer / HP (Choose File)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Garis Pemisah
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'atau masukkan link URL foto di bawah',
                            style: TextStyle(fontSize: 11, color: AppTheme.outline),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Image URL input
              const Text('URL Foto Produk', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _imageController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'https://... atau otomatis terisi dari tombol Pilih Foto',
                  prefixIcon: Icon(Icons.link, color: AppTheme.outline),
                ),
              ),
              const SizedBox(height: 16),

              // Name input
              const Text('Nama Menu', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                validator: (val) => val == null || val.isEmpty ? 'Nama menu wajib diisi' : null,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Nasi Goreng Spesial',
                  prefixIcon: Icon(Icons.restaurant, color: AppTheme.outline),
                ),
              ),
              const SizedBox(height: 16),

              // Price input
              const Text('Harga Jual (Rp)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Harga wajib diisi' : null,
                decoration: const InputDecoration(
                  hintText: 'Contoh: 20000',
                  prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.outline),
                ),
              ),
              const SizedBox(height: 16),

              // Category dropdown
              const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined, color: AppTheme.outline),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 16),

              // Description input
              const Text('Deskripsi (Opsional)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Keterangan menu...',
                  prefixIcon: Icon(Icons.notes, color: AppTheme.outline),
                ),
              ),
              const SizedBox(height: 16),

              // Availability Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status Stok Tersedia', style: TextStyle(fontWeight: FontWeight.w600)),
                    Switch(
                      value: _isAvailable,
                      activeColor: AppTheme.primary,
                      onChanged: (val) => setState(() => _isAvailable = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _saveMenu,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(isEdit ? 'Simpan Perubahan' : 'Tambah Menu ke Database'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
