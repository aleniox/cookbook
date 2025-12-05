import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'recipe_list_screen.dart';
import 'shopping_list_screen.dart';
import 'preset_recipe_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart'; // <-- đảm bảo đã import
import 'ai_features_screen.dart'; // <-- thêm import AI screen
import '../models/recipe.dart';
import '../services/recipe_service.dart'; // <-- thêm
import 'add_recipe_screen.dart'; // <-- dùng màn AddRecipeScreen duy nhất
import 'recipe_detail_screen.dart'; // <-- thêm import để mở chi tiết
import '../helpers/database_helper.dart'; // <-- thêm for delete/undo
import '../models/ingredient_item.dart'; // <-- thêm for undo

class MainAppLayout extends StatefulWidget {
  const MainAppLayout({super.key});

  @override
  State<MainAppLayout> createState() => _MainAppLayoutState();
}

class _MainAppLayoutState extends State<MainAppLayout> {
  int _selectedIndex = 0; // 0 = RecipeList, 1 = ShoppingList, 2 = PresetLibrary

  final List<Recipe> _plannedRecipes = [];
  final List<Recipe> _myRecipes = []; // danh sách công thức của bạn

  late final List<Widget> _screens;

  // Thêm trạng thái hiển thị dạng lưới
  bool _useGrid = false;
  int _gridCrossAxisCount = 2; // số cột mặc định

  // Thêm state cho tìm kiếm & lọc
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _filterPlannedOnly = false;
  String? _selectedFilter; // dùng cho thanh filter chung

