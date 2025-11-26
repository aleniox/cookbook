import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/recipe_list_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'screens/preset_recipe_screen.dart'; // <-- Màn hình thư viện sẵn
import 'models/recipe.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.deleteBoxFromDisk('recipes');

  Hive.registerAdapter(IngredientItemAdapter());
  Hive.registerAdapter(RecipeAdapter());

  await Hive.openBox<Recipe>('recipes');

  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sách Nấu Ăn Flutter',
      theme: AppTheme.lightTheme,
      home: const MainAppLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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

  @override
  void initState() {
    super.initState();

    _screens = [
      RecipeListScreen(
        initialRecipes: _myRecipes,
        onPlanAdded: _addRecipeToPlan,
      ),
      ShoppingListScreen(recipes: _plannedRecipes),
      PresetRecipeScreen(
        onAddToRecipeList: _addRecipeFromPreset, // <- callback mới
      ),
    ];
  }

  // 🔹 Thêm món ăn từ Thư viện vào danh sách công thức
  void _addRecipeFromPreset(Recipe recipe) {
    if (!_myRecipes.contains(recipe)) {
      setState(() {
        _myRecipes.add(recipe);
        _selectedIndex = 0; // tự động chuyển sang tab danh sách công thức
      });
    } else {
      // Nếu đã có, vẫn chuyển tab
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

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Danh sách Công thức'
              : _selectedIndex == 1
                  ? 'Kế hoạch Mua sắm'
                  : 'Thư viện Công thức',
        ),
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
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
