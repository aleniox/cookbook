// IMPORTS: dọn trùng lặp và sắp xếp
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'add_recipe_screen.dart';
import '../helpers/database_helper.dart';
import 'recipe_detail_screen.dart';
import '../models/ingredient_item.dart';

class RecipeListScreen extends StatefulWidget {
  final Function(Recipe) onPlanAdded;
  final List<Recipe>? initialRecipes;
  final Function(Recipe)? onRecipeDeleted; // <-- thêm callback tùy chọn

  const RecipeListScreen({
    super.key,
    required this.onPlanAdded,
    this.initialRecipes,
    this.onRecipeDeleted,
  });

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  String _searchQuery = '';
  String? _selectedType;

  // Thêm controller để dễ quản lý và clear
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
      _filterRecipes();
    });
  }

  @override
  void didUpdateWidget(covariant RecipeListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu parent truyền initialRecipes mới (hoặc thay đổi), cập nhật danh sách nội bộ
    if (widget.initialRecipes != null &&
        widget.initialRecipes != oldWidget.initialRecipes) {
      _recipes = List.from(widget.initialRecipes!);
      _filterRecipes();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    if (widget.initialRecipes != null) {
      _recipes = List.from(widget.initialRecipes!);
    } else {
      _recipes = await RecipeService.getAllRecipes();
    }
    _filterRecipes();
  }

  void addRecipeFromPreset(Recipe recipe) async {
    // Thêm recipe nếu chưa có (so sánh id nếu có, hoặc title)
    final exists =
        (recipe.id != null && _recipes.any((r) => r.id == recipe.id)) ||
        _recipes.any((r) => r.title == recipe.title);
    if (exists) return;
    setState(() {
      _recipes.add(recipe);
      _filterRecipes();
    });
  }

  void _openAddRecipeScreen() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
    );

    if (added == true) {
      await _loadRecipes();
      _filterRecipes();
    }
  }

  // Xác nhận và xóa với undo
  Future<void> _confirmAndDelete(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công thức'),
        content: Text('Bạn có chắc muốn xóa "${recipe.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // sao lưu để có thể undo
    final backup = recipe;

    // xóa DB + file ảnh
    try {
      if (backup.id != null) {
        if (backup.imageUrl.isNotEmpty) {
          final f = File(backup.imageUrl);
          if (f.existsSync()) f.deleteSync();
        }
        await DatabaseHelper.instance.deleteRecipe(backup.id!);
      }
    } catch (_) {}

    // cập nhật UI cục bộ
    setState(() {
      _recipes.removeWhere((r) => r.id == backup.id || r.title == backup.title);
      _filterRecipes();
    });

    // thông báo parent (nếu có)
    widget.onRecipeDeleted?.call(backup);

    // SnackBar with undo
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa "${backup.title}"'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () async {
            // chèn lại recipe + nguyên liệu + bước
            final newId = await RecipeService.insertRecipe(backup);
            for (var ing in backup.ingredients) {
              await RecipeService.insertIngredient(
                IngredientItem(
                  id: null,
                  name: ing.name,
                  isChecked: ing.isChecked,
                  recipeId: newId,
                ),
              );
            }
            for (var step in backup.steps) {
              await RecipeService.insertStep(newId, step);
            }
            await _loadRecipes();
            // notify parent to reload if needed
            widget.onRecipeDeleted?.call(backup); // parent may reload lists
          },
        ),
      ),
    );
  }

  void _deleteRecipe(Recipe recipe) async {
    // deprecated: dùng _confirmAndDelete để xử lý confirmation + undo
    await _confirmAndDelete(recipe);
  }

  void _filterRecipes() {
    final q = _searchQuery.trim().toLowerCase();
    _filteredRecipes = _recipes.where((recipe) {
      final title = recipe.title.toLowerCase();
      final matchesSearch = q.isEmpty || title.contains(q);
      final matchesType =
          _selectedType == null ||
          _selectedType == 'Tất cả' ||
          recipe.type == _selectedType;
      return matchesSearch && matchesType;
    }).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Nếu màn này được cung cấp initialRecipes từ bên ngoài (như MainAppLayout),
            // thì không hiển thị thanh tìm kiếm/lọc ở đây (tránh trùng lặp).
            if (widget.initialRecipes == null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: SearchFilterBar(
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  filterOptions: const ['Tất cả', 'Đồ uống', 'Thức ăn'],
                  selectedFilter: _selectedType ?? 'Lọc',
                  onFilterSelected: (value) {
                    setState(() {
                      _selectedType = (value == 'Tất cả' || value == 'Lọc')
                          ? null
                          : value;
                      _filterRecipes();
                    });
                  },
                  onClear: () {
                    _searchController.clear();
                    _filterRecipes();
                  },
                ),
              ),

            // Danh sách công thức
            Expanded(
              child: _filteredRecipes.isEmpty
                  ? const Center(child: Text('Chưa có công thức nào.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _filteredRecipes[index];
                        return RecipeCard(
                          recipe: recipe,
                          onPlanAdded: widget.onPlanAdded,
                          onDelete: () =>
                              _confirmAndDelete(recipe), // show confirm
                        );
                      },
                    ),
            ),
          ],
        ),
        // FAB removed (now managed by parent/layout)
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
    if (path.isEmpty) {
      return _buildPlaceholder(height);
    }

    // Load từ assets
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(height),
      );
    }

    // Load từ network (HTTP/HTTPS)
    if (path.startsWith('http')) {
      return Image.network(
        path,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(height),
      );
    }

    // Load từ file local
    if (File(path).existsSync()) {
      return Image.file(
        File(path),
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(height),
      );
    }

    return _buildPlaceholder(height);
  }

  Widget _buildPlaceholder(double? height) {
    return Container(
      height: height ?? 120,
      width: height ?? 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.restaurant_menu,
        size: 48,
        color: Colors.grey[400],
      ),
    );
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
                    borderRadius: BorderRadius.circular(12.0),
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: loadImage(
                        widget.recipe.imageUrl,
                        fit: BoxFit.cover,
                      ),
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

// ======= Thêm widget tái sử dụng SearchFilterBar (dưới cùng file) =======
class SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final List<String> filterOptions;
  final String? selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback? onClear;

  const SearchFilterBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.filterOptions,
    required this.onFilterSelected,
    this.selectedFilter,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
                Icon(Icons.search, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm công thức...",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
            onSelected: onFilterSelected,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (_) => filterOptions
                .map((o) => PopupMenuItem(value: o, child: Text(o)))
                .toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedFilter ?? 'Lọc',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