  @override
  void initState() {
    super.initState();

    _screens = [
      // giữ chỗ cho index 0 (sẽ render riêng để có thể chuyển grid/list)
      const SizedBox.shrink(),
      ShoppingListScreen(recipes: _plannedRecipes),
      PresetRecipeScreen(onAddToRecipeList: _addRecipeFromPreset),
    ];

    // Đọc setting từ SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _useGrid = prefs.getBool('useGrid') ?? false;
        _gridCrossAxisCount = prefs.getInt('gridCrossAxisCount') ?? 2;
      });
    });

    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // 🔹 Thêm món ăn từ Thư viện vào danh sách công thức
  void _addRecipeFromPreset(Recipe recipe) {
    if (!_myRecipes.contains(recipe)) {
      setState(() {
        _myRecipes.add(recipe);
        _selectedIndex = 0; // tự động chuyển sang tab danh sách công thức
      });
    } else {
      setState(() => _selectedIndex = 0);
    }
  }

  void _addRecipeToPlan(Recipe recipe) {
    if (!_plannedRecipes.contains(recipe)) {
      setState(() => _plannedRecipes.add(recipe));
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).maybePop(); // đóng drawer nếu đang mở
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("email");
    await prefs.remove("password");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // Optional: giả lập refresh dữ liệu
  Future<void> _refreshRecipes() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    setState(() {
      // cập nhật lại danh sách nếu cần
    });
  }

  // --- Mới: xác nhận xóa + undo ---
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

    final backup = recipe;

    // Xóa file ảnh nếu có, xóa DB (nếu có id)
    try {
      if (backup.imageUrl.isNotEmpty) {
        final f = File(backup.imageUrl);
        if (f.existsSync()) f.deleteSync();
      }
      if (backup.id != null) {
        await DatabaseHelper.instance.deleteRecipe(backup.id!);
      }
    } catch (_) {}

    setState(() {
      _myRecipes.removeWhere(
        (r) => r.id == backup.id || r.title == backup.title,
      );
      _plannedRecipes.removeWhere(
        (r) => r.id == backup.id || r.title == backup.title,
      );
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa "${backup.title}"'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () async {
            try {
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
              final all = await RecipeService.getAllRecipes();
              setState(() {
                _myRecipes.clear();
                _myRecipes.addAll(all);
              });
            } catch (_) {
              // ignore errors on undo
            }
          },
        ),
      ),
    );
  }

  // Hàm xây dựng nội dung cho tab Công thức (grid hoặc list)
  Widget _buildRecipeTab() {
    // Áp dụng tìm kiếm & lọc
    final displayed = _myRecipes.where((r) {
      final text = r.toString().toLowerCase();
      final matchSearch =
          _searchQuery.isEmpty || text.contains(_searchQuery.toLowerCase());
      final matchFilter = !_filterPlannedOnly || _plannedRecipes.contains(r);
      return matchSearch && matchFilter;
    }).toList();

    // Empty state
    if (displayed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fastfood_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Không tìm thấy công thức phù hợp.'
                    : 'Chưa có công thức nào.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thêm công thức từ Thư viện hoặc tạo mới.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.library_books),
                label: const Text('Mở Thư viện'),
                onPressed: () => setState(() => _selectedIndex = 2),
              ),
            ],
          ),
        ),
      );
    }

    if (_useGrid) {
      // Grid: thẻ mở chi tiết khi nhấn, chỉ thêm vào kế hoạch khi nhấn icon
      return RefreshIndicator(
        onRefresh: _refreshRecipes,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridCrossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
          ),
          itemCount: displayed.length,
          itemBuilder: (context, index) {
            final recipe = displayed[index];
            final added = _plannedRecipes.contains(recipe);
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Mở màn hình chi tiết (không tự động thêm)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(
                        recipe: recipe,
                        onPlanAdded: _addRecipeToPlan,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.14),
                              Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.18),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.fastfood, size: 56),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              recipe.toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Thêm vào kế hoạch (hoặc đã thêm)
                          IconButton(
                            tooltip: added ? 'Đã thêm' : 'Thêm vào kế hoạch',
                            icon: Icon(
                              added ? Icons.check_circle : Icons.playlist_add,
                              color: added ? Colors.green : null,
                            ),
                            onPressed: added
                                ? null
                                : () {
                                    _addRecipeToPlan(recipe);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đã thêm vào kế hoạch: ${recipe.toString()}',
                                        ),
                                      ),
                                    );
                                  },
                          ),
                          // Nút xóa công thức (mới)
                          IconButton(
                            tooltip: 'Xóa công thức',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _confirmAndDelete(recipe),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else {
      // List giữ nguyên, thêm RefreshIndicator bao ngoài
      return RefreshIndicator(
        onRefresh: _refreshRecipes,
        child: RecipeListScreen(
          initialRecipes: displayed,
          onPlanAdded: _addRecipeToPlan,
          onRecipeDeleted: (recipe) {
            // Đồng bộ parent list nếu một công thức bị xóa ở child
            setState(() {
              _myRecipes.removeWhere(
                (r) => r.id == recipe.id || r.title == recipe.title,
              );
            });
          },
        ),
      );
    }
  }

  // Mở màn hình tạo công thức mới (AddRecipeScreen) và refresh danh sách khi có thay đổi
  Future<void> _openAddRecipeScreen() async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddRecipeScreen()));
    if (saved == true) {
      // reload từ DB để đồng bộ (AddRecipeScreen lưu vào DB)
      final all = await RecipeService.getAllRecipes();
      setState(() {
        _myRecipes.clear();
        _myRecipes.addAll(all);
        _selectedIndex = 0; // quay về tab danh sách công thức
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật danh sách công thức.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Text(
          _selectedIndex == 0
              ? 'Công thức'
              : _selectedIndex == 1
              ? 'Mua sắm'
              : 'Thư viện',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        // Xóa bottom search ở AppBar — sẽ dùng SearchFilterBar trong body
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: color),
              child: const Text(
                'Menu Nấu Ăn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: color),
              title: const Text('Danh sách Công thức'),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart, color: color),
              title: const Text('Kế hoạch Mua sắm'),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: Icon(Icons.book, color: color),
              title: const Text('Thư viện Công thức'),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.auto_awesome, color: color),
              title: const Text('Tính Năng AI'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AIFeaturesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài đặt'),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await Navigator.of(context)
                    .push<Map<String, dynamic>>(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          initialUseGrid: _useGrid,
                          initialGridCrossAxisCount: _gridCrossAxisCount,
                        ),
                      ),
                    );
                if (result != null) {
                  setState(() {
                    _useGrid = result['useGrid'] as bool? ?? _useGrid;
                    _gridCrossAxisCount =
                        result['gridCrossAxisCount'] as int? ??
                        _gridCrossAxisCount;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),

      // FloatingActionButton: nút thêm công thức (không bị ảnh hưởng bởi zoom)
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Thêm công thức'),
              onPressed: _openAddRecipeScreen,
            )
          : null,

      // Bọc nội dung bằng SafeArea; đặt SearchFilterBar phía trên InteractiveViewer (không zoom)
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedIndex == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SearchFilterBar(
                  controller: _searchCtrl,
                  searchQuery: _searchQuery,
                  filterOptions: const ['Tất cả', 'Đã lên kế hoạch'],
                  selectedFilter: _selectedFilter ?? 'Lọc',
                  onFilterSelected: (val) {
                    setState(() {
                      _selectedFilter = (val == 'Tất cả' || val == 'Lọc')
                          ? null
                          : val;
                      _filterPlannedOnly = _selectedFilter == 'Đã lên kế hoạch';
                    });
                  },
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),

            // Nội dung chính
            Expanded(
              child: _selectedIndex == 0
                  ? _buildRecipeTab()
                  : _screens[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}
