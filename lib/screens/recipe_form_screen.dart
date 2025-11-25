// lib/screens/recipe_form_screen.dart

import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../helper/database_helper.dart';

class RecipeFormScreen extends StatefulWidget {
  const RecipeFormScreen({super.key});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _imageUrlController = TextEditingController(text: 'assets/images/placeholder.jpg'); // Placeholder mặc định
  
  // Danh sách các nguyên liệu đang được nhập
  final List<TextEditingController> _ingredientControllers = [TextEditingController()];
  
  // Danh sách các bước làm (Steps)
  final List<TextEditingController> _stepControllers = [TextEditingController()];


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _imageUrlController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  // --- HÀM THAO TÁC DB: LƯU CÔNG THỨC MỚI ---
  void _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      // 1. Trích xuất dữ liệu
      final newRecipe = Recipe(
        title: _titleController.text,
        imageUrl: _imageUrlController.text.isNotEmpty ? _imageUrlController.text : 'assets/images/placeholder.jpg',
        description: _descriptionController.text,
        durationInMinutes: int.tryParse(_durationController.text) ?? 0,
        
        // 2. Chuyển đổi List<TextEditingController> thành List<IngredientItem> và List<String>
        ingredients: _ingredientControllers
            .where((c) => c.text.isNotEmpty)
            .map((c) => IngredientItem(name: c.text))
            .toList(),
            
        steps: _stepControllers
            .where((c) => c.text.isNotEmpty)
            .map((c) => c.text)
            .toList(),
      );

      // 3. Gọi DB Helper để tạo công thức mới
      await DatabaseHelper.instance.createRecipe(newRecipe);
      
      // 4. Thông báo và quay lại
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu công thức mới thành công!')),
        );
        Navigator.pop(context, true); // Trả về true để báo hiệu cần làm mới
      }
    }
  }
  
  // --- HÀM XỬ LÝ UI ---
  Widget _buildIngredientFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nguyên liệu:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ..._ingredientControllers.asMap().entries.map((entry) {
          int index = entry.key;
          TextEditingController controller = entry.value;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Nguyên liệu ${index + 1} (vd: 500g ức gà)',
                    border: const UnderlineInputBorder(),
                  ),
                  validator: (value) {
                    // Yêu cầu ít nhất 1 nguyên liệu đầu tiên
                    if (index == 0 && (value == null || value.isEmpty)) {
                      return 'Cần ít nhất một nguyên liệu.';
                    }
                    return null;
                  },
                ),
              ),
              if (index == _ingredientControllers.length - 1)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    setState(() {
                      _ingredientControllers.add(TextEditingController());
                    });
                  },
                ),
              if (index > 0)
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _ingredientControllers.removeAt(index);
                      controller.dispose();
                    });
                  },
                ),
            ],
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildStepFields() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('Các bước thực hiện:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ..._stepControllers.asMap().entries.map((entry) {
          int index = entry.key;
          TextEditingController controller = entry.value;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Bước ${index + 1}',
                    border: const UnderlineInputBorder(),
                  ),
                  validator: (value) {
                    if (index == 0 && (value == null || value.isEmpty)) {
                      return 'Cần ít nhất một bước làm.';
                    }
                    return null;
                  },
                ),
              ),
              if (index == _stepControllers.length - 1)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    setState(() {
                      _stepControllers.add(TextEditingController());
                    });
                  },
                ),
            ],
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Công thức Mới'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRecipe,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tên Công thức'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên công thức.' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập mô tả.' : null,
              ),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Thời gian chuẩn bị (phút)'),
                validator: (value) => int.tryParse(value!) == null ? 'Vui lòng nhập số hợp lệ.' : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Đường dẫn ảnh (Url hoặc assets)'),
              ),
              
              const SizedBox(height: 20),
              
              // Fields cho Nguyên liệu
              _buildIngredientFields(),
              
              // Fields cho Các bước làm
              _buildStepFields(),
              
              const SizedBox(height: 30),
              
              ElevatedButton.icon(
                onPressed: _saveRecipe,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Lưu Công thức', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}