import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';

class ShoppingListScreen extends StatefulWidget {
  final List<Recipe> recipes;

  const ShoppingListScreen({super.key, required this.recipes});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late List<IngredientItem> shoppingItems;
  List<XFile> capturedImages = [];

  final RegExp _quantityRegex = RegExp(r'(\d*\.?\d+)\s*([a-zA-Z]+)?\s*(.*)');

  @override
  void initState() {
    super.initState();
    shoppingItems = _extractIngredients(widget.recipes);
  }

  @override
  void didUpdateWidget(covariant ShoppingListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recipes != oldWidget.recipes) {
      setState(() {
        shoppingItems = _extractIngredients(widget.recipes);
      });
    }
  }

  // ---------------------
  // 📌 Tính năng CAMERA
  // ---------------------
  Future<void> _captureIngredientImage() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        capturedImages.add(photo);
      });
    }
  }

  // ----------------------
  // 📌 Gộp nguyên liệu
  // ----------------------
  List<IngredientItem> _extractIngredients(List<Recipe> recipes) {
    Map<String, IngredientItem> combined = {};

    for (var recipe in recipes) {
      for (var item in recipe.ingredients) {
        final match = _quantityRegex.firstMatch(item.name.trim());

        String baseName;
        double quantity = 1;
        String unit = '';

        if (match != null) {
          quantity = double.tryParse(match.group(1) ?? '1') ?? 1;
          unit = (match.group(2) ?? '').toLowerCase();
          baseName = (match.group(3) ?? '').trim().toLowerCase();
        } else {
          baseName = item.name.toLowerCase().trim();
        }

        final key = "$baseName-$unit";

        if (combined.containsKey(key)) {
          final exist = combined[key]!;
          final existMatch = _quantityRegex.firstMatch(exist.name);
          final existQty = existMatch != null
              ? double.tryParse(existMatch.group(1) ?? '1') ?? 1
              : 1;

          final total = existQty + quantity;

          combined[key] = IngredientItem(
            name: unit.isNotEmpty ? "$total $unit $baseName" : "$total $baseName",
            isChecked: exist.isChecked || item.isChecked,
          );
        } else {
          combined[key] = IngredientItem(
            name: unit.isNotEmpty ? "$quantity $unit $baseName" : item.name,
            isChecked: item.isChecked,
          );
        }
      }
    }

    final list = combined.values.toList();
    list.sort((a, b) => (a.isChecked ? 1 : 0) - (b.isChecked ? 1 : 0));

    return list;
  }

  void _toggleChecked(IngredientItem item) {
    setState(() {
      item.isChecked = !item.isChecked;
      shoppingItems.sort((a, b) => (a.isChecked ? 1 : 0) - (b.isChecked ? 1 : 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // 🔥 Hiển thị ảnh chụp
            if (capturedImages.isNotEmpty)
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: capturedImages.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(capturedImages[i].path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),

            Expanded(
              child: shoppingItems.isEmpty
                  ? const Center(
                      child: Text('Chưa có nguyên liệu nào trong danh sách.'),
                    )
                  : ListView.builder(
                      itemCount: shoppingItems.length,
                      itemBuilder: (context, index) {
                        final item = shoppingItems[index];
                        return CheckboxListTile(
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isChecked ? Colors.grey : Colors.black,
                            ),
                          ),
                          value: item.isChecked,
                          activeColor: Colors.teal,
                          onChanged: (_) => _toggleChecked(item),
                        );
                      },
                    ),
            ),
          ],
        ),

        // 🔥 Floating Button chụp ảnh
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _captureIngredientImage,
            child: const Icon(Icons.camera_alt),
            backgroundColor: Colors.teal,
          ),
        ),
      ],
    );
  }
}
