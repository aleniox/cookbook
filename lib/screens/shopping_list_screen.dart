import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';
import '../models/ingredient_item.dart';

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
            name: unit.isNotEmpty
                ? "$total $unit $baseName"
                : "$total $baseName",
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
      shoppingItems.sort(
        (a, b) => (a.isChecked ? 1 : 0) - (b.isChecked ? 1 : 0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Captured images
            if (capturedImages.isNotEmpty)
              Container(
                height: 110,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: capturedImages.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildImageThumbnail(i),
                    );
                  },
                ),
              ),

            // Shopping list
            Expanded(
              child: shoppingItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 56,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có nguyên liệu nào',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thêm công thức để bắt đầu',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      itemCount: shoppingItems.length,
                      itemBuilder: (context, index) {
                        final item = shoppingItems[index];
                        return _buildIngredientTile(item, index);
                      },
                    ),
            ),
          ],
        ),

        // Camera FAB
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _captureIngredientImage,
            backgroundColor: Colors.teal,
            child: const Icon(Icons.camera_alt),
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(capturedImages[index].path),
            width: 98,
            height: 98,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => setState(() => capturedImages.removeAt(index)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 3),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientTile(IngredientItem item, int index) {
    return AnimatedOpacity(
      opacity: item.isChecked ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 2),
          ],
        ),
        child: CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
              color: item.isChecked ? Colors.grey[500] : Colors.black87,
              fontSize: 14,
            ),
          ),
          value: item.isChecked,
          activeColor: Colors.teal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onChanged: (_) => _toggleChecked(item),
        ),
      ),
    );
  }
}
