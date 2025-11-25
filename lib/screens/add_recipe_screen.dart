import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/recipe.dart';
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

  // Chọn ảnh từ gallery
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Lưu ảnh vào thư mục app
  Future<String?> _saveImage(File image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(image.path);
    final savedImage = await image.copy('${appDir.path}/$fileName');
    return savedImage.path;
  }

  // Tạo Recipe và lưu vào Hive
  void _createRecipe() async {
    if (_titleController.text.isEmpty) return;

    final ingredientItems = _ingredients
        .map((i) => IngredientItem(name: i))
        .toList();

    String imagePath = "";
    if (_imageFile != null) {
      imagePath = await _saveImage(_imageFile!) ?? "";
    }

    final recipe = Recipe(
      title: _titleController.text,
      description: _descController.text,
      ingredients: ingredientItems,
      steps: _steps,
      durationInMinutes: int.tryParse(_durationController.text) ?? 0,
      imageUrl: imagePath,
    );

    await RecipeService.addRecipe(recipe);

    if (mounted) Navigator.pop(context, true);
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
            // Chọn ảnh
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
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: "Thời gian (phút)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            // Nguyên liệu
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
                    if (_ingredientController.text.isEmpty) return;
                    setState(() {
                      _ingredients.add(_ingredientController.text);
                      _ingredientController.clear();
                    });
                  },
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: _ingredients
                  .map(
                    (i) => Chip(
                      label: Text(i),
                      onDeleted: () {
                        setState(() {
                          _ingredients.remove(i);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),

            // Steps
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    decoration: const InputDecoration(
                      labelText: "Bước nấu ăn",
                      // border: OutlineInputBorder(),
                    ),
                    minLines: 1, // số dòng tối thiểu
                    maxLines: 5, // số dòng tối đa
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_stepController.text.isEmpty) return;
                    setState(() {
                      _steps.add(_stepController.text);
                      _stepController.clear();
                    });
                  },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _steps
                  .map(
                    (s) => Chip(
                      label: Text(s),
                      onDeleted: () {
                        setState(() {
                          _steps.remove(s);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),

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
