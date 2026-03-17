import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/product.dart';
import '../models/category.dart';
import '../services/product_service.dart';
import 'native_scanner_screen.dart';
import 'package:image_cropper/image_cropper.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final _imagePicker = ImagePicker();

  bool get isEditing => widget.product != null;
  bool _isSaving = false;
  XFile? _pickedImage;
  List<ProductCategory> _categories = [];
  int? _selectedCategoryId;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _salePriceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;
  ProductType _type = ProductType.piece;

  static const Color primaryColor = Color(0xFF2FA7A4);
  static const Color bgColor = Color(0xFFF6F7F9);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color secondaryTextColor = Color(0xFF8A97A5);

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _purchasePriceCtrl = TextEditingController(text: p?.purchasePrice.toString() ?? '');
    _salePriceCtrl = TextEditingController(text: p?.salePrice.toString() ?? '');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '0');
    _minStockCtrl = TextEditingController(text: p?.minStock.toString() ?? '10');
    _type = p?.type ?? ProductType.piece;
    _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _salePriceCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _productService.fetchCategories();
      setState(() {
        _categories = cats;
        if (isEditing && widget.product?.category != null) {
          try {
             _selectedCategoryId = cats.firstWhere((c) => c.name.toLowerCase() == widget.product!.category.toLowerCase()).id;
          } catch (_) {}
        }
      });
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Choose Image Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: primaryColor),
                title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _processImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: primaryColor),
                title: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _processImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() => _pickedImage = XFile(croppedFile.path));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'barcode': _barcodeCtrl.text.trim(),
      'purchase_price': _purchasePriceCtrl.text.trim(),
      'sale_price': _salePriceCtrl.text.trim(),
      'stock_quantity': _stockCtrl.text.trim(),
      'min_stock': _minStockCtrl.text.trim(),
      'type': _type.value,
      if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
    };

    try {
      if (isEditing) {
        await _productService.updateProduct(widget.product!.id!, data, image: _pickedImage);
      } else {
        await _productService.createProduct(data, image: _pickedImage);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final ctrl = TextEditingController();
    bool isSavingCat = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: 'Category Name', 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: isSavingCat ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: isSavingCat ? null : () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                setStateDialog(() => isSavingCat = true);
                try {
                  final newCat = await _productService.createCategory(name);
                  setState(() {
                    _categories.add(newCat);
                    _selectedCategoryId = newCat.id;
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category created!'), backgroundColor: Colors.green));
                    Navigator.pop(context);
                  }
                } catch (e) {
                  setStateDialog(() => isSavingCat = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: isSavingCat 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(isEditing ? 'EDIT PRODUCT' : 'ADD PRODUCT',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 1.2)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker section
              _buildSectionCard(
                child: Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                          ),
                          child: _pickedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(File(_pickedImage!.path), fit: BoxFit.cover))
                              : (widget.product?.imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.network(widget.product!.imagePath!, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.add_photo_alternate_outlined, size: 40, color: secondaryTextColor)))
                                  : const Icon(Icons.add_photo_alternate_outlined, size: 40, color: secondaryTextColor)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Product Image', style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              _buildSectionTitle('BASIC INFORMATION'),
              const SizedBox(height: 8),
              _buildSectionCard(
                child: Column(
                  children: [
                    _buildInputField(_nameCtrl, 'Product Name', Icons.inventory_2_outlined, required: true),
                    const Divider(height: 24),
                    _buildInputField(
                      _barcodeCtrl, 
                      'Barcode / SKU (Optional)', 
                      Icons.qr_code_scanner_outlined, 
                      required: false,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.center_focus_strong, color: primaryColor),
                        tooltip: 'Scan Barcode',
                        onPressed: () async {
                          final result = await Navigator.push<String?>(
                            context,
                            MaterialPageRoute(builder: (_) => const NativeScannerScreen(isFormMode: true)),
                          );
                          if (result != null && result.isNotEmpty) {
                            setState(() => _barcodeCtrl.text = result);
                          }
                        },
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField<int>(
                            label: 'Category',
                            icon: Icons.category_outlined,
                            value: _selectedCategoryId,
                            items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                            onChanged: (v) => setState(() => _selectedCategoryId = v),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: primaryColor, size: 28),
                          padding: EdgeInsets.zero,
                          tooltip: 'Add Category',
                          onPressed: _showAddCategoryDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('PRICING'),
              const SizedBox(height: 8),
              _buildSectionCard(
                child: Column(
                  children: [
                    _buildInputField(_purchasePriceCtrl, 'Purchase Price (UZS)', Icons.shopping_cart_outlined, keyboardType: TextInputType.number, required: true),
                    const Divider(height: 24),
                    _buildInputField(_salePriceCtrl, 'Sale Price (UZS)', Icons.payments_outlined, keyboardType: TextInputType.number, required: true),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('INVENTORY'),
              const SizedBox(height: 8),
              _buildSectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInputField(_stockCtrl, 'Stock', Icons.warehouse_outlined, keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInputField(_minStockCtrl, 'Min Alert', Icons.notifications_active_outlined, keyboardType: TextInputType.number)),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDropdownField<ProductType>(
                      label: 'Type',
                      icon: Icons.scale_outlined,
                      value: _type,
                      items: ProductType.values.map((u) => DropdownMenuItem(value: u, child: Text(u.label))).toList(),
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(isEditing ? 'UPDATE PRODUCT' : 'CREATE PRODUCT',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: secondaryTextColor, letterSpacing: 1),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: secondaryTextColor, size: 20),
        suffixIcon: suffixIcon,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      icon: const Icon(Icons.unfold_more, color: secondaryTextColor, size: 20),
      isExpanded: true, // EXTREMELY IMPORTANT: Fixes the Right Overflow Error!
      style: const TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: secondaryTextColor, size: 20),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
