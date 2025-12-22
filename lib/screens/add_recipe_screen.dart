import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/recipe.dart';
import '../models/ingredient_item.dart';
import '../services/recipe_service.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _ingredientController = TextEditingController();
  final _stepController = TextEditingController();
  final _durationController = TextEditingController();

  final List<String> _ingredients = [];
  final List<String> _steps = [];

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  String? _selectedType;

  /// PICK IMAGE
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  /// SAVE IMAGE INTO APP DIRECTORY
  Future<String?> _saveImage(File image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(image.path);
    final savedFile = await image.copy('${appDir.path}/$fileName');
    return savedFile.path;
  }

  /// CREATE RECIPE USING SQLITE
  Future<void> _createRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    String imagePath = "";
    if (_imageFile != null) {
      imagePath = await _saveImage(_imageFile!) ?? "";
    }

    final recipe = Recipe(
      id: null,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      durationInMinutes: int.tryParse(_durationController.text) ?? 0,
      type: _selectedType!,
      imageUrl: imagePath,
      ingredients: _ingredients.map((name) => IngredientItem(name: name, isChecked: false)).toList(),
      steps: _steps,
    );

    await RecipeService.createRecipe(recipe);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _ingredientController.dispose();
    _stepController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Widget _buildImagePicker(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              color: Colors.grey[200],
              child: _imageFile == null
                  ? const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                    )
                  : Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Chọn ảnh', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm Công Thức"), elevation: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImagePicker(context),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration("Tên món"),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập tên món'
                      : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descController,
                  decoration: _inputDecoration("Mô tả ngắn"),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration("Thời gian (phút)"),
                        validator: (v) =>
                            (v == null || v.isEmpty || int.tryParse(v) == null)
                            ? 'Nhập số phút hợp lệ'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: _inputDecoration("Loại công thức"),
                        items: ['Đồ uống', 'Thức ăn']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedType = v),
                        validator: (v) =>
                            v == null ? 'Chọn loại công thức' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // INGREDIENT INPUT (chip list)
                Text(
                  'Nguyên liệu',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ingredientController,
                        decoration: InputDecoration(
                          hintText: "Ví dụ: 500g ức gà",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final text = _ingredientController.text.trim();
                        if (text.isEmpty) return;
                        setState(() {
                          _ingredients.add(text);
                          _ingredientController.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _ingredients.map((i) {
                    return Chip(
                      label: Text(i),
                      onDeleted: () => setState(() => _ingredients.remove(i)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // STEP INPUT
                Text(
                  'Các bước thực hiện',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _stepController,
                        decoration: InputDecoration(
                          hintText: "Mô tả bước",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final text = _stepController.text.trim();
                        if (text.isEmpty) return;
                        setState(() {
                          _steps.add(text);
                          _stepController.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _steps.asMap().entries.map((e) {
                    final idx = e.key;
                    final s = e.value;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 12,
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      title: Text(s),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => setState(() => _steps.removeAt(idx)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _createRecipe,
                  icon: const Icon(Icons.save),
                  label: const Text("Lưu Công Thức"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Huỷ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
