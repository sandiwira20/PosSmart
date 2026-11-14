import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../models/menu_model.dart';
import '../../services/menu_service.dart';

class AddEditMenuScreen extends StatefulWidget {
  final MenuModel? menu;

  const AddEditMenuScreen({super.key, this.menu});

  bool get isEditMode => menu != null;

  @override
  State<AddEditMenuScreen> createState() => _AddEditMenuScreenState();
}

class _AddEditMenuScreenState extends State<AddEditMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _menuService = MenuService();
  final _imagePicker = ImagePicker();

  String _selectedCategory = AppConstants.menuCategories.first;
  bool _isAvailable = true;
  bool _isLoading = false;
  File? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      final m = widget.menu!;
      _nameController.text = m.name;
      _priceController.text = m.price.toStringAsFixed(0);
      _selectedCategory = m.category;
      _isAvailable = m.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0;

      if (widget.isEditMode) {
        final updated = widget.menu!.copyWith(
          name: name,
          price: price,
          category: _selectedCategory,
          isAvailable: _isAvailable,
        );
        await _menuService.updateMenu(
          updated,
          imageFile: _selectedImageFile,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu berhasil diperbarui'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        await _menuService.createMenu(
          name: name,
          price: price,
          category: _selectedCategory,
          isAvailable: _isAvailable,
          imageFile: _selectedImageFile,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu berhasil ditambahkan'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan menu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Menu',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Yakin ingin menghapus menu ini? Tindakan ini tidak dapat dibatalkan.',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.menu != null) {
      setState(() => _isLoading = true);
      try {
        await _menuService.deleteMenu(widget.menu!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu berhasil dihapus'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus menu: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text(
              widget.isEditMode ? 'Edit Menu' : 'Tambah Menu',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.onSurface,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo Upload
                  _PhotoUploadArea(
                    imageFile: _selectedImageFile,
                    imageUrl: widget.menu?.imageUrl,
                    onTap: _pickImage,
                  ),
                  const SizedBox(height: 24),

                  // Nama Menu
                  _SectionLabel(label: 'Nama Menu'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      hintText: 'Contoh: Nasi Goreng Spesial',
                      prefixIcon: Icons.label_outline_rounded,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nama menu wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Harga
                  _SectionLabel(label: 'Harga'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _priceController,
                    decoration: _inputDecoration(
                      hintText: '0',
                      prefixText: 'Rp  ',
                      prefixIcon: Icons.payments_outlined,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Harga wajib diisi';
                      }
                      final price = double.tryParse(v.trim());
                      if (price == null || price <= 0) {
                        return 'Masukkan harga yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Kategori
                  _SectionLabel(label: 'Kategori'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _inputDecoration(
                      hintText: 'Pilih Kategori',
                      prefixIcon: Icons.category_outlined,
                    ),
                    items: AppConstants.menuCategories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                    validator: (v) =>
                        v == null ? 'Kategori wajib dipilih' : null,
                  ),
                  const SizedBox(height: 8),

                  // Toggle Tersedia
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'Menu Tersedia',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        _isAvailable
                            ? 'Menu aktif dan dapat dipesan'
                            : 'Menu tidak aktif',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      value: _isAvailable,
                      onChanged: (val) => setState(() => _isAvailable = val),
                      activeColor: AppColors.primaryContainer,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveMenu,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(
                      'Simpan Menu',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primaryContainer.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),

                  // Delete Button (Edit Mode only)
                  if (widget.isEditMode) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _confirmDelete,
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error),
                      label: Text(
                        'Hapus Menu',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side:
                            const BorderSide(color: AppColors.error, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),

        // Loading Overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                          color: AppColors.primaryContainer),
                      SizedBox(height: 16),
                      Text('Menyimpan...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.bodyMedium
          .copyWith(color: AppColors.outline.withOpacity(0.7)),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.outline)
          : null,
      prefixText: prefixText,
      prefixStyle: AppTypography.bodyMedium
          .copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceContainer),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.surfaceContainer, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.primaryContainer, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelLarge.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PhotoUploadArea extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback onTap;

  const _PhotoUploadArea({
    required this.imageFile,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imageFile != null || (imageUrl != null && imageUrl!.isNotEmpty);

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryContainer,
              width: 2,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageFile != null)
                      Image.file(imageFile!, fit: BoxFit.cover)
                    else
                      Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_rounded,
                          color: AppColors.outline,
                          size: 48,
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        color: Colors.black.withOpacity(0.45),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Ganti Foto',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppColors.primaryContainer,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Pilih Foto',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'dari Galeri',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
