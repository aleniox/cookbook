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
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
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
    if (_titleController.text.isEmpty || _selectedType == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ thông tin")));
      return;
    }

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
    );

    final recipeId = await RecipeService.insertRecipe(recipe);

    // Lưu ingredients
    for (var name in _ingredients) {
      await RecipeService.insertIngredient(
        IngredientItem(
          id: null,
          name: name,
          isChecked: false,
          recipeId: recipeId,
        ),
      );
    }

    // Lưu steps
    for (var step in _steps) {
      await RecipeService.insertStep(recipeId, step);
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm Công Thức")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE PICKER
            GestureDetector(
              onTap: _pickImage,
              child: _imageFile == null
                  ? Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.add_a_photo, size: 50),
                    )
                  : Image.file(_imageFile!, height: 150, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Tên món"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Mô tả"),
              maxLines: 3,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Thời gian (phút)"),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: "Loại công thức"),
              items: ['Đồ uống', 'Thức ăn']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            const SizedBox(height: 16),

            // INGREDIENT INPUT
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: const InputDecoration(labelText: "Nguyên liệu"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final text = _ingredientController.text.trim();
                    if (text.isEmpty) return;
                    setState(() {
                      _ingredients.add(text);
                      _ingredientController.clear();
                    });
                  },
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _ingredients
                  .map((i) => Chip(
                        label: Text(i),
                        onDeleted: () => setState(() => _ingredients.remove(i)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // STEP INPUT
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Bước nấu ăn"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final text = _stepController.text.trim();
                    if (text.isEmpty) return;
                    setState(() {
                      _steps.add(text);
                      _stepController.clear();
                    });
                  },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _steps
                  .map((s) => Chip(
                        label: Text(s),
                        onDeleted: () => setState(() => _steps.remove(s)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _createRecipe,
              child: const Text("Lưu Công Thức"),
            ),
          ],
        ),
      ),
    );
  }
}
