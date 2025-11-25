import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/recipe_list_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'models/recipe.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

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
  int _selectedIndex = 0; // 0 = RecipeList, 1 = ShoppingList
  final List<Recipe> _plannedRecipes = [];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      RecipeListScreen(onPlanAdded: _addRecipeToPlan),
      ShoppingListScreen(recipes: _plannedRecipes),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).maybePop(); // đóng drawer nếu đang mở
  }

  void _addRecipeToPlan(Recipe recipe) {
    if (!_plannedRecipes.contains(recipe)) {
      setState(() => _plannedRecipes.add(recipe));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Danh sách Công thức' : 'Kế hoạch Mua sắm',
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
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
