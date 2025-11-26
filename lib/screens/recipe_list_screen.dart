import 'dart:io';
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'add_recipe_screen.dart';
import '../helper/database_helper.dart';
import 'recipe_detail_screen.dart';

class RecipeListScreen extends StatefulWidget {
  final Function(Recipe) onPlanAdded;

  // Thêm tham số optional để nhận danh sách công thức từ ngoài
  final List<Recipe>? initialRecipes;

  const RecipeListScreen({
    super.key,
    required this.onPlanAdded,
    this.initialRecipes,
  });

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  late List<Recipe> _recipes; // danh sách gốc
  late List<Recipe> _filteredRecipes; // danh sách hiển thị sau search/ lọc
  String _searchQuery = '';
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _recipes = widget.initialRecipes ?? RecipeService.getAllRecipes();
    _filteredRecipes = List.from(_recipes);
  }

  // Hàm thêm công thức từ PresetRecipeScreen
  void addRecipeFromPreset(Recipe recipe) {
    if (!_recipes.contains(recipe)) {
      setState(() {
        _recipes.add(recipe);
        _filterRecipes();
      });
    }
  }

  void _openAddRecipeScreen() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
    );

    if (added == true) {
      setState(() {
        _recipes = RecipeService.getAllRecipes();
        _filterRecipes();
      });
    }
  }

  void _deleteRecipe(Recipe recipe) async {
    // Xóa ảnh local nếu có
    if (recipe.imageUrl.isNotEmpty && File(recipe.imageUrl).existsSync()) {
      File(recipe.imageUrl).deleteSync();
    }
    await recipe.delete();
    setState(() {
      _recipes.remove(recipe);
      _filterRecipes();
    });
  }

  // Hàm lọc/search danh sách
  void _filterRecipes() {
    setState(() {
      _filteredRecipes = _recipes.where((recipe) {
        final matchesSearch = recipe.title.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final matchesType =
            _selectedType == null || recipe.type == _selectedType;
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Search + Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // SEARCH BAR
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: "Tìm kiếm công thức...",
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                isCollapsed: true, // giảm chiều cao input
                              ),
                              onChanged: (value) {
                                _searchQuery = value;
                                _filterRecipes();
                              },
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchQuery = "";
                                _filterRecipes();
                              },
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // FILTER BUTTON NÂNG CẤP
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        setState(() {
                          _selectedType = value;
                          _filterRecipes();
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'Đồ uống',
                          child: Text('Đồ uống'),
                        ),
                        const PopupMenuItem(
                          value: 'Thức ăn',
                          child: Text('Thức ăn'),
                        ),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedType ?? 'Lọc',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 50),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Danh sách công thức
            Expanded(
              child: _filteredRecipes.isEmpty
                  ? const Center(child: Text('Chưa có công thức nào.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _filteredRecipes[index];
                        return RecipeCard(
                          recipe: recipe,
                          onPlanAdded: widget.onPlanAdded,
                          onDelete: () => _deleteRecipe(recipe),
                        );
                      },
                    ),
            ),
          ],
        ),

        // Nút FAB nổi
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _openAddRecipeScreen,
            tooltip: 'Thêm Công Thức',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

/// =======================
/// RecipeCard (tối ưu)
/// =======================
class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final Function(Recipe) onPlanAdded;
  final VoidCallback? onDelete;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onPlanAdded,
    this.onDelete,
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _isExpanded = false;

  Widget loadImage(String path, {double? height, BoxFit? fit}) {
    if (path.startsWith('http')) {
      return Image.network(path, height: height, fit: fit);
    } else if (path.isNotEmpty && File(path).existsSync()) {
      return Image.file(File(path), height: height, fit: fit);
    } else {
      return Container(
        height: height ?? 100,
        width: height ?? 100,
        color: Colors.grey[300],
        child: const Icon(Icons.restaurant_menu, size: 50),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh + thông tin
          InkWell(
            borderRadius: BorderRadius.circular(15.0),
            onTap: () {
              // TODO: mở màn hình chi tiết
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(
                    recipe: widget.recipe,
                    onPlanAdded: widget.onPlanAdded,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: loadImage(
                      widget.recipe.imageUrl,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recipe.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          widget.recipe.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Color(0xFF6D9886),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.recipe.durationInMinutes} phút',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 0),
          // Nút thêm/xóa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => widget.onPlanAdded(widget.recipe),
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.green,
                  ),
                  label: const Text('Thêm vào kế hoạch'),
                ),
                const Spacer(),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
          ),
          // Nút mở/thu checklist
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isExpanded
                        ? 'Thu gọn Nguyên liệu'
                        : 'Xem Nguyên liệu (Checklist)',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            IngredientChecklist(ingredients: widget.recipe.ingredients),
        ],
      ),
    );
  }
}

/// =======================
/// Checklist nguyên liệu
/// =======================
class IngredientChecklist extends StatefulWidget {
  final List<IngredientItem> ingredients;
  const IngredientChecklist({super.key, required this.ingredients});

  @override
  State<IngredientChecklist> createState() => _IngredientChecklistState();
}

class _IngredientChecklistState extends State<IngredientChecklist> {
  void _toggleChecked(IngredientItem item) async {
    setState(() {
      item.isChecked = !item.isChecked;
    });
    if (item.id != null) {
      await DatabaseHelper.instance.updateIngredient(item);
      print('Đã cập nhật trạng thái checklist cho ingredient ID: ${item.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 10.0, bottom: 5.0),
          child: Text(
            'Nguyên liệu cần thiết:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.ingredients.length,
          itemBuilder: (context, index) {
            final item = widget.ingredients[index];
            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              value: item.isChecked,
              onChanged: (bool? newValue) => _toggleChecked(item),
              title: Text(
                item.name,
                style: TextStyle(
                  fontSize: 14,
                  decoration: item.isChecked
                      ? TextDecoration.lineThrough
                      : null,
                  color: item.isChecked ? Colors.grey : Colors.black87,
                ),
              ),
              activeColor: Theme.of(context).primaryColor,
            );
          },
        ),
      ],
    );
  }
}
